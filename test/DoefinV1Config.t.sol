// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Base_Test } from "./Base.t.sol";
import { Test } from "forge-std/Test.sol";
import { IDoefinConfig } from "../src/interfaces/IDoefinConfig.sol";
import { Errors } from "../src/libraries/Errors.sol";

/// @title DoefinV1Config_Test
contract DoefinV1Config_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
        Base_Test.deployConfig();
    }

    function test_AddTokenToApproveList_NotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(users.broker);
        config.addTokenToApprovedList(address(dai), 100, address(daiUsdPriceFeed), 0);
    }

    function test_RemoveTokenFromApproveList_NotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(users.broker);
        config.removeTokenFromApprovedList(address(dai));
    }

    function test_AddTokenToApproveList() public {
        vm.expectEmit();
        emit IDoefinConfig.AddTokenToApprovedList(address(dai));
        config.addTokenToApprovedList(address(dai), 100, address(usdcUsdPriceFeed), 0);
    }

    function test_RemoveTokenFromApproveList() public {
        vm.expectEmit();
        emit IDoefinConfig.RemoveTokenFromApprovedList(address(dai));
        config.removeTokenFromApprovedList(address(dai));
    }

    function test_SetFee_NotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(users.broker);
        config.setFee(200);
    }

    function test_SetFee_InvalidFee() public {
        vm.expectRevert(Errors.Config_InvalidFee.selector);
        config.setFee(10_001); // Trying to set fee > 100%
    }

    function test_SetFee() public {
        uint256 newFee = 200; // 2%
        vm.expectEmit();
        emit IDoefinConfig.FeeSet(newFee);
        config.setFee(newFee);
        assertEq(config.getFee(), newFee, "Fee was not set correctly");
    }

    function test_SetOrderBook_NotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(users.broker);
        config.setOrderBook(address(1));
    }

    function test_SetOrderBook_ZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        config.setOrderBook(address(0));
    }

    function test_SetOrderBook() public {
        address newOrderBook = address(1);
        vm.expectEmit();
        emit IDoefinConfig.SetOrderBook(newOrderBook);
        config.setOrderBook(newOrderBook);
        assertEq(config.getOrderBook(), newOrderBook, "OrderBook was not set correctly");
    }

    function test_SetFeeAddress_NotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(users.broker);
        config.setFeeAddress(address(1));
    }

    function test_SetFeeAddress_ZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        config.setFeeAddress(address(0));
    }

    function test_SetFeeAddress() public {
        address newFeeAddress = address(1);
        vm.expectEmit();
        emit IDoefinConfig.SetFeeAddress(newFeeAddress);
        config.setFeeAddress(newFeeAddress);
        assertEq(config.getFeeAddress(), newFeeAddress, "FeeAddress was not set correctly");
    }

    function test_SetBlockHeaderOracle_NotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(users.broker);
        config.setBlockHeaderOracle(address(1));
    }

    function test_SetBlockHeaderOracle_ZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        config.setBlockHeaderOracle(address(0));
    }

    function test_SetBlockHeaderOracle() public {
        address newOracle = address(1);
        vm.expectEmit();
        emit IDoefinConfig.SetBlockHeaderOracle(newOracle);
        config.setBlockHeaderOracle(newOracle);
        assertEq(config.getBlockHeaderOracle(), newOracle, "BlockHeaderOracle was not set correctly");
    }

    function test_SetTrustedForwarder_NotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(users.broker);
        config.setTrustedForwarder(address(1));
    }

    function test_SetTrustedForwarder_ZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        config.setTrustedForwarder(address(0));
    }

    function test_SetTrustedForwarder() public {
        address newForwarder = address(1);
        vm.expectEmit();
        emit IDoefinConfig.SetTrustedForwarder(newForwarder);
        config.setTrustedForwarder(newForwarder);
        assertEq(config.getTrustedForwarder(), newForwarder, "TrustedForwarder was not set correctly");
    }

    function test_SetAuthorizedRelayer_NotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(users.broker);
        config.setAuthorizedRelayer(address(1));
    }

    function test_SetAuthorizedRelayer_ZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        config.setAuthorizedRelayer(address(0));
    }

    function test_SetAuthorizedRelayer() public {
        address newRelayer = address(1);
        vm.expectEmit();
        emit IDoefinConfig.SetAuthorizedRelayer(newRelayer);
        config.setAuthorizedRelayer(newRelayer);
        assertEq(config.getAuthorizedRelayer(), newRelayer, "AuthorizedRelayer was not set correctly");
    }
}
