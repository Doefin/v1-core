// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Errors } from "./libraries/Errors.sol";
import { BlockHeaderUtils } from "./libraries/BlockHeaderUtils.sol";
import { IDoefinBlockHeaderOracle } from "./interfaces/IDoefinBlockHeaderOracle.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DoefinV1OptionsManager } from "./DoefinV1OptionsManager.sol";

/**
 * @title DoefinV1BlockHeaderOracle
 * @dev The block header oracle is responsible for verifying new bitcoin block header
 * The contract is initialized with 17 confirmed blocks on the bitcoin blockchain.
 * As new blocks are mined and confirmed, they are submitted to this contract for validation.
 *
 * Validating a block header is a critical part of maintaining the integrity and security of the bitcoin
 * block header oracle.
 * The contract uses the bitcoin consensus rules for validating a block header. The rules are specified as:
 * 1. Check Block Header Structure
 * 2. Verify the Previous Block Hash: Check that the hashPrevBlock field matches the hash of the previous block.
 *    This ensures the blockchain is properly linked and ordered.
 * 3. Validate the Timestamp: Check that the block’s timestamp is greater than the median of the previous 11 blocks.
 * 4. Validate the Proof of Work: Calculate the hash of the block header using the double SHA-256 hashing algorithm
 *    and ensure it is less than the target specified by nBits.
 * 5. Verify the Difficulty Target (nBits): Ensure that the difficulty target (nBits) of the block matches the expected
 *    value. Difficulty is adjusted every 2016 blocks to maintain the 10-minute block interval.
 *
 * After validating the new block header, the contract dispatches the new difficulty to the Options Manager for
 * settlement
 */
contract DoefinV1BlockHeaderOracle is IDoefinBlockHeaderOracle, Ownable {
    /// @notice Track the index of the next block in the ring buffer
    uint256 public nextBlockIndex;

    /// @notice Track the total number of timestamps
    uint256 public timestampCount;

    /// @notice The total number of timestamps to be stored
    uint256 public constant TIMESTAMP_SIZE = 11;

    /// @notice The total number of initial blocks to be stored
    uint256 public constant BLOCK_HEADER_SIZE = 17;

    /// @notice Ring buffer to store the block headers
    BlockHeader[BLOCK_HEADER_SIZE] public blockHeaders;

    /// @notice A sorted list of timestamps
    uint256[TIMESTAMP_SIZE] public sortedTimestamps;

    constructor(BlockHeader[BLOCK_HEADER_SIZE] memory initialBlockHeaders, uint256 initialBlockHeight) {
        for (uint256 i = 0; i < BLOCK_HEADER_SIZE; ++i) {
            blockHeaders[i] = initialBlockHeaders[i];
        }

        nextBlockIndex = 0;
        timestampCount = 0;
    }

    /// @inheritdoc IDoefinBlockHeaderOracle
    function submitNextBlock(BlockHeader calldata newBlockHeader) public {
        BlockHeader memory currentBlockHeader = getLatestBlockHeader();
        if (newBlockHeader.prevBlockHash != BlockHeaderUtils.calculateBlockHash(currentBlockHeader)) {
            revert Errors.BlockHeaderOracle_PrevBlockHashMismatch();
        }

        if (newBlockHeader.timestamp < medianBlockTime()) {
            revert Errors.BlockHeaderOracle_InvalidTimestamp();
        }

        if (!BlockHeaderUtils.isValidBlockHeaderHash(currentBlockHeader, newBlockHeader)) {
            revert();
        }

        blockHeaders[nextBlockIndex] = newBlockHeader;
        nextBlockIndex = (nextBlockIndex + 1) % BLOCK_HEADER_SIZE;

        addTimestamp(newBlockHeader.timestamp);

        emit BlockSubmitted(newBlockHeader.merkleRootHash);
    }

    /// @inheritdoc IDoefinBlockHeaderOracle
    function medianBlockTime() public view returns (uint256) {
        if (timestampCount < TIMESTAMP_SIZE) {
            revert Errors.BlockHeaderOracle_InsufficientTimeStamps();
        }

        return sortedTimestamps[TIMESTAMP_SIZE / 2];
    }

    /// @inheritdoc IDoefinBlockHeaderOracle
    function getLatestBlockHeader() public view returns (BlockHeader memory) {
        require(nextBlockIndex != 0 || timestampCount != 0, "No blocks added yet");
        uint256 latestIndex = (nextBlockIndex == 0) ? BLOCK_HEADER_SIZE - 1 : nextBlockIndex - 1;
        return blockHeaders[latestIndex];
    }

    /**
     * @dev Add timestamps to the sorted list of timestamps
     * @param timestamp The timestamp from the latest block header
     * @notice blockNumber The number at which an order can be settled
     */
    function addTimestamp(uint256 timestamp) internal {
        if (timestampCount < TIMESTAMP_SIZE) {
            uint256 i = timestampCount;
            while (i > 0 && sortedTimestamps[i - 1] > timestamp) {
                sortedTimestamps[i] = sortedTimestamps[i - 1];
                i--;
            }
            sortedTimestamps[i] = timestamp;
            timestampCount++;
        } else {
            for (uint256 i = 1; i < TIMESTAMP_SIZE; i++) {
                sortedTimestamps[i - 1] = sortedTimestamps[i];
            }

            uint256 i = TIMESTAMP_SIZE - 1;
            while (i > 0 && sortedTimestamps[i - 1] > timestamp) {
                sortedTimestamps[i] = sortedTimestamps[i - 1];
                i--;
            }
            sortedTimestamps[i] = timestamp;
        }
    }
}
