// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import {Base_Test} from "./Base.t.sol";
import {Test} from "forge-std/Test.sol";
import {IDoefinConfig} from "../src/interfaces/IDoefinConfig.sol";
import {DoefinV1OptionsManager} from "../src/DoefinV1OptionsManager.sol";

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
}
