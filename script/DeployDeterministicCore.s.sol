// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

import {BaseScript} from "./Base.s.sol";
import {DoefinV1Config} from "../src/DoefinV1Config.sol";
import {DoefinV1OrderBook} from "../src/DoefinV1OrderBook.sol";
import {BlockHeaderUtils} from "../src/libraries/BlockHeaderUtils.sol";
import {DoefinV1BlockHeaderOracle} from "../src/DoefinV1BlockHeaderOracle.sol";

/// @notice Deploys all V1 Core contracts at deterministic addresses across chains:
/// 1. {DoefinV1Config}
///
/// @dev Reverts if any contract has already been deployed.
contract DeployDeterministicCore is BaseScript {
    address public feeAddress;
    uint256 public initialBlockHeight;

    function run() public virtual broadcast returns (DoefinV1Config config) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        feeAddress = 0x94c5D1D0E682ebEfcfFfeF1645f40947E572e54a;
        initialBlockHeight = 838_886;

        bytes32 salt = constructCreate2Salt();
        config = new DoefinV1Config{salt: salt}();
        DoefinV1BlockHeaderOracle blockHeaderOracle =
                    new DoefinV1BlockHeaderOracle{salt: salt}(BlockHeaderUtils.setupInitialBlocks(), initialBlockHeight);

        config.setFeeAddress(feeAddress);
        config.setBlockHeaderOracle(address(blockHeaderOracle));
        DoefinV1OrderBook orderBook = new DoefinV1OrderBook{salt: salt}(address(config));

        config.setOrderBook(address(orderBook));
        vm.stopBroadcast();
    }
}
