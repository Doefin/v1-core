// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Errors } from "./libraries/Errors.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IDoefinV1OrderBook } from "./interfaces/IDoefinV1OrderBook.sol";
import { IDoefinConfig } from "./interfaces/IDoefinConfig.sol";
import { IDoefinBlockHeaderOracle } from "./interfaces/IDoefinBlockHeaderOracle.sol";

contract DoefinV1OrderBook is IDoefinV1OrderBook, ERC1155, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Doefin Config
    IDoefinConfig public immutable config;

    /// @notice The block header oracle address
    address public immutable blockHeaderOracle;

    /// @notice The address of the relayer
    address public immutable authorizedRelayer;

    /// @notice The address where premium fees are transferred to
    address public immutable optionsFeeAddress;

    /// @dev The id of the next order to be created
    uint256 public orderIdCounter;

    /// @dev The mapping of id to option orders
    mapping(uint256 => BinaryOption) public orders;

    /// @notice List of orderIds to be settled
    uint256[] public registeredOrderIds;

    modifier onlyBlockHeaderOracle() {
        require(_msgSender() == blockHeaderOracle, "Caller is not block header oracle");
        _;
    }

    modifier onlyAuthorizedRelayer() {
        require(authorizedRelayer == msg.sender, "Caller is not an authorized relayer");
        _;
    }

    constructor(address _config, address owner) ERC1155("")  {
        if (_config == address(0)) {
            revert Errors.ZeroAddress();
        }
        _transferOwnership(owner);
        config = IDoefinConfig(_config);
        blockHeaderOracle = config.getBlockHeaderOracle();
        optionsFeeAddress = config.getFeeAddress();
        authorizedRelayer = config.getAuthorizedRelayer();
    }

    //@@inheritdoc
    function createOrder(CreateOrderInput calldata createOrderInput) external returns (uint256) {
        _validateOrderParameters(
            createOrderInput.strike,
            createOrderInput.premium,
            createOrderInput.notional,
            createOrderInput.expiry,
            createOrderInput.collateralToken
        );

        (uint256 newOrderId,) = _createBinaryOption(
            createOrderInput.strike,
            createOrderInput.premium,
            createOrderInput.notional,
            createOrderInput.deadline,
            createOrderInput.expiry,
            createOrderInput.expiryType,
            createOrderInput.position,
            createOrderInput.collateralToken,
            createOrderInput.allowed
        );

        _handleCollateralTransferFrom(createOrderInput.collateralToken, _msgSender(), createOrderInput.premium);
        _mint(_msgSender(), newOrderId, 1, "");

        emit OrderCreated(
            newOrderId,
            msg.sender,
            createOrderInput.collateralToken,
            createOrderInput.premium,
            createOrderInput.notional,
            createOrderInput.strike,
            createOrderInput.position,
            createOrderInput.expiry,
            createOrderInput.expiryType
        );
        return newOrderId;
    }

    function matchOrder(uint256 orderId, uint256 expectedNonce) external {
        BinaryOption storage order = orders[orderId];
        if (order.metadata.maker == _msgSender()) {
            revert Errors.OrderBook_SelfMatchOrder();
        }

        if (order.metadata.status != Status.Pending) {
            revert Errors.OrderBook_OrderMustBePending();
        }

        if (order.metadata.nonce != expectedNonce) {
            revert Errors.OrderBook_InvalidNonce();
        }

        if (block.timestamp > order.metadata.deadline) {
            revert Errors.OrderBook_OrderExpired();
        }

        if (order.metadata.taker != address(0)) {
            revert Errors.OrderBook_OrderAlreadyMatched();
        }

        address[] memory allowed = order.metadata.allowed;
        if (allowed.length > 0) {
            bool isAllowed = false;
            for (uint256 i = 0; i < allowed.length; i++) {
                if (allowed[i] == _msgSender()) {
                    isAllowed = true;
                    break;
                }
            }

            if (!isAllowed) {
                revert Errors.OrderBook_MatchOrderNotAllowed();
            }
        }

        order.metadata.taker = _msgSender();
        order.metadata.status = Status.Matched;
        uint256 takerPremium = order.premiums.notional - order.premiums.makerPremium;
        order.premiums.takerPremium = takerPremium;

        _registerOrderForSettlement(orderId);

        _handleCollateralTransferFrom(order.metadata.collateralToken, _msgSender(), takerPremium);
        _handleCollateralTransfer(
            order.metadata.collateralToken, optionsFeeAddress, order.premiums.notional - order.metadata.payOut
        );

        _mint(_msgSender(), orderId, 1, "");
        emit OrderMatched(orderId, _msgSender(), takerPremium);
    }

    function createAndMatchOrder(CreateAndMatchOrderInput calldata order)
        external
        onlyAuthorizedRelayer
        returns (uint256)
    {
        _validateOrderParameters(order.strike, order.premium, order.notional, order.expiry, order.collateralToken);

        (uint256 newOrderId, BinaryOption storage newBinaryOption) = _createBinaryOption(
            order.strike,
            order.premium,
            order.notional,
            block.timestamp,
            order.expiry,
            ExpiryType(order.expiryType),
            Position(order.position),
            order.collateralToken,
            order.allowed
        );

        newBinaryOption.metadata.status = Status.Matched;
        newBinaryOption.metadata.taker = order.taker;
        uint256 takerPremium = order.notional - order.premium;
        newBinaryOption.premiums.takerPremium = takerPremium;

        _registerOrderForSettlement(newOrderId);

        _handleCollateralTransferFrom(order.collateralToken, order.maker, order.premium);
        _handleCollateralTransferFrom(order.collateralToken, order.taker, takerPremium);
        _handleCollateralTransfer(
            order.collateralToken, optionsFeeAddress, order.notional - newBinaryOption.metadata.payOut
        );

        _mint(order.maker, newOrderId, 1, "");
        _mint(order.taker, newOrderId, 1, "");

        emit OrderCreated(
            newOrderId,
            msg.sender,
            order.collateralToken,
            order.premium,
            order.notional,
            order.strike,
            order.position,
            order.expiry,
            order.expiryType
        );
        emit OrderMatched(newOrderId, order.taker, takerPremium);

        return newOrderId;
    }

    //@@inheritdoc
    function exerciseOrder(uint256 orderId) external returns (uint256) {
        BinaryOption memory order = orders[orderId];
        if (order.metadata.status != Status.Settled) {
            revert Errors.OrderBook_OrderMustBeSettled();
        }

        address winner;
        _burn(order.metadata.maker, orderId, 1);
        _burn(order.metadata.taker, orderId, 1);
        delete orders[orderId];

        if (order.metadata.finalStrike >= order.metadata.initialStrike) {
            if (order.positions.makerPosition == Position.Above) {
                winner = order.metadata.maker;
            } else {
                winner = order.metadata.taker;
            }

            _handleCollateralTransfer(order.metadata.collateralToken, winner, order.metadata.payOut);
        } else if (order.metadata.finalStrike < order.metadata.initialStrike) {
            if (order.positions.makerPosition == Position.Below) {
                winner = order.metadata.maker;
            } else {
                winner = order.metadata.taker;
            }

            _handleCollateralTransfer(order.metadata.collateralToken, winner, order.metadata.payOut);
        }
        emit OrderExercised(orderId, order.metadata.payOut, winner);
        return orderId;
    }

    //@@inheritdoc
    function settleOrder(uint256 blockNumber, uint256 timestamp, uint256 difficulty) public onlyBlockHeaderOracle {
        uint256 len = registeredOrderIds.length;
        for (uint256 i = 0; i < len; i++) {
            uint256 orderId = registeredOrderIds[i];
            BinaryOption storage order = orders[orderId];

            bool expiryIsValid = (
                order.metadata.expiryType == ExpiryType.BlockNumber && blockNumber >= order.metadata.expiry
            ) || (order.metadata.expiryType == ExpiryType.Timestamp && timestamp >= order.metadata.expiry);

            if (expiryIsValid) {
                order.metadata.status = Status.Settled;
                order.metadata.finalStrike = difficulty;

                registeredOrderIds[i] = registeredOrderIds[len - 1];
                registeredOrderIds.pop();
                len--;

                emit OrderSettled(orderId, blockNumber, timestamp, difficulty);
            }
        }
    }

    //@@inheritdoc
    function cancelOrder(uint256 orderId) external {
        BinaryOption memory order = orders[orderId];
        if (_msgSender() != order.metadata.maker) {
            revert Errors.OrderBook_CallerNotMaker();
        }

        if (order.metadata.status != Status.Pending) {
            revert Errors.OrderBook_OrderMustBePending();
        }

        _burn(order.metadata.maker, orderId, 1);
        delete orders[orderId];

        _handleCollateralTransfer(order.metadata.collateralToken, order.metadata.maker, order.premiums.makerPremium);
        emit OrderCanceled(orderId);
    }

    //@@inheritdoc
    function getOrder(uint256 orderId) external view returns (BinaryOption memory) {
        return orders[orderId];
    }

    /*//////////////////////////////////////////////////////////////////////////
                                UPDATE ORDER FUNCTION
    //////////////////////////////////////////////////////////////////////////*/
    /**
     * @dev Update multiple aspects of an order
     * @param orderId The order id of the order to update
     * @param updateOrder A struct containing the update parameters
     */
    function updateOrder(uint256 orderId, UpdateOrder memory updateOrder) external {
        BinaryOption storage order = orders[orderId];
        if (_msgSender() != order.metadata.maker) {
            revert Errors.OrderBook_CallerNotMaker();
        }

        if (order.metadata.status != Status.Pending) {
            revert Errors.OrderBook_OrderMustBePending();
        }

        // Increment nonce
        order.metadata.nonce += 1;

        //Update Notional
        if (updateOrder.notional != 0) {
            uint256 prevNotional = order.premiums.notional;
            order.premiums.notional = updateOrder.notional;

            if (updateOrder.notional > prevNotional) {
                emit NotionalIncreased(orderId, updateOrder.notional);
            } else {
                emit NotionalDecreased(orderId, updateOrder.notional);
            }
        }

        // Update deadline
        if (updateOrder.deadline != 0 && updateOrder.deadline > block.timestamp) {
            order.metadata.deadline = updateOrder.deadline;
            emit OrderDeadlineUpdated(orderId, updateOrder.deadline);
        }

        // Update position
        if (updateOrder.position != order.positions.makerPosition) {
            order.positions.makerPosition = updateOrder.position;
            emit OrderPositionUpdated(orderId, updateOrder.position);
        }

        // Update expiry
        if (updateOrder.expiry != 0) {
            order.metadata.expiry = updateOrder.expiry;
            order.metadata.expiryType = updateOrder.expiryType;
            emit OrderExpiryUpdated(orderId, updateOrder.expiry, updateOrder.expiryType);
        }

        // Update allowed list
        order.metadata.allowed = updateOrder.allowed;
        emit OrderAllowedListUpdated(orderId, updateOrder.allowed);

        // Update strike
        if (updateOrder.strike != 0) {
            order.metadata.initialStrike = updateOrder.strike;
            emit OrderStrikeUpdated(orderId, updateOrder.strike);
        }

        // Update premium
        if (updateOrder.premium != 0) {
            if (updateOrder.premium >= order.premiums.makerPremium) {
                uint256 premiumIncrease = updateOrder.premium - order.premiums.makerPremium;
                order.premiums.makerPremium = updateOrder.premium;
                _handleCollateralTransferFrom(order.metadata.collateralToken, _msgSender(), premiumIncrease);
                emit PremiumIncreased(orderId, updateOrder.premium);
            } else {
                uint256 premiumDecrease = order.premiums.makerPremium - updateOrder.premium;
                if (updateOrder.premium < config.getApprovedToken(order.metadata.collateralToken).minCollateralAmount) {
                    revert Errors.OrderBook_LessThanMinCollateralAmount();
                }

                order.premiums.makerPremium = updateOrder.premium;
                _handleCollateralTransfer(order.metadata.collateralToken, _msgSender(), premiumDecrease);
                emit PremiumDecreased(orderId, updateOrder.premium);
            }
        }

        if (order.premiums.makerPremium >= order.premiums.notional) {
            revert Errors.OrderBook_InvalidNotional();
        }
    }

    /**
     * @dev Delete multiple orders from the order-book
     */
    function deleteOrders() external onlyOwner {
        IDoefinBlockHeaderOracle.BlockHeader memory blockHeader =
            IDoefinBlockHeaderOracle(blockHeaderOracle).getLatestBlockHeader();

        uint256 len = orderIdCounter;
        for (uint256 orderId = 0; orderId < len; orderId++) {
            BinaryOption storage order = orders[orderId];
            if (order.metadata.maker == address(0)) continue;

            bool isMatched = order.metadata.status == Status.Matched;
            bool isPastDeadline = block.timestamp > order.metadata.deadline;
            bool isExpired = (
                order.metadata.expiryType == ExpiryType.BlockNumber && blockHeader.blockNumber >= order.metadata.expiry
            ) || (order.metadata.expiryType == ExpiryType.Timestamp && blockHeader.timestamp >= order.metadata.expiry);

            if (!isMatched && (isExpired || isPastDeadline)) {
                _burn(order.metadata.maker, orderId, 1);
                IERC20(order.metadata.collateralToken).safeTransfer(order.metadata.maker, order.premiums.makerPremium);
                delete orders[orderId];
            }
        }
    }

    function uri(uint256 id) public view override returns (string memory) {
        return "";
    }
    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    //@inheritdoc
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        override
    {
        //if `from` is zero (mint) and `to` is zero (burn) this checked will be skipped.
        //Otherwise the action is a transfer, and it will revert
        if (from != address(0) && to != address(0)) {
            revert Errors.OrderBook_OptionTokenTransferNotAllowed();
        }
    }

    /**
     * @dev Register an order for settlement in the options manager
     * @param orderId The order id of the order to register
     */
    function _registerOrderForSettlement(uint256 orderId) internal {
        registeredOrderIds.push(orderId);
        emit OrderRegistered(orderId);
    }

    /**
     * @dev Initialize the premium struct of an order
     * @param premium The premium the market maker
     * @param notional The notional of the trade
     */
    function _initializePremiums(uint256 premium, uint256 notional) internal pure returns (Premiums memory) {
        return Premiums({ makerPremium: premium, takerPremium: 0, notional: notional });
    }

    /**
     * @dev Initialize the position struct of an order
     * @param position The position of the market maker
     */
    function _initializePositions(Position position) internal pure returns (Positions memory) {
        return Positions({
            makerPosition: position,
            takerPosition: position == Position.Above ? Position.Below : Position.Above
        });
    }

    /**
     * @dev Initialize the metadata struct of an order
     * @param collateralToken The collateral token of the order
     * @param strike The strike of the order
     * @param notional The notional of the order
     * @param expiry The expiry of the order
     * @param expiryType The expiry type of the order
     * @param allowed The allowed address list for the order
     */
    function _initializeMetadata(
        address collateralToken,
        uint256 strike,
        uint256 notional,
        uint256 deadline,
        uint256 expiry,
        ExpiryType expiryType,
        address[] calldata allowed
    )
        internal
        view
        returns (Metadata memory)
    {
        return Metadata({
            status: Status.Pending,
            maker: _msgSender(),
            taker: address(0),
            collateralToken: collateralToken,
            initialStrike: strike,
            finalStrike: 0,
            payOut: notional - (notional * config.getFee() / 10_000),
            expiry: expiry,
            expiryType: expiryType,
            deadline: deadline,
            allowed: allowed,
            nonce: 0
        });
    }

    /// changes
    function _validateOrderParameters(
        uint256 strike,
        uint256 premium,
        uint256 notional,
        uint256 expiry,
        address collateralToken
    )
        internal
        view
    {
        if (strike == 0) {
            revert Errors.OrderBook_ZeroStrike();
        }

        if (collateralToken == address(0) || !config.tokenIsInApprovedList(collateralToken)) {
            revert Errors.OrderBook_InvalidCollateralToken();
        }

        if (premium < config.getApprovedToken(collateralToken).minCollateralAmount) {
            revert Errors.OrderBook_InvalidMinCollateralAmount();
        }

        if (expiry == 0) {
            revert Errors.OrderBook_ZeroExpiry();
        }

        if (notional <= premium) {
            revert Errors.OrderBook_InvalidNotional();
        }
    }

    function _createBinaryOption(
        uint256 strike,
        uint256 premium,
        uint256 notional,
        uint256 deadline,
        uint256 expiry,
        ExpiryType expiryType,
        Position position,
        address collateralToken,
        address[] calldata allowed
    )
        internal
        returns (uint256 newOrderId, BinaryOption storage newBinaryOption)
    {
        newOrderId = orderIdCounter++;
        newBinaryOption = orders[newOrderId];
        newBinaryOption.premiums = _initializePremiums(premium, notional);
        newBinaryOption.positions = _initializePositions(position);
        newBinaryOption.metadata =
            _initializeMetadata(collateralToken, strike, notional, deadline, expiry, expiryType, allowed);
    }

    function _handleCollateralTransferFrom(
        address collateralToken,
        address from,
        uint256 amount
    )
        internal
        nonReentrant
    {
        if (!config.tokenIsInApprovedList(collateralToken)) {
            revert Errors.OrderBook_TokenIsNotApproved();
        }

        uint256 balBefore = IERC20(collateralToken).balanceOf(address(this));
        IERC20(collateralToken).safeTransferFrom(from, address(this), amount);
        if (IERC20(collateralToken).balanceOf(address(this)) - balBefore != amount) {
            revert Errors.OrderBook_IncorrectTransferAmount();
        }
    }

    function _handleCollateralTransfer(address collateralToken, address to, uint256 amount) internal nonReentrant {
        if (!config.tokenIsInApprovedList(collateralToken)) {
            revert Errors.OrderBook_TokenIsNotApproved();
        }

        uint256 balBefore = IERC20(collateralToken).balanceOf(to);
        IERC20(collateralToken).safeTransfer(to, amount);

        if (IERC20(collateralToken).balanceOf(to) - balBefore != amount) {
            revert Errors.OrderBook_IncorrectTransferAmount();
        }
    }
}
