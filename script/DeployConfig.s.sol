// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { DoefinV1Config } from "../src/DoefinV1Config.sol";

contract DeployConfig is BaseScript {
    address public feeAddress;

    function run() public virtual returns (DoefinV1Config config) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        feeAddress = 0x94c5D1D0E682ebEfcfFfeF1645f40947E572e54a;

        config = new DoefinV1Config();
        config.setFeeAddress(feeAddress);

        vm.stopBroadcast();
    }
}
