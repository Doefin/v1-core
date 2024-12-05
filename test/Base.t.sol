// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Users } from "./utils/Types.sol";
import { Test } from "forge-std/Test.sol";
import { Constants } from "./utils/Constants.sol";
import { MockToken } from "./mocks/MockToken.sol";
import { Assertions } from "./utils/Assertions.sol";
import { DoefinV1Config, IDoefinConfig } from "../src/DoefinV1Config.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is Test, Assertions, Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    IDoefinConfig internal config;
    ERC20 internal dai;
    ERC20 internal usdt;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Deploy the base test contracts.
        dai = new MockToken("Dai Stablecoin", "DAI", 6); // new ERC20("Dai Stablecoin", "DAI");
        usdt = new MockToken("Tether USD", "USDT", 6); // new ERC20("Tether USD", "USDT");

        // Label the base test contracts.
        vm.label({ account: address(dai), newLabel: "DAI" });
        vm.label({ account: address(usdt), newLabel: "USDT" });

        // Create users for testing.
        users = Users({
            admin: createUser("Admin"),
            alice: createUser("Alice"),
            james: createUser("James"),
            rick: createUser("Rick"),
            broker: createUser("Broker"),
            feeAddress: createUser("FeeAddress"),
            relayer: createUser("relayer")
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(dai), to: user, give: 1_000_000e18 });
        deal({ token: address(usdt), to: user, give: 1_000_000e18 });
        return user;
    }

    /// @dev deploy Doefin V1 Config
    function deployConfig() public {
        // Deploy mock price feeds
        config = new DoefinV1Config(address(this));
        config.addTokenToApprovedList(address(dai), 100);
        config.addTokenToApprovedList(address(usdt), 100);
        config.setAuthorizedRelayer(users.relayer);
        vm.label({ account: address(config), newLabel: "DoefinV1Config" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CALL EXPECTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a call to {IERC20.transfer}.
    function expectCallToTransfer(address to, uint256 amount) internal {
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(IERC20.transfer, (to, amount)) });
    }

    /// @dev Expects a call to {IERC20.transfer}.
    function expectCallToTransfer(IERC20 asset, address to, uint256 amount) internal {
        vm.expectCall({ callee: address(asset), data: abi.encodeCall(IERC20.transfer, (to, amount)) });
    }

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(address from, address to, uint256 amount) internal {
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(IERC20.transferFrom, (from, to, amount)) });
    }

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(IERC20 asset, address from, address to, uint256 amount) internal {
        vm.expectCall({ callee: address(asset), data: abi.encodeCall(IERC20.transferFrom, (from, to, amount)) });
    }
}
