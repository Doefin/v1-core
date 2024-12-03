// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

library Lib {
    function _generateSalt(address deployer) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(deployer, block.timestamp, "DoefinV1Config"));
    }
}
