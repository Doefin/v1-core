// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Errors } from "./libraries/Errors.sol";
import { IDoefinConfig } from "./interfaces/IDoefinConfig.sol";
import { BlockHeaderUtils } from "./libraries/BlockHeaderUtils.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IDoefinV1OrderBook } from "./interfaces/IDoefinV1OrderBook.sol";
import { IDoefinBlockHeaderOracle } from "./interfaces/IDoefinBlockHeaderOracle.sol";

/**
 * @title DoefinV1BlockHeaderOracle
 * @dev The block header oracle is responsible for verifying new bitcoin block header
 * The contract is initialized with a buffer of 17 confirmed blocks on the bitcoin blockchain. Having a buffer of 17
 * blocks ensures that the contract has sufficient historical data to handle reorgs and validate a new chain
 * correctly.
 *
 * As new blocks are mined and confirmed, they are submitted to this contract for validation.
 *
 * Validating a block header is a critical part of maintaining the integrity and security of the bitcoin
 * block header oracle.
 * The contract uses the bitcoin consensus rules for validating a block header. The rules are specified as:
 * 1. Check Block Header Structure
 * 2. Verify the Previous Block Hash: Check that the hashPrevBlock field matches the hash of the previous block.
 *    This ensures the blockchain is properly linked and ordered.
 * 3. Validate the Timestamp: Check that the block’s timestamp is greater than the median of the previous 11 blocks.
 * 4. Validate the Proof of work: Calculate the hash of the block header using the double SHA-256 hashing algorithm
 *    and ensure it is less than the target specified by nBits.
 * 5. Verify the Difficulty Target (nBits): Ensure that the difficulty target (nBits) of the block matches the expected
 *    value. Difficulty is adjusted every 2016 blocks to maintain the 10-minute block interval.
 *
 * After validating the new block header, the contract dispatches the new difficulty to the Options Manager for
 * settlement
 */
contract DoefinV1BlockHeaderOracle is IDoefinBlockHeaderOracle, Ownable {
    /// @notice Doefin Config
    IDoefinConfig public immutable config;

    // @notice Store the block number separately since the block number is not part of the block header information.
    uint256 public currentBlockHeight;

    /// @notice Track the index of the next block in the ring buffer
    uint256 public nextBlockIndex;

    /// @notice The number of blocks to delay before settlement
    uint256 public constant SETTLEMENT_DELAY = 6;

    /// @notice The total number of timestamps to be stored
    uint256 public constant NUM_OF_TIMESTAMPS = 11;

    /// @notice The total number of initial blocks headers to be stored
    uint256 public constant NUM_OF_BLOCK_HEADERS = 17;

    /// @notice Ring buffer to store the block headers
    BlockHeader[NUM_OF_BLOCK_HEADERS] public blockHeaders;

    constructor(
        IDoefinBlockHeaderOracle.BlockHeader[NUM_OF_BLOCK_HEADERS] memory initialBlockHistory,
        uint256 initialBlockHeight,
        address _config
    ) {
        for (uint256 i = 0; i < NUM_OF_BLOCK_HEADERS; ++i) {
            BlockHeader memory blockHeader = initialBlockHistory[i];
            blockHeader.blockHash = BlockHeaderUtils.calculateBlockHash(blockHeader);
            blockHeader.blockNumber = initialBlockHeight + i;

            blockHeaders[i] = blockHeader;
        }

        nextBlockIndex = 0;
        currentBlockHeight = initialBlockHeight + NUM_OF_BLOCK_HEADERS - 1;
        config = IDoefinConfig(_config);
    }

    /// @inheritdoc IDoefinBlockHeaderOracle
    function submitNextBlock(BlockHeader calldata _newBlockHeader) external {
        BlockHeader memory newBlockHeader = _newBlockHeader;
        newBlockHeader.blockHash = BlockHeaderUtils.calculateBlockHash(newBlockHeader);
        newBlockHeader.blockNumber = ++currentBlockHeight;

        BlockHeader memory currentBlockHeader = getLatestBlockHeader();
        _verifyBlockHeader(currentBlockHeader, newBlockHeader);

        blockHeaders[nextBlockIndex] = newBlockHeader;
        nextBlockIndex = (nextBlockIndex + 1) % NUM_OF_BLOCK_HEADERS;

        emit BlockSubmitted(newBlockHeader.blockHash, newBlockHeader.timestamp);

        _settleOrder();
    }

    /// @inheritdoc IDoefinBlockHeaderOracle
    function submitBatchBlocks(BlockHeader[] calldata newBlockHeaders) external {
        BlockHeader memory latestBlockHeaderInBatch = newBlockHeaders[newBlockHeaders.length - 1];
        uint256 forkHeight = _findForkPoint(newBlockHeaders[0]);

        if (forkHeight + newBlockHeaders.length <= currentBlockHeight) {
            revert Errors.BlockHeaderOracle_NewChainNotLonger();
        }

        if (forkHeight < currentBlockHeight) {
            emit BlockReorged(latestBlockHeaderInBatch.merkleRootHash);
        }

        BlockHeader memory prevBlockHeader = forkHeight == currentBlockHeight
            ? getLatestBlockHeader()
            : blockHeaders[(nextBlockIndex + forkHeight - currentBlockHeight - 1) % NUM_OF_BLOCK_HEADERS];

        nextBlockIndex = (nextBlockIndex + forkHeight - currentBlockHeight) % NUM_OF_BLOCK_HEADERS;
        currentBlockHeight = forkHeight;

        _applyChain(prevBlockHeader, newBlockHeaders);
    }

    /// @inheritdoc IDoefinBlockHeaderOracle
    function medianBlockTime() public view returns (uint256) {
        uint256[NUM_OF_TIMESTAMPS] memory timestamps;
        uint256 startIndex = (nextBlockIndex + NUM_OF_BLOCK_HEADERS - 1) % NUM_OF_BLOCK_HEADERS;

        for (uint256 i = 0; i < NUM_OF_TIMESTAMPS; ++i) {
            uint256 j = (startIndex + NUM_OF_BLOCK_HEADERS - i) % NUM_OF_BLOCK_HEADERS;
            timestamps[i] = blockHeaders[j].timestamp;
        }

        return BlockHeaderUtils.median(timestamps);
    }

    /// @inheritdoc IDoefinBlockHeaderOracle
    function getLatestBlockHeader() public view returns (BlockHeader memory) {
        uint256 currentBlockIndex = ((nextBlockIndex + NUM_OF_BLOCK_HEADERS) - 1) % NUM_OF_BLOCK_HEADERS;
        return blockHeaders[currentBlockIndex];
    }

    /**
     * @dev Settle orders in the order book for every new bloc number
     */
    function _settleOrder() internal {
        address orderBook = config.getOrderBook();
        if (orderBook == address(0)) {
            revert Errors.ZeroAddress();
        }

        uint256 settlementIndex = (nextBlockIndex + NUM_OF_BLOCK_HEADERS - SETTLEMENT_DELAY - 1) % NUM_OF_BLOCK_HEADERS;
        BlockHeader memory settlementBlock = blockHeaders[settlementIndex];

        IDoefinV1OrderBook(orderBook).settleOrder(
            settlementBlock.blockNumber,
            settlementBlock.timestamp,
            BlockHeaderUtils.calculateDifficultyTarget(settlementBlock)
        );
    }

    /**
     * @dev Apply a series of new block headers to the chain
     * @param newBlockHeaders The block headers to apply
     */
    function _applyChain(BlockHeader memory prevBlockHeader, BlockHeader[] memory newBlockHeaders) internal {
        for (uint256 i = 0; i < newBlockHeaders.length; i++) {
            BlockHeader memory newBlockHeader = newBlockHeaders[i];
            newBlockHeader.blockHash = BlockHeaderUtils.calculateBlockHash(newBlockHeader);
            newBlockHeader.blockNumber = ++currentBlockHeight;

            _verifyBlockHeader(prevBlockHeader, newBlockHeader);
            prevBlockHeader = newBlockHeader;

            blockHeaders[nextBlockIndex] = newBlockHeader;
            nextBlockIndex = (nextBlockIndex + 1) % NUM_OF_BLOCK_HEADERS;

            emit BlockSubmitted(newBlockHeader.blockHash, newBlockHeader.timestamp);
            _settleOrder();
        }
    }

    /**
     * @dev Find the fork point where the new chain diverges from the current chain
     * @param newBlockHeader The first header of the new chain
     * @return The height of the fork point
     */
    function _findForkPoint(BlockHeader calldata newBlockHeader) internal view returns (uint256) {
        for (uint256 i = 0; i < NUM_OF_BLOCK_HEADERS; i++) {
            uint256 index = (nextBlockIndex + NUM_OF_BLOCK_HEADERS - i - 1) % NUM_OF_BLOCK_HEADERS;
            if (blockHeaders[index].blockHash == newBlockHeader.prevBlockHash) {
                return currentBlockHeight - i;
            }
        }

        revert Errors.BlockHeaderOracle_CannotFindForkPoint();
    }

    /// @notice Verifies a single block header against consensus rules
    /// @param prevBlockHeader The previous block header
    /// @param newBlockHeader The new block header to verify
    function _verifyBlockHeader(BlockHeader memory prevBlockHeader, BlockHeader memory newBlockHeader) internal view {
        if (newBlockHeader.prevBlockHash != prevBlockHeader.blockHash) {
            revert Errors.BlockHeaderOracle_PrevBlockHashMismatch();
        }

        if (newBlockHeader.timestamp < medianBlockTime()) {
            revert Errors.BlockHeaderOracle_InvalidTimestamp();
        }

        if (!BlockHeaderUtils.isValidBlockHeaderHash(prevBlockHeader, newBlockHeader)) {
            revert Errors.BlockHeaderOracle_InvalidBlockHash();
        }
    }
}
