// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Base_Test } from "./Base.t.sol";
import { Test } from "forge-std/Test.sol";
import { IDoefinFactory } from "../src/interfaces/IDoefinFactory.sol";
import { DoefinV1OptionsManager } from "../src/DoefinV1OptionsManager.sol";

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
        factory.createOptionsManager(address(1), address(1), address(1));
    }

    function test_AddTokenToApproveList_NotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(users.broker);
        factory.addTokenToApprovedList(address(dai), 100);
    }

    function test_RemoveTokenFromApproveList_NotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(users.broker);
        factory.removeTokenFromApprovedList(address(dai));
    }

    function test_AddTokenToApproveList() public {
        vm.expectEmit();
        emit IDoefinFactory.AddTokenToApprovedList(address(dai));
        factory.addTokenToApprovedList(address(dai), 100);
    }

    function test_RemoveTokenFromApproveList() public {
        vm.expectEmit();
        emit IDoefinFactory.RemoveTokenFromApprovedList(address(dai));
        factory.removeTokenFromApprovedList(address(dai));
    }

    function test_CreateOrderBook(address collateralToken, uint256 minStrikeAmount) public {
        vm.assume(minStrikeAmount != 0);
        vm.assume(collateralToken != address(0));

        DoefinV1OptionsManager optionsManager =
            DoefinV1OptionsManager(factory.createOptionsManager(address(0), address(0), users.feeAddress));

        address orderBookAddress = factory.createOrderBook(collateralToken, minStrikeAmount, address(optionsManager));
//        assertEq(factory.getOrderBook(orderBookAddress).orderBookAddress, orderBookAddress);
    }

    function test_CreateOptionsManager(
        address orderBook,
        address blockHeaderOracle,
        address optionsFeeAddress
    )
        public
    {
        address optionsManagerAddress = factory.createOptionsManager(orderBook, blockHeaderOracle, optionsFeeAddress);
        assertNotEq(optionsManagerAddress, address(0));
    }
}
