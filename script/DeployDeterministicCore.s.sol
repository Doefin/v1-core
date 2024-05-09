// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { DoefinV1Factory } from "../src/DoefinV1Factory.sol";

/// @notice Deploys all V2 Core contracts at deterministic addresses across chains:
/// 1. {DoefinV1Factory}
///
/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicCore is BaseScript {
    function run(address initialAdmin)
        public
        virtual
        broadcast
        returns (DoefinV1Factory factory)
    {
        bytes32 salt = constructCreate2Salt();
        factory = new DoefinV1Factory{ salt: salt }(initialAdmin);
    }
}
