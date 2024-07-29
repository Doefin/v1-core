// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

import {BaseScript} from "./Base.s.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Initializes the protocol by setting up the config and other related classes.
contract Init is BaseScript {
    function run(IERC20 asset) public broadcast {
        address sender = broadcaster;
        address recipient = vm.addr(vm.deriveKey({mnemonic: mnemonic, index: 1}));

        /*//////////////////////////////////////////////////////////////////////////
                                        SETUP CONFIG LOGIC
        //////////////////////////////////////////////////////////////////////////*/
    }
}
