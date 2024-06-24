// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Errors } from "./libraries/Errors.sol";
import { IDoefinOptionsManager } from "./interfaces/IDoefinOptionsManager.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { IDoefinV1OrderBook } from "./interfaces/IDoefinV1OrderBook.sol";

contract DoefinV1OrderBook is IDoefinV1OrderBook, ERC1155 {
    /// @notice The ERC20 token used as strike token in the trading pair
    IERC20 public immutable collateralToken;

    /// @notice The minimum collateral token amount required for an order to be valid
    uint256 public immutable minCollateralTokenAmount;

    /// @notice The minimum strike token amount required for an order to be valid
    address public immutable optionsManager;

    /// @dev The id of the next order to be created
    uint256 public orderIdCounter;

    /// @dev The mapping of id to option orders
    mapping(uint256 => BinaryOption) public orders;

    modifier onlyOptionsManager() {
        require(msg.sender == optionsManager);
        _;
    }

    constructor(address _collateralToken, uint256 _minCollateralTokenAmount, address _optionsManager) ERC1155("") {
        if (_minCollateralTokenAmount == 0) {
            revert Errors.OrderBook_InvalidMinCollateralAmount();
        }

        if (_collateralToken == address(0) || _optionsManager == address(0)) {
            revert Errors.ZeroAddress();
        }

        collateralToken = IERC20(_collateralToken);
        minCollateralTokenAmount = _minCollateralTokenAmount;
        optionsManager = _optionsManager;
    }

    //@@inheritdoc
    function createOrder(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address allowed
    )
        public
        returns (uint256)
    {
        if (strike == 0) {
            revert Errors.OrderBook_ZeroStrike();
        }

        if (amount < minCollateralTokenAmount) {
            revert Errors.OrderBook_InvalidMinCollateralAmount();
        }

        if (expiry == 0) {
            revert Errors.OrderBook_ZeroExpiry();
        }

        uint256 newOrderId = orderIdCounter;
        BinaryOption memory newBinaryOption = BinaryOption({
            amount: amount,
            position: isLong ? Position.Long : Position.Short,
            collateralToken: address(collateralToken),
            expiry: expiry,
            exerciseWindowStart: block.timestamp,
            exerciseWindowEnd: 0,
            writer: msg.sender,
            counterparty: allowed,
            payOffAmount: amount,
            initialStrike: strike,
            finalStrike: 0,
            isSettled: false
        });

        IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, newOrderId, 1, "");
        orders[newOrderId] = newBinaryOption;
        orderIdCounter++;

        emit OrderCreated(newOrderId);
        return newOrderId;
    }

    //@@inheritdoc
    function matchOrder(uint256 orderId) public {
        BinaryOption storage order = orders[orderId];
        uint256 amount = order.amount;

        if (block.timestamp > order.exerciseWindowStart) {
            revert Errors.OrderBook_MatchOrderExpired();
        }

        if (order.counterparty != msg.sender) {
            revert Errors.OrderBook_MatchOrderNotAllowed();
        }

        uint256 balBefore = IERC20(collateralToken).balanceOf(address(this));
        IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
        if(IERC20(collateralToken).balanceOf(address(this)) - balBefore != amount){
            revert Errors.OrderBook_IncorrectMatchOrderAmount();
        }

        order.counterparty = msg.sender;
        order.payOffAmount += amount;

        _mint(msg.sender, orderId, 1, "");
        _registerOrderForSettlement(orderId);
        emit OrderMatched(orderId, msg.sender, amount);
    }

    //@@inheritdoc
    function exerciseOrder(uint256 orderId) public returns (uint256) {
        BinaryOption storage order = orders[orderId];
        address winner;

        if (!order.isSettled) {
            revert Errors.OrderBook_OrderNotSettled();
        }

        if (block.timestamp < order.exerciseWindowStart) {
            revert Errors.OrderBook_NotWithinExerciseWindow();
        }

        _burn(order.writer, orderId, 1);
        _burn(order.counterparty, orderId, 1);

        if (
            order.position == Position.Long && order.finalStrike > order.initialStrike
                || order.position == Position.Short && order.finalStrike < order.initialStrike
        ) {
            winner = order.writer;
            IERC20(collateralToken).transfer(order.writer, order.payOffAmount);
        } else {
            winner = order.counterparty;
            IERC20(collateralToken).transfer(order.counterparty, order.payOffAmount);
        }

        emit OrderExercised(orderId, order.payOffAmount, winner);
        return orderId;
    }

    //@@inheritdoc
    function settleOrder(
        uint256 orderId,
        uint256 blockNumber,
        uint256 difficulty
    )
        public
        onlyOptionsManager
        returns (bool)
    {
        BinaryOption storage order = orders[orderId];
        if (order.counterparty != address(0) && blockNumber >= order.expiry) {
            order.isSettled = true;
            order.finalStrike = difficulty;
        }

        return true;
    }

    //@@inheritdoc
    function getOrder(uint256 orderId) public view returns (BinaryOption memory) {
        return orders[orderId];
    }

    /**
     * @dev Register an order for settlement in the options manager
     * @param orderId The order id of the order to register
     */
    function _registerOrderForSettlement(uint256 orderId) internal {
        IDoefinOptionsManager(optionsManager).registerOrderForSettlement(orderId);
    }

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
}
