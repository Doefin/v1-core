// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { DoefinV1Config } from "../src/DoefinV1Config.sol";
import { MockToken } from "../test/mocks/MockToken.sol";

/// @notice Deploys MockToken
contract DeployMockToken is BaseScript {
    address public feeAddress;
    uint256 public initialBlockHeight;

    function run(address configAddress) public virtual returns (MockToken mockToken) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        mockToken = MockToken(0x1CE730de98ff5a144980D57dbfcc8d5011058aD7);
        uint256 priceFeedHeartbeat = 24 * 60 * 60;
        DoefinV1Config(configAddress).addTokenToApprovedList(address(0x1CE730de98ff5a144980D57dbfcc8d5011058aD7), 100);

        vm.stopBroadcast();
    }
}
