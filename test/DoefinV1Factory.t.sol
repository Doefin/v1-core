// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Base_Test } from "./Base.t.sol";
import { Test } from "forge-std/Test.sol";
import { IDoefinFactory } from "../src/interfaces/IDoefinFactory.sol";

/// @title DoefinV1Factory_Test
contract DoefinV1Factory_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
        Base_Test.deployFactory();
    }

    function test_CreateOrderBook_NotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(users.alice);
        factory.createOrderBook(address(dai), 10, address(1));
    }

    function test_CreateOptionsManager_NotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(users.alice);
        factory.createOptionsManager(address(1), address(1));
    }

    function test_AddTokenToApproveList_NotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(users.broker);
        factory.addTokenToApprovedList(address(dai));
    }

    function test_RemoveTokenFromApproveList_NotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(users.broker);
        factory.removeTokenFromApprovedList(address(dai));
    }

    function test_AddTokenToApproveList() public {
        vm.expectEmit();
        emit IDoefinFactory.AddTokenToApprovedList(address(dai));
        factory.addTokenToApprovedList(address(dai));
    }

    function test_RemoveTokenFromApproveList() public {
        vm.expectEmit();
        emit IDoefinFactory.RemoveTokenFromApprovedList(address(dai));
        factory.removeTokenFromApprovedList(address(dai));
    }

    function test_CreateOrderBook(address strikeToken, uint256 minStrikeAmount, address optionsManager) public {
        vm.assume(minStrikeAmount != 0);
        vm.assume(strikeToken != address(0));
        vm.assume(optionsManager != address(0));

        address orderBookAddress = factory.createOrderBook(strikeToken, minStrikeAmount, optionsManager);
        assertEq(factory.getOrderBook(orderBookAddress).orderBookAddress, orderBookAddress);
    }

    function test_CreateOptionsManager(address orderBook, address blockHeaderOracle) public {
        address optionsManagerAddress = factory.createOptionsManager(orderBook, blockHeaderOracle);
        assertNotEq(optionsManagerAddress, address(0));
    }
}
