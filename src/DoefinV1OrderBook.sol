// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Errors } from "./libraries/Errors.sol";
import { ERC1155 } from "solady/contracts/tokens/ERC1155.sol";
import { ERC2771Context } from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IDoefinV1OrderBook } from "./interfaces/IDoefinV1OrderBook.sol";
import { IDoefinConfig } from "./interfaces/IDoefinConfig.sol";

contract DoefinV1OrderBook is IDoefinV1OrderBook, ERC1155, ERC2771Context {
    using SafeERC20 for IERC20;

    /// @notice Doefin Config
    IDoefinConfig public immutable config;

    /// @notice The minimum collateral token amount required for an order to be valid
    uint256 public immutable minCollateralTokenAmount;

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

    modifier onlyOptionsManager() {
        require(_msgSender() == blockHeaderOracle, "Can only be called by options manager");
        _;
    }

    modifier onlyBlockHeaderOracle() {
        require(_msgSender() == blockHeaderOracle, "Caller is not block header oracle");
        _;
    }

    modifier onlyAuthorizedRelayer() {
        require(authorizedRelayer == msg.sender, "Caller is not an authorized relayer");
        _;
    }

    constructor(address _config) ERC1155() ERC2771Context(IDoefinConfig(_config).getTrustedForwarder()) {
        if (_config == address(0)) {
            revert Errors.ZeroAddress();
        }

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

        (uint256 newOrderId, BinaryOption storage newBinaryOption) = _createBinaryOption(
            createOrderInput.strike,
            createOrderInput.premium,
            createOrderInput.notional,
            createOrderInput.expiry,
            createOrderInput.expiryType,
            createOrderInput.position,
            createOrderInput.collateralToken,
            createOrderInput.allowed
        );

        _handleCollateralTransfer(createOrderInput.collateralToken, _msgSender(), createOrderInput.premium);
        _mint(_msgSender(), newOrderId, 1, "");

        emit OrderCreated(newOrderId);
        return newOrderId;
    }

    function matchOrder(uint256 orderId) external {
        BinaryOption storage order = orders[orderId];
        if (order.metadata.status != Status.Pending) {
            revert Errors.OrderBook_OrderMustBePending();
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

        _handleCollateralTransfer(order.metadata.collateralToken, _msgSender(), takerPremium);
        _handleFeeTransfer(order.metadata.collateralToken, order.premiums.notional, order.metadata.payOut);

        _mint(_msgSender(), orderId, 1, "");
        _registerOrderForSettlement(orderId);
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

        _handleCollateralTransfer(order.collateralToken, order.maker, order.premium);
        _handleCollateralTransfer(order.collateralToken, order.taker, takerPremium);
        _handleFeeTransfer(order.collateralToken, order.notional, newBinaryOption.metadata.payOut);

        _mint(order.maker, newOrderId, 1, "");
        _mint(order.taker, newOrderId, 1, "");
        _registerOrderForSettlement(newOrderId);

        emit OrderCreated(newOrderId);
        emit OrderMatched(newOrderId, order.taker, takerPremium);

        return newOrderId;
    }

    //@@inheritdoc
    function exerciseOrder(uint256 orderId) external returns (uint256) {
        BinaryOption storage order = orders[orderId];
        if (order.metadata.status != Status.Settled) {
            revert Errors.OrderBook_OrderMustBeSettled();
        }

        address winner;
        order.metadata.status = Status.Exercised;
        _burn(order.metadata.maker, orderId, 1);
        _burn(order.metadata.taker, orderId, 1);

        if (order.metadata.finalStrike > order.metadata.initialStrike) {
            if (order.positions.makerPosition == Position.Call) {
                winner = order.metadata.maker;
                IERC20(order.metadata.collateralToken).safeTransfer(order.metadata.maker, order.metadata.payOut);
            } else {
                winner = order.metadata.taker;
                IERC20(order.metadata.collateralToken).safeTransfer(order.metadata.taker, order.metadata.payOut);
            }
        } else if (order.metadata.finalStrike < order.metadata.initialStrike) {
            if (order.positions.makerPosition == Position.Put) {
                winner = order.metadata.maker;
                IERC20(order.metadata.collateralToken).safeTransfer(order.metadata.maker, order.metadata.payOut);
            } else {
                winner = order.metadata.taker;
                IERC20(order.metadata.collateralToken).safeTransfer(order.metadata.taker, order.metadata.payOut);
            }
        }

        emit OrderExercised(orderId, order.metadata.payOut, winner);
        return orderId;
    }

    //@@inheritdoc
    function settleOrder(uint256 blockNumber, uint256 timestamp, uint256 difficulty) public onlyBlockHeaderOracle {
        uint256 len = registeredOrderIds.length;
        for (uint256 i = 0; i < len; i++) {
            BinaryOption storage order = orders[registeredOrderIds[i]];
            if (order.metadata.status != Status.Matched) {
                continue;
            }

            bool expiryIsValid = (
                order.metadata.expiryType == ExpiryType.BlockNumber && blockNumber >= order.metadata.expiry
            ) || (order.metadata.expiryType == ExpiryType.Timestamp && timestamp >= order.metadata.expiry);

            if (expiryIsValid) {
                order.metadata.status = Status.Settled;
                order.metadata.finalStrike = difficulty;

                registeredOrderIds[i] = registeredOrderIds[len - 1];
                registeredOrderIds.pop();
                len--;
            }
        }
    }

    //@@inheritdoc
    function cancelOrder(uint256 orderId) external {
        BinaryOption storage order = orders[orderId];
        if (_msgSender() != order.metadata.maker) {
            revert Errors.OrderBook_CallerNotMaker();
        }

        if (order.metadata.status != Status.Pending) {
            revert Errors.OrderBook_OrderMustBePending();
        }

        order.metadata.status = Status.Canceled;
        _burn(order.metadata.maker, orderId, 1);
        IERC20(order.metadata.collateralToken).safeTransfer(order.metadata.maker, order.premiums.makerPremium);
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

        // Update premium
        if (updateOrder.premium != 0) {
            if (updateOrder.premium >= order.premiums.makerPremium) {
                uint256 premiumIncrease = updateOrder.premium - order.premiums.makerPremium;
                order.premiums.makerPremium = updateOrder.premium;
                IERC20(order.metadata.collateralToken).safeTransferFrom(_msgSender(), address(this), premiumIncrease);
                emit PremiumIncreased(orderId, updateOrder.premium);
            } else {
                uint256 premiumDecrease = order.premiums.makerPremium - updateOrder.premium;
                if (premiumDecrease < config.getApprovedToken(order.metadata.collateralToken).minCollateralAmount) {
                    revert Errors.OrderBook_LessThanMinCollateralAmount();
                }
                order.premiums.makerPremium = updateOrder.premium;
                IERC20(order.metadata.collateralToken).safeTransfer(_msgSender(), premiumDecrease);
                emit PremiumDecreased(orderId, updateOrder.premium);
            }
        }

        if (order.premiums.makerPremium >= order.premiums.notional) {
            revert Errors.OrderBook_InvalidNotional();
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
    }

    function uri(uint256 id) public view override returns (string memory) {
        return "";
    }
    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _useBeforeTokenTransfer() internal pure override returns (bool) {
        return true;
    }

    //@inheritdoc
    function _beforeTokenTransfer(
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
            takerPosition: position == Position.Call ? Position.Put : Position.Call
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
            payOut: notional - (notional / 100),
            expiry: expiry,
            expiryType: expiryType,
            deadline: block.timestamp,
            allowed: allowed
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
        newBinaryOption.metadata = _initializeMetadata(collateralToken, strike, notional, expiry, expiryType, allowed);
    }

    function _handleCollateralTransfer(address collateralToken, address from, uint256 amount) internal {
        uint256 balBefore = IERC20(collateralToken).balanceOf(address(this));
        IERC20(collateralToken).safeTransferFrom(from, address(this), amount);
        if (IERC20(collateralToken).balanceOf(address(this)) - balBefore != amount) {
            revert Errors.OrderBook_UnableToMatchOrder();
        }
    }

    function _handleFeeTransfer(address collateralToken, uint256 notional, uint256 payOut) internal {
        uint256 fee = notional - payOut;
        IERC20(collateralToken).safeTransfer(optionsFeeAddress, fee);
    }
}
