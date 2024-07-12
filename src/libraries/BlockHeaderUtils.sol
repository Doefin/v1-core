// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "../interfaces/IDoefinBlockHeaderOracle.sol";
import "./Errors.sol";

/// @title BlockHeaderUtils
/// @notice Library that implements utils for bitcoin block header hashing
library BlockHeaderUtils {
    /**
     * @dev Return true/false if the block header hash is valid
     * @param currentBlockHeader The block header to hash
     * @param nextBlockHeader The block header to hash
     * @return true/false
     */
    function isValidBlockHeaderHash(
        IDoefinBlockHeaderOracle.BlockHeader memory currentBlockHeader,
        IDoefinBlockHeaderOracle.BlockHeader memory nextBlockHeader
    )
        internal
        view
        returns (bool)
    {
        uint256 target = calculateDifficultyTarget(currentBlockHeader);
        bytes32 hash = calculateBlockHash(nextBlockHeader);

        return uint256(hash) < target;
    }

    /**
     * @dev Get the hash of the block header
     * @param blockHeader The block header to hash
     * @return the hash of the block header
     * @notice The function encodes block header data and applies a double SHA-256 hash.
     * Each element of the block header must be encoded in little-endian byte order. Since the EVM
     * uses big-endian byte order, we reverse the bytes of all values prior to encoding to follow the
     * implementation of the bitcoin double-hash algorithm. Note that we reverse the byte order
     * to allow the result to be interpreted as a uint256 value in big-endian byte order.
     */
    function calculateBlockHash(IDoefinBlockHeaderOracle.BlockHeader memory blockHeader)
        internal
        pure
        returns (bytes32)
    {
        bytes32 hash = blockHeader.prevBlockHash;
        bytes32 root = blockHeader.merkleRootHash;

        bytes memory prevBlockHash = new bytes(32);
        bytes memory merkleRootHash = new bytes(32);
        assembly {
            mstore(add(prevBlockHash, 32), hash)
            mstore(add(merkleRootHash, 32), root)
        }

        //1. Reverse the byte order of each block header field to match the little-endian format required by Bitcoin
        //2. Serialize the block header into an 80-byte array: (4 + 32 + 32 + 4 + 4 + 4) bytes
        bytes memory data = abi.encodePacked(
            reverseBytes(abi.encodePacked(blockHeader.version)),
            reverseBytes(prevBlockHash),
            reverseBytes(merkleRootHash),
            reverseBytes(abi.encodePacked(blockHeader.timestamp)),
            reverseBytes(abi.encodePacked(blockHeader.nBits)),
            reverseBytes(abi.encodePacked(blockHeader.nonce))
        );

        require(data.length == 80, "incorrect data length");

        //3. Calculate the SHA-256 hash of the serialized data
        //4. Convert bytes32 of the first hash to bytes array for second SHA-256 hash
        //5. Calculate the second SHA-256 hash of the bytes array
        bytes32 blockHashBytes32 = sha256(abi.encodePacked(sha256(data)));

        bytes memory blockHash = new bytes(32);
        assembly {
            mstore(add(blockHash, 32), blockHashBytes32)
        }

        //6. refer to step1
        return bytes32(reverseBytes(blockHash));
    }

    /**
     * @dev Reverse bytes data in place
     * @param data The bytes data to reverse
     * @return reversed bytes
     */
    function reverseBytes(bytes memory data) internal pure returns (bytes memory) {
        uint256 length = data.length;
        for (uint256 i = 0; i < length / 2; i++) {
            bytes1 temp = data[i];
            data[i] = data[length - 1 - i];
            data[length - 1 - i] = temp;
        }
        return data;
    }

    /**
     * @dev Calculates the difficulty target of a block header
     * @param blockHeader The block header to hash
     * @return the difficulty target
     * @notice The difficulty target is calculated from the nBits encoding as:
     * target = coefficient * 256 ^ (exponent - 3)
     * Where the exponent is encoded as the first byte of the nBits value
     * and the coefficient is the remaining 3 bytes.
     *
     * The function extracts the first bytes (8-bits) of the nBits value by shifting the value 24 bits to the right and
     * extracts the last 3 bytes (24-bits) of the nBits by doing a bitwise AND with a 24-bit mask 0xFFFFFF.
     */
    function calculateDifficultyTarget(IDoefinBlockHeaderOracle.BlockHeader memory blockHeader)
        internal
        view
        returns (uint256)
    {
        uint256 exponent = uint256(blockHeader.nBits) >> 24;
        uint256 coefficient = uint256(blockHeader.nBits & 0xffffff);

        if (exponent <= 3) {
            return coefficient >> (8 * (3 - exponent)); //coefficient * 2 ^ (8 * (3 - exponent))
        } else {
            return coefficient << (8 * (exponent - 3)); //coefficient * 2 ^ (8 * (exponent - 3))
        }
    }
}
