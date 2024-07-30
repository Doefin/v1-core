// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

import {BaseScript} from "./Base.s.sol";
import {DoefinV1Config} from "../src/DoefinV1Config.sol";

/// @notice Deploys all V1 Core contracts at deterministic addresses across chains:
/// 1. {DoefinV1Config}
///
/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicCore is BaseScript {
    function run(address initialAdmin) public virtual broadcast returns (DoefinV1Config config) {
        bytes32 salt = constructCreate2Salt();
        config = new DoefinV1Config{salt: salt}();
    }
}
