// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Base_Test } from "./Base.t.sol";
import { Test } from "forge-std/Test.sol";
import { Errors, DoefinV1OrderBook, IDoefinV1OrderBook } from "../src/DoefinV1OrderBook.sol";
import { IDoefinOptionsManager, DoefinV1OptionsManager } from "../src/DoefinV1OptionsManager.sol";

/// @title DoefinV1OptionsManager_Test
contract DoefinV1OptionsManager_Test is Base_Test {
    address public blockHeaderOracle;
    DoefinV1OrderBook public orderBook;
    DoefinV1OptionsManager public optionsManager;
    uint256 public constant minCollateralTokenTokenAmount = 100;

    function setUp() public virtual override {
        Base_Test.setUp();
        Base_Test.deployConfig();

        optionsManager = new DoefinV1OptionsManager(address(0), blockHeaderOracle, users.feeAddress);
        orderBook = new DoefinV1OrderBook(address(config), address(optionsManager));
    }

    function test_SetOrderBookAddress_NotOwner(address notOwner) public {
        vm.assume(notOwner != optionsManager.owner());
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(notOwner);
        optionsManager.setOrderBookAddress(address(orderBook));
    }

    function testFail_SetOrderBookAddress_ZeroAddress() public {
        vm.prank(optionsManager.owner());
        optionsManager.setOrderBookAddress(address(0));
    }

    function test_SetOrderBookAddress() public {
        vm.startBroadcast(optionsManager.owner());
        optionsManager.setOrderBookAddress(address(orderBook));
        vm.stopBroadcast();
    }

    function test_SetBlockHeaderOracle_NotOwner(address notOwner, address blockHeaderOracle) public {
        vm.assume(notOwner != optionsManager.owner());
        vm.assume(blockHeaderOracle != address(0));
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(notOwner);
        optionsManager.setBlockHeaderOracleAddress(blockHeaderOracle);
    }

    function testFail_SetBlockHeaderOracle_ZeroAddress() public {
        vm.prank(optionsManager.owner());
        optionsManager.setBlockHeaderOracleAddress(address(0));
    }

    function test_SetBlockHeaderOracle(address blockHeaderOracle) public {
        vm.assume(blockHeaderOracle != address(0));

        vm.startBroadcast(optionsManager.owner());
        optionsManager.setBlockHeaderOracleAddress(blockHeaderOracle);
        vm.stopBroadcast();
    }

    function test_RegisterOrderForSettlement_NotOrderBook(address notOrderBook, uint256 orderId) public {
        vm.startBroadcast(optionsManager.owner());
        optionsManager.setOrderBookAddress(address(orderBook));
        vm.stopBroadcast();

        vm.assume(notOrderBook != address(orderBook));
        vm.expectRevert("OptionsManager: caller is not the order book");

        vm.prank(notOrderBook);
        optionsManager.registerOrderForSettlement(orderId);
    }

    function test_RegisterOrderForSettlement(uint256 orderId) public {
        vm.startBroadcast(optionsManager.owner());
        optionsManager.setOrderBookAddress(address(orderBook));
        vm.stopBroadcast();

        vm.expectEmit();
        emit IDoefinOptionsManager.OrderRegistered(orderId);

        vm.prank(address(orderBook));
        optionsManager.registerOrderForSettlement(orderId);
    }

    function test_settleOrders_NotBlockHeaderOracle(
        address blockHeaderOracle,
        address notBlockHeaderOracle,
        uint256 blockNumber,
        uint256 difficulty,
        uint256 timestamp
    )
        public
    {
        vm.assume(blockHeaderOracle != address(0));
        vm.assume(timestamp != 0);

        vm.startBroadcast(optionsManager.owner());
        optionsManager.setBlockHeaderOracleAddress(blockHeaderOracle);
        vm.stopBroadcast();

        vm.expectRevert("OptionsManager: caller is not block header oracle");

        vm.prank(notBlockHeaderOracle);
        optionsManager.settleOrders(blockNumber, timestamp, difficulty);
    }

    function test_settleOrders(
        address blockHeaderOracle,
        uint256 blockNumber,
        uint256 difficulty,
        uint256 timestamp
    )
        public
    {
        vm.assume(blockHeaderOracle != address(0));
        vm.assume(timestamp != 0);

        vm.startBroadcast(optionsManager.owner());
        optionsManager.setOrderBookAddress(address(orderBook));
        optionsManager.setBlockHeaderOracleAddress(blockHeaderOracle);
        vm.stopBroadcast();

        vm.prank(blockHeaderOracle);
        optionsManager.settleOrders(blockNumber, timestamp, difficulty);
    }

    //    function test_SetOptionsFeeAddress_NotOwner(address notOwner) public {
    //        vm.assume(notOwner != optionsManager.owner());
    //        vm.expectRevert("Ownable: caller is not the owner");
    //
    //        vm.prank(notOwner);
    //        optionsManager.setOrderBookAddress(address(1));
    //    }

    //    function testFail_SetOptionsFeeAddress_ZeroAddress() public {
    //        vm.prank(optionsManager.owner());
    //        optionsManager.setOrderBookAddress(address(0));
    //    }
}
