// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Base_Test } from "./Base.t.sol";
import { Test } from "forge-std/Test.sol";
import { Errors, DoefinV1OrderBook, IDoefinV1OrderBook } from "../src/DoefinV1OrderBook.sol";
import { IDoefinOptionsManager, DoefinV1OptionsManager } from "../src/DoefinV1OptionsManager.sol";

/// @title DoefinV1OrderBook_Test
contract DoefinV1OrderBook_Test is Base_Test {
    DoefinV1OrderBook public orderBook;
    uint256 public constant minStrikeTokenAmount = 100;
    uint256 public constant depositBound = 5000e6;

    function setUp() public virtual override {
        Base_Test.setUp();
        Base_Test.deployFactory();

        DoefinV1OptionsManager optionsManager =
            DoefinV1OptionsManager(factory.createOptionsManager(address(0), address(0)));
        orderBook =
            DoefinV1OrderBook(factory.createOrderBook(address(dai), minStrikeTokenAmount, address(optionsManager)));

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
        address allowed
    )
        public
    {
        vm.assume(strike == 0);
        vm.assume(expiry != 0);
        vm.assume(allowed != address(0));
        vm.assume(amount >= minStrikeTokenAmount);

        orderBook.createOrder(strike, amount, expiry, isLong, allowed);
    }

    function testFail__createOrderWithAmountLessThanMinStrike(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address allowed
    )
        public
    {
        vm.assume(strike != 0);
        vm.assume(expiry != 0);
        vm.assume(allowed != address(0));
        vm.assume(amount < minStrikeTokenAmount);

        orderBook.createOrder(strike, amount, expiry, isLong, allowed);
    }

    function testFail__createOrderWithZeroExpiry(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address allowed
    )
        public
    {
        vm.assume(strike != 0);
        vm.assume(expiry == 0);
        vm.assume(allowed != address(0));
        vm.assume(amount >= minStrikeTokenAmount);

        orderBook.createOrder(strike, amount, expiry, isLong, allowed);
    }

    function testFail__TransferTokenAfterCreateOrder(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address allowed
    )
        public
    {
        vm.assume(strike != 0);
        vm.assume(expiry != 0);
        vm.assume(allowed != address(0));
        vm.assume(amount >= minStrikeTokenAmount && amount <= depositBound);

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);

        uint256 orderId = orderBook.createOrder(strike, amount, expiry, isLong, allowed);
        orderBook.safeTransferFrom(users.alice, users.broker, orderId, 1, "");
    }

    function test__createOrder(uint256 strike, uint256 amount, uint256 expiry, bool isLong, address allowed) public {
        vm.assume(strike != 0);
        vm.assume(expiry != 0);
        vm.assume(allowed != address(0));
        vm.assume(amount >= minStrikeTokenAmount && amount <= depositBound);

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderCreated(0);

        uint256 orderId = orderBook.createOrder(strike, amount, expiry, isLong, allowed);
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
        address allowed
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(allowed != address(0));
        vm.assume(amount >= minStrikeTokenAmount && amount <= depositBound);

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);
        uint256 orderId = orderBook.createOrder(strike, amount, expiry, isLong, allowed);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        vm.warp(block.timestamp + 3 days);
        dai.approve(address(orderBook), amount);
        orderBook.matchOrder(orderId, amount);
        vm.stopBroadcast();
    }

    function testFail__matchOrderWithCounterPartyNotAllowed(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address allowed
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(allowed != address(0));
        vm.assume(amount >= minStrikeTokenAmount && amount <= depositBound);

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);
        uint256 orderId = orderBook.createOrder(strike, amount, expiry, isLong, allowed);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), amount);
        orderBook.matchOrder(orderId, amount);
        vm.stopBroadcast();
    }

    function testFail__TransferTokenAfterMatchOrder(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address allowed
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(allowed != address(0));
        vm.assume(amount >= minStrikeTokenAmount && amount <= depositBound);

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);
        uint256 orderId = orderBook.createOrder(strike, amount, expiry, isLong, users.broker);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), amount);

        orderBook.matchOrder(orderId, amount);
        orderBook.safeTransferFrom(users.broker, users.alice, orderId, 1, "");
        vm.stopBroadcast();
    }

    function test__matchOrder(uint256 strike, uint256 amount, uint256 expiry, bool isLong, address allowed) public {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(allowed != address(0));
        vm.assume(amount >= minStrikeTokenAmount && amount <= depositBound);

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);
        uint256 orderId = orderBook.createOrder(strike, amount, expiry, isLong, users.broker);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), amount);

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderMatched(orderId, users.broker, amount);

        orderBook.matchOrder(orderId, amount);
        vm.stopBroadcast();

        DoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        assertEq(order.counterparty, users.broker);
        assertEq(order.payOffAmount, amount * 2);

        assertEq(orderBook.balanceOf(users.broker, orderId), 1);
    }

    /*//////////////////////////////////////////////////////////////
              Exercise ORDER
    //////////////////////////////////////////////////////////////*/
    function testFail__exerciseOrderWhenOrderIsNotSettled(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address allowed
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(allowed != address(0));
        vm.assume(amount >= minStrikeTokenAmount && amount <= depositBound);

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);
        uint256 orderId = orderBook.createOrder(strike, amount, expiry, isLong, users.broker);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), amount);

        orderBook.matchOrder(orderId, amount);
        vm.stopBroadcast();

        orderBook.exerciseOrder(orderId);
    }

    function testFail__exerciseOrderWhenExerciseWindowHasNotStarted(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address allowed,
        uint256 blockNumber,
        uint256 difficulty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(allowed != address(0));
        vm.assume(blockNumber > expiry);
        vm.assume(amount >= minStrikeTokenAmount && amount <= depositBound);

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);
        uint256 orderId = orderBook.createOrder(strike, amount, expiry, isLong, users.broker);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), amount);

        orderBook.matchOrder(orderId, amount);
        vm.stopBroadcast();

        vm.startBroadcast(orderBook.optionsManager());
        orderBook.settleOrder(orderId, blockNumber, difficulty);
        vm.stopBroadcast();

        rewind(1);
        orderBook.exerciseOrder(orderId);
    }

    function test__exerciseOrder(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address allowed,
        uint256 blockNumber,
        uint256 difficulty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(allowed != address(0));
        vm.assume(blockNumber > expiry);
        vm.assume(amount >= minStrikeTokenAmount && amount <= depositBound);

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);
        uint256 orderId = orderBook.createOrder(strike, amount, expiry, isLong, users.broker);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), amount);

        orderBook.matchOrder(orderId, amount);
        vm.stopBroadcast();

        vm.startBroadcast(orderBook.optionsManager());
        orderBook.settleOrder(orderId, blockNumber, difficulty);
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
