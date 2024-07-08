// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "../interfaces/IDoefinBlockHeaderOracle.sol";

/// @title BlockHeaderUtils
/// @notice Library that implements ...
library BlockHeaderUtils {

    /**
     * @dev Get the hash of the block header
     * @param blockHeader The block header to hash
     * @return the hash of the block header
     * @notice Values must be encoded in little-endian byte order. Since the EVM
     * uses big-endian byte order, we must reverse the bytes of all values prior to encoding.
     * Implementation of the bitcoin double-hash algorithm. Note that we reverse the byte order
     * to allow the result to be interpreted as a uint256 value in big-endian byte order.
     */
    function getCurrentBlockHeaderHash(IDoefinBlockHeaderOracle.BlockHeader memory blockHeader) internal pure returns (bytes32) {
        bytes memory data = abi.encodePacked(
            reverseUint32(blockHeader.version),
            reverseBytes32(blockHeader.prevBlockHash),
            reverseBytes32(blockHeader.merkleRootHash),
            reverseUint32(blockHeader.timestamp),
            reverseUint32(blockHeader.nBits),
            reverseUint32(blockHeader.nonce)
        );

        if (data.length != 80) {
            revert();
        }

        return reverseBytes32(sha256(abi.encodePacked(sha256(data))));
    }

    /**
     * @dev Return true/false if the block header hash is valid
     * @param currentBlockHeader The block header to hash
     * @param nextBlockHeader The block header to hash
     * @return true/false
     * @notice
     */
    function isValidBlockHeaderHash(
        IDoefinBlockHeaderOracle.BlockHeader memory currentBlockHeader,
        IDoefinBlockHeaderOracle.BlockHeader memory nextBlockHeader
    )
        internal
        view
        returns (bool)
    {
        uint256 threshold = currentThreshold(currentBlockHeader);
        bytes32 hash = getCurrentBlockHeaderHash(nextBlockHeader);

        return uint256(hash) < threshold;
    }

    /**
     * @dev Return true/false if the block header hash is valid
     * @param currentBlockHeader The block header to hash
     * @param nextBlockHeader The block header to hash
     * @return true/false
     * @notice
     */
    function currentThreshold(IDoefinBlockHeaderOracle.BlockHeader memory currentBlockHeader)
        internal
        view
        returns (uint256)
    {
        // The target threshold is calculated from the nBits encoding as:
        //
        // target = significand * 256 ^ (exponent - 3)
        //
        // Where the exponent is encoded as the first byte of the nBits value
        // and the significand is the remaining bytes.

        uint256 exponent = uint256(currentBlockHeader.nBits) >> 24;
        uint256 significand = uint256(currentBlockHeader.nBits & 0xffffff);

        if (exponent <= 3) {
            return significand >> (8 * (3 - exponent));
        } else {
            return significand << (8 * (exponent - 3));
        }
    }


    function reverseUint32(uint32 input) internal pure returns (uint32) {
        uint32 v = input;

        // swap bytes
        v = ((v & 0xFF00FF00) >> 8) | ((v & 0x00FF00FF) << 8);

        // swap 2-byte long pairs
        v = (v >> 16) | (v << 16);
        return v;
    }

    function reverseBytes32(bytes32 input) internal pure returns (bytes32) {
        uint256 v = uint256(input);

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8)
            | ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16)
            | ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32)
            | ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64)
            | ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);

        return bytes32(v);
    }
}
