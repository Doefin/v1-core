// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { IERC20, Base_Test } from "./Base.t.sol";
import { Test } from "forge-std/Test.sol";
import { Errors, DoefinV1OrderBook, IDoefinV1OrderBook } from "../src/DoefinV1OrderBook.sol";
import { IDoefinOptionsManager, DoefinV1OptionsManager } from "../src/DoefinV1OptionsManager.sol";

/// @title DoefinV1OrderBook_Test
contract DoefinV1OrderBook_Test is Base_Test {
    DoefinV1OrderBook public orderBook;
    uint256 public constant minCollateralTokenAmount = 100;
    uint256 public constant depositBound = 5000e6;

    function setUp() public virtual override {
        Base_Test.setUp();
        Base_Test.deployFactory();

        DoefinV1OptionsManager optionsManager =
            DoefinV1OptionsManager(factory.createOptionsManager(address(0), address(0), users.feeAddress));
        orderBook =
            DoefinV1OrderBook(factory.createOrderBook(address(dai), minCollateralTokenAmount, address(optionsManager)));

        vm.startBroadcast(optionsManager.owner());
        optionsManager.setOrderBookAddress(address(orderBook));
        vm.stopBroadcast();
    }

    /*//////////////////////////////////////////////////////////////
                      CREATE ORDER
    //////////////////////////////////////////////////////////////*/

    function testFail__createOrderWithZeroStrike(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address counterparty
    )
        public
    {
        vm.assume(strike == 0);
        vm.assume(expiry != 0);
        vm.assume(counterparty != address(0));
        vm.assume(amount >= minCollateralTokenAmount);

        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        orderBook.createOrder(strike, amount, expiry, IDoefinV1OrderBook.ExpiryType.BlockNumber, isLong, allowed);
    }

    function testFail__createOrderWithAmountLessThanMinStrike(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address counterparty
    )
        public
    {
        vm.assume(strike != 0);
        vm.assume(expiry != 0);
        vm.assume(counterparty != address(0));
        vm.assume(amount < minCollateralTokenAmount);

        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        orderBook.createOrder(strike, amount, expiry, IDoefinV1OrderBook.ExpiryType.BlockNumber, isLong, allowed);
    }

    function testFail__createOrderWithZeroExpiry(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address counterparty
    )
        public
    {
        vm.assume(strike != 0);
        vm.assume(expiry == 0);
        vm.assume(counterparty != address(0));
        vm.assume(amount >= minCollateralTokenAmount);

        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        orderBook.createOrder(strike, amount, expiry, IDoefinV1OrderBook.ExpiryType.BlockNumber, isLong, allowed);
    }

    function testFail__TransferTokenAfterCreateOrder(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address counterparty
    )
        public
    {
        vm.assume(strike != 0);
        vm.assume(expiry != 0);
        vm.assume(counterparty != address(0));
        vm.assume(amount >= minCollateralTokenAmount && amount <= depositBound);

        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);

        uint256 orderId =
            orderBook.createOrder(strike, amount, expiry, IDoefinV1OrderBook.ExpiryType.BlockNumber, isLong, allowed);
        orderBook.safeTransferFrom(users.alice, users.broker, orderId, 1, "");
    }

    function test__createOrder(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address counterparty
    )
        public
    {
        vm.assume(strike != 0);
        vm.assume(expiry != 0);
        vm.assume(counterparty != address(0));
        vm.assume(amount >= minCollateralTokenAmount && amount <= depositBound);

        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderCreated(0);

        uint256 orderId =
            orderBook.createOrder(strike, amount, expiry, IDoefinV1OrderBook.ExpiryType.BlockNumber, isLong, allowed);
        assertEq(orderBook.balanceOf(users.alice, orderId), 1);
    }

    /*//////////////////////////////////////////////////////////////
                  MATCH ORDER
    //////////////////////////////////////////////////////////////*/
    function testFail__matchOrderAfterExpiry(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address counterparty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(counterparty != address(0));
        vm.assume(amount >= minCollateralTokenAmount && amount <= depositBound);

        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);
        uint256 orderId =
            orderBook.createOrder(strike, amount, expiry, IDoefinV1OrderBook.ExpiryType.BlockNumber, isLong, allowed);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        vm.warp(block.timestamp + 3 days);
        dai.approve(address(orderBook), amount);
        orderBook.matchOrder(orderId);
        vm.stopBroadcast();
    }

    function testFail__matchOrderWithCounterPartyNotAllowed(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address counterparty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(counterparty != address(0) && counterparty != users.broker);
        vm.assume(amount >= minCollateralTokenAmount && amount <= depositBound);

        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);
        uint256 orderId =
            orderBook.createOrder(strike, amount, expiry, IDoefinV1OrderBook.ExpiryType.BlockNumber, isLong, allowed);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), amount);
        orderBook.matchOrder(orderId);
        vm.stopBroadcast();
    }

    function testFail__TransferTokenAfterMatchOrder(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address counterparty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(counterparty != address(0));
        vm.assume(amount >= minCollateralTokenAmount && amount <= depositBound);

        address[] memory allowed = new address[](1);
        allowed[0] = users.broker;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);
        uint256 orderId =
            orderBook.createOrder(strike, amount, expiry, IDoefinV1OrderBook.ExpiryType.BlockNumber, isLong, allowed);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), amount);

        orderBook.matchOrder(orderId);
        orderBook.safeTransferFrom(users.broker, users.alice, orderId, 1, "");
        vm.stopBroadcast();
    }

    function test__matchOrderWithEmptyAllowedList(uint256 strike, uint256 amount, uint256 expiry, bool isLong) public {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(amount >= minCollateralTokenAmount && amount <= depositBound);

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);

        address[] memory allowed = new address[](0);

        uint256 orderId =
            orderBook.createOrder(strike, amount, expiry, IDoefinV1OrderBook.ExpiryType.BlockNumber, isLong, allowed);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), amount);

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderMatched(orderId, users.broker, amount);

        uint256 feeBalBefore = IERC20(orderBook.collateralToken()).balanceOf(users.feeAddress);
        orderBook.matchOrder(orderId);
        vm.stopBroadcast();
        uint256 orderBookBalAfter = IERC20(orderBook.collateralToken()).balanceOf(address(orderBook));

        DoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        assertEq(order.counterparty, users.broker);
        assertEq(order.payOffAmount, amount * 2 - order.premium);

        assertEq(orderBook.balanceOf(users.broker, orderId), 1);
        assertEq(IERC20(order.collateralToken).balanceOf(users.feeAddress) - feeBalBefore, order.premium);
        assertEq((order.amount * 2) - orderBookBalAfter, order.premium);
    }

    function test__FailToMatchOrderWhenOrderIsAlreadyMatched(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address counterparty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(amount >= minCollateralTokenAmount && amount <= depositBound);
        vm.assume(counterparty == users.rick || counterparty == users.james);

        address[] memory allowed = new address[](3);
        allowed[0] = users.broker;
        allowed[1] = users.rick;
        allowed[2] = users.james;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);
        uint256 orderId =
            orderBook.createOrder(strike, amount, expiry, IDoefinV1OrderBook.ExpiryType.BlockNumber, isLong, allowed);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), amount);

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderMatched(orderId, users.broker, amount);

        uint256 feeBalBefore = IERC20(orderBook.collateralToken()).balanceOf(users.feeAddress);
        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

        vm.startBroadcast(counterparty);
        dai.approve(address(orderBook), amount);

        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_OrderAlreadyMatched.selector));
        orderBook.matchOrder(orderId);
        vm.stopBroadcast();
    }

    function test__matchOrderWithNonEmptyAllowedList(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address counterparty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(amount >= minCollateralTokenAmount && amount <= depositBound);
        vm.assume(counterparty == users.broker || counterparty == users.rick || counterparty == users.james);

        address[] memory allowed = new address[](3);
        allowed[0] = users.broker;
        allowed[1] = users.rick;
        allowed[2] = users.james;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);
        uint256 orderId =
            orderBook.createOrder(strike, amount, expiry, IDoefinV1OrderBook.ExpiryType.BlockNumber, isLong, allowed);
        vm.stopBroadcast();

        vm.startBroadcast(counterparty);
        dai.approve(address(orderBook), amount);

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderMatched(orderId, counterparty, amount);

        uint256 feeBalBefore = IERC20(orderBook.collateralToken()).balanceOf(users.feeAddress);
        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

        uint256 orderBookBalAfter = IERC20(orderBook.collateralToken()).balanceOf(address(orderBook));

        DoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        assertEq(order.counterparty, counterparty);
        assertEq(order.payOffAmount, amount * 2 - order.premium);

        assertEq(orderBook.balanceOf(counterparty, orderId), 1);
        assertEq(IERC20(order.collateralToken).balanceOf(users.feeAddress) - feeBalBefore, order.premium);
        assertEq((order.amount * 2) - orderBookBalAfter, order.premium);
    }

    /*//////////////////////////////////////////////////////////////
              EXERCISE ORDER
    //////////////////////////////////////////////////////////////*/
    function testFail__exerciseOrderWhenOrderIsNotSettled(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address counterparty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(counterparty != address(0));
        vm.assume(amount >= minCollateralTokenAmount && amount <= depositBound);

        address[] memory allowed = new address[](1);
        allowed[0] = users.broker;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);
        uint256 orderId =
            orderBook.createOrder(strike, amount, expiry, IDoefinV1OrderBook.ExpiryType.BlockNumber, isLong, allowed);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), amount);

        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

        orderBook.exerciseOrder(orderId);
    }

    function testFail__exerciseOrderWhenExerciseWindowHasNotStarted(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        uint256 timestamp,
        bool isLong,
        address counterparty,
        uint256 blockNumber,
        uint256 difficulty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(timestamp != 0);
        vm.assume(counterparty != address(0));
        vm.assume(blockNumber > expiry);
        vm.assume(amount >= minCollateralTokenAmount && amount <= depositBound);

        address[] memory allowed = new address[](1);
        allowed[0] = users.broker;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);
        uint256 orderId =
            orderBook.createOrder(strike, amount, expiry, IDoefinV1OrderBook.ExpiryType.BlockNumber, isLong, allowed);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), amount);

        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

        vm.startBroadcast(orderBook.optionsManager());
        orderBook.settleOrder(orderId, blockNumber, timestamp, difficulty);
        vm.stopBroadcast();

        rewind(1);
        orderBook.exerciseOrder(orderId);
    }

    function test__exerciseOrderWhenExpiryIsBlockNumber(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        uint256 timestamp,
        bool isLong,
        address counterparty,
        uint256 blockNumber,
        uint256 difficulty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(timestamp != 0);
        vm.assume(counterparty != address(0));
        vm.assume(blockNumber > expiry);
        vm.assume(amount >= minCollateralTokenAmount && amount <= depositBound);

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);

        address[] memory allowed = new address[](1);
        allowed[0] = users.broker;

        uint256 orderId =
            orderBook.createOrder(strike, amount, expiry, IDoefinV1OrderBook.ExpiryType.BlockNumber, isLong, allowed);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), amount);

        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

        vm.startBroadcast(orderBook.optionsManager());
        orderBook.settleOrder(orderId, blockNumber, timestamp, difficulty);
        vm.stopBroadcast();

        address winner;
        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        if (
            order.position == IDoefinV1OrderBook.Position.Long && order.finalStrike > order.initialStrike
                || order.position == IDoefinV1OrderBook.Position.Short && order.finalStrike < order.initialStrike
        ) {
            winner = order.writer;
        } else {
            winner = order.counterparty;
        }

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderExercised(orderId, orderBook.getOrder(orderId).payOffAmount, winner);
        orderBook.exerciseOrder(orderId);
    }

    function test__exerciseOrderWhenExpiryIsTimestamp(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        uint256 timestamp,
        bool isLong,
        address counterparty,
        uint256 blockNumber,
        uint256 difficulty
    )
    public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(timestamp > expiry);
        vm.assume(counterparty != address(0));
        vm.assume(blockNumber != 0);
        vm.assume(amount >= minCollateralTokenAmount && amount <= depositBound);

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);

        address[] memory allowed = new address[](1);
        allowed[0] = users.broker;

        uint256 orderId =
                            orderBook.createOrder(strike, amount, expiry, IDoefinV1OrderBook.ExpiryType.Timestamp, isLong, allowed);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), amount);

        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

        vm.startBroadcast(orderBook.optionsManager());
        orderBook.settleOrder(orderId, blockNumber, timestamp, difficulty);
        vm.stopBroadcast();

        address winner;
        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        if (
            order.position == IDoefinV1OrderBook.Position.Long && order.finalStrike > order.initialStrike
            || order.position == IDoefinV1OrderBook.Position.Short && order.finalStrike < order.initialStrike
        ) {
            winner = order.writer;
        } else {
            winner = order.counterparty;
        }

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderExercised(orderId, orderBook.getOrder(orderId).payOffAmount, winner);
        orderBook.exerciseOrder(orderId);
    }
}
