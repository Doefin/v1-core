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
        config.addTokenToApprovedList(address(dai), 100);
    }

    function test_RemoveTokenFromApproveList_NotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(users.broker);
        config.removeTokenFromApprovedList(address(dai));
    }

    function test_AddTokenToApproveList() public {
        vm.expectEmit();
        emit IDoefinConfig.AddTokenToApprovedList(address(dai));
        config.addTokenToApprovedList(address(dai), 100);
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
}
