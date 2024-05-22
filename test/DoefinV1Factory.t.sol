// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19;

import "forge-std/Console.sol";
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
        factory.createOrderBook();
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

    function test_CreateOrderBook() public {
        address orderBookAddress = factory.createOrderBook();
        assertEq(factory.getOrderBook(orderBookAddress).orderBookAddress, orderBookAddress);
    }
}
