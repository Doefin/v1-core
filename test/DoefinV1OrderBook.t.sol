// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19;

import "forge-std/Console.sol";
import { Base_Test } from "./Base.t.sol";
import { Test } from "forge-std/Test.sol";
import { DoefinV1OrderBook } from "../src/DoefinV1OrderBook.sol";
import { IERC7390VanillaOption } from "../src/interfaces/IERC7390VanillaOption.sol";

/// @title DoefinV1Factory_Test
contract DoefinV1OrderBook_Test is Base_Test {
    DoefinV1OrderBook public orderBook;
    uint256 public constant minStrikeTokenAmount = 100;

    function setUp() public virtual override {
        Base_Test.setUp();
        Base_Test.deployFactory();

        orderBook = DoefinV1OrderBook(factory.createOrderBook(address(dai), minStrikeTokenAmount));
    }

    /*//////////////////////////////////////////////////////////////
                      CREATE ORDER
    //////////////////////////////////////////////////////////////*/

    function testFail__createOrderWithZeroStrike() public {
        uint256 strike = 0;
        uint256 amount = 10;
        uint256 expiry = 1_717_523_313_511;
        bool isLong = true;
        address[] memory allowed = new address[](0);

        orderBook.createOrder(strike, amount, expiry, isLong, allowed);
    }

    function testFail__createOrderWithAmountLessThanMinStrike() public {
        uint256 strike = 81_725_299_822_043;
        uint256 amount = 10;
        uint256 expiry = 1_717_523_313_511;
        bool isLong = true;
        address[] memory allowed = new address[](0);
        orderBook.createOrder(strike, amount, expiry, isLong, allowed);
    }

    function testFail__createOrderWithZeroExpiry() public {
        uint256 strike = 81_725_299_822_043;
        uint256 amount = 1000;
        uint256 expiry = 0;
        bool isLong = true;
        address[] memory allowed = new address[](0);
        orderBook.createOrder(strike, amount, expiry, isLong, allowed);
    }

    function test__createOrder() public {
        uint256 strike = 81_725_299_822_043;
        uint256 amount = 1000;
        uint256 expiry = 1_717_525_680_684;
        bool isLong = true;
        address[] memory allowed = new address[](0);

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);

        vm.expectEmit();
        emit IERC7390VanillaOption.OrderCreated(0);

        uint256 orderId = orderBook.createOrder(strike, amount, expiry, isLong, allowed);
        assertEq(orderBook.balanceOf(users.alice, orderId), 1);
    }

    /*//////////////////////////////////////////////////////////////
                  MATCH ORDER
    //////////////////////////////////////////////////////////////*/
    function testFail__matchOrderAfterExpiry() public {
        uint256 strike = 81_725_299_822_043;
        uint256 amount = 1000;
        uint256 expiry = block.timestamp + 2 days;
        bool isLong = true;
        address[] memory allowed = new address[](0);

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

    function testFail__matchOrderWithCounterPartyNotAllowed() public {
        uint256 strike = 81_725_299_822_043;
        uint256 amount = 1000;
        uint256 expiry = block.timestamp + 2 days;
        bool isLong = true;
        address[] memory allowed = new address[](1);
        allowed[0] = users.admin;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);
        uint256 orderId = orderBook.createOrder(strike, amount, expiry, isLong, allowed);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), amount);
        orderBook.matchOrder(orderId, amount);
        vm.stopBroadcast();
    }

    function test__matchOrderWithCounterPartyNotAllowed() public {
        uint256 strike = 81_725_299_822_043;
        uint256 amount = 1000;
        uint256 expiry = block.timestamp + 2 days;
        bool isLong = true;
        address[] memory allowed = new address[](1);
        allowed[0] = users.broker;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), amount);
        uint256 orderId = orderBook.createOrder(strike, amount, expiry, isLong, allowed);
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), amount);

        vm.expectEmit();
        emit IERC7390VanillaOption.OrderMatched(orderId, users.broker, amount);

        orderBook.matchOrder(orderId, amount);
        vm.stopBroadcast();

        DoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        assertEq(order.isMatched, true);
        assertEq(order.counterparty, users.broker);
        assertEq(order.payOffAmount, amount * 2);

        assertEq(orderBook.balanceOf(users.broker, orderId), 1);
    }
}
