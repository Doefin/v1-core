// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Errors} from "./libraries/Errors.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC1155} from "solady/contracts/tokens/ERC1155.sol";
import {IDoefinV1OrderBook} from "./interfaces/IDoefinV1OrderBook.sol";
import {IDoefinConfig} from "./interfaces/IDoefinConfig.sol";

contract DoefinV1OrderBook is IDoefinV1OrderBook, ERC1155 {
    using SafeERC20 for IERC20;

    /// @notice Doefin Config
    IDoefinConfig public immutable config;

    /// @notice The minimum collateral token amount required for an order to be valid
    uint256 public immutable minCollateralTokenAmount;

    /// @notice The block header oracle address
    address public immutable blockHeaderOracle;

    /// @notice The address where premium fees are transferred to
    address public immutable optionsFeeAddress;

    /// @dev The id of the next order to be created
    uint256 public orderIdCounter;

    /// @dev The mapping of id to option orders
    mapping(uint256 => BinaryOption) public orders;

    /// @notice List of orderIds to be settled
    uint256[] public registeredOrderIds;

    modifier onlyOptionsManager() {
        require(msg.sender == blockHeaderOracle, "Can only be called by options manager");
        _;
    }

    modifier onlyBlockHeaderOracle() {
        require(msg.sender == blockHeaderOracle, "Caller is not block header oracle");
        _;
    }

    constructor(address _config) ERC1155() {
        if (_config == address(0)) {
            revert Errors.ZeroAddress();
        }

        config = IDoefinConfig(_config);
        blockHeaderOracle = config.getBlockHeaderOracle();
        optionsFeeAddress = config.getFeeAddress();
    }

    //@@inheritdoc
    function createOrder(
        uint256 strike,
        uint256 premium,
        uint256 notional,
        uint256 expiry,
        ExpiryType expiryType,
        Position position,
        address collateralToken,
        address[] calldata allowed
    )
        external
        returns (uint256)
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

        BinaryOption memory newBinaryOption;
        uint256 newOrderId = orderIdCounter;

        newBinaryOption.premiums = _initializePremiums(premium, notional);
        newBinaryOption.positions = _initializePositions(position);
        newBinaryOption.metadata = _initializeMetadata(collateralToken, strike, notional, expiry, expiryType, allowed);

        IERC20(collateralToken).safeTransferFrom(msg.sender, address(this), premium);
        _mint(msg.sender, newOrderId, 1, "");
        orders[newOrderId] = newBinaryOption;
        orderIdCounter++;

        emit OrderCreated(newOrderId);
        return newOrderId;
    }

    //@@inheritdoc
    function matchOrder(uint256 orderId) external {
        BinaryOption storage order = orders[orderId];
        if (order.metadata.status != Status.Pending) {
            revert Errors.OrderBook_OrderMustBePending();
        }

        if (block.timestamp > order.metadata.exerciseWindowStart) {
            revert Errors.OrderBook_MatchOrderExpired();
        }

        if (order.metadata.taker != address(0)) {
            revert Errors.OrderBook_OrderAlreadyMatched();
        }

        address[] memory allowed = order.metadata.allowed;
        if (allowed.length > 0) {
            bool isAllowed = false;
            for (uint256 i = 0; i < allowed.length; i++) {
                if (allowed[i] == msg.sender) {
                    isAllowed = true;
                    break;
                }
            }

            if (!isAllowed) {
                revert Errors.OrderBook_MatchOrderNotAllowed();
            }
        }

        order.metadata.taker = msg.sender;
        order.metadata.status = Status.Matched;
        uint256 takerPremium = order.premiums.notional - order.premiums.makerPremium;
        order.premiums.takerPremium = takerPremium;
        uint256 balBefore = IERC20(order.metadata.collateralToken).balanceOf(address(this));
        IERC20(order.metadata.collateralToken).safeTransferFrom(msg.sender, address(this), takerPremium);
        if (IERC20(order.metadata.collateralToken).balanceOf(address(this)) - balBefore != takerPremium) {
            revert Errors.OrderBook_UnableToMatchOrder();
        }

        uint256 fee = order.premiums.notional - order.metadata.payOut;
        IERC20(order.metadata.collateralToken).safeTransfer(optionsFeeAddress, fee);

        _mint(msg.sender, orderId, 1, "");
        _registerOrderForSettlement(orderId);
        emit OrderMatched(orderId, msg.sender, takerPremium);
    }

    //@@inheritdoc
    function exerciseOrder(uint256 orderId) external returns (uint256) {
        BinaryOption storage order = orders[orderId];
        if (order.metadata.status != Status.Settled) {
            revert Errors.OrderBook_OrderMustBeSettled();
        }

        if (block.timestamp < order.metadata.exerciseWindowStart) {
            revert Errors.OrderBook_NotWithinExerciseWindow();
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
        if (msg.sender != order.metadata.maker) {
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
        if (msg.sender != order.metadata.maker) {
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
                IERC20(order.metadata.collateralToken).safeTransferFrom(msg.sender, address(this), premiumIncrease);
                emit PremiumIncreased(orderId, updateOrder.premium);
            } else {
                uint256 premiumDecrease = order.premiums.makerPremium - updateOrder.premium;
                if (premiumDecrease < config.getApprovedToken(order.metadata.collateralToken).minCollateralAmount) {
                    revert Errors.OrderBook_LessThanMinCollateralAmount();
                }
                order.premiums.makerPremium = updateOrder.premium;
                IERC20(order.metadata.collateralToken).safeTransfer(msg.sender, premiumDecrease);
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

    function _useBeforeTokenTransfer() internal view override returns (bool) {
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
        return Premiums({makerPremium: premium, takerPremium: 0, notional: notional});
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
            maker: msg.sender,
            taker: address(0),
            collateralToken: collateralToken,
            initialStrike: strike,
            finalStrike: 0,
            payOut: notional - (notional / 100),
            expiry: expiry,
            expiryType: expiryType,
            exerciseWindowStart: block.timestamp,
            exerciseWindowEnd: 0,
            allowed: allowed
        });
    }
}
