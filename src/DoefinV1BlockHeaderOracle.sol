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

    /// @notice The total number of timestamps to be stored
    uint256 public constant NUM_OF_TIMESTAMPS = 11;

    /// @notice The total number of initial blocks headers to be stored
    uint256 public constant NUM_OF_BLOCK_HEADERS = 17;

    /// @notice Ring buffer to store the block headers
    BlockHeader[NUM_OF_BLOCK_HEADERS] public blockHeaders;

    /// @notice The canonical chain tip
    ChainTip public canonicalChainTip;

    /// @notice Stores cumulative difficulty for each block to compare chains
    mapping(bytes32 => uint256) public cumulativeDifficulty;

    constructor(
        IDoefinBlockHeaderOracle.BlockHeader[NUM_OF_BLOCK_HEADERS] memory initialBlockHistory,
        uint256 initialBlockHeight,
        address _config
    ) {
        for (uint256 i = 0; i < NUM_OF_BLOCK_HEADERS; ++i) {
            blockHeaders[i] = initialBlockHistory[i];
        }

        nextBlockIndex = 0;
        currentBlockHeight = initialBlockHeight;
        config = IDoefinConfig(_config);

        bytes32 initialTipHash = BlockHeaderUtils.calculateBlockHash(initialBlockHistory[NUM_OF_BLOCK_HEADERS - 1]);
        canonicalChainTip = ChainTip({ tipHash: initialTipHash, blockHeight: initialBlockHeight });
        cumulativeDifficulty[initialTipHash] =
            BlockHeaderUtils.calculateDifficultyTarget(initialBlockHistory[NUM_OF_BLOCK_HEADERS - 1]);
    }

    /// @inheritdoc IDoefinBlockHeaderOracle
    function submitNextBlock(BlockHeader calldata newBlockHeader) external {
        BlockHeader memory currentBlockHeader = getLatestBlockHeader();
        if (newBlockHeader.prevBlockHash != BlockHeaderUtils.calculateBlockHash(currentBlockHeader)) {
            revert Errors.BlockHeaderOracle_PrevBlockHashMismatch();
        }

        if (newBlockHeader.timestamp < medianBlockTime()) {
            revert Errors.BlockHeaderOracle_InvalidTimestamp();
        }

        if (!BlockHeaderUtils.isValidBlockHeaderHash(currentBlockHeader, newBlockHeader)) {
            revert Errors.BlockHeaderOracle_InvalidBlockHash();
        }

        blockHeaders[nextBlockIndex] = newBlockHeader;
        nextBlockIndex = (nextBlockIndex + 1) % NUM_OF_BLOCK_HEADERS;
        ++currentBlockHeight;

        _settleOrder(
            currentBlockHeight, newBlockHeader.timestamp, BlockHeaderUtils.calculateDifficultyTarget(newBlockHeader)
        );

        bytes32 newBlockHash = BlockHeaderUtils.calculateBlockHash(newBlockHeader);
        _updateCumulativeDifficulty(
            newBlockHash, newBlockHeader.prevBlockHash, BlockHeaderUtils.calculateDifficultyTarget(newBlockHeader)
        );
        canonicalChainTip = ChainTip({ tipHash: newBlockHash, blockHeight: currentBlockHeight });

        emit BlockSubmitted(newBlockHeader.merkleRootHash, newBlockHeader.timestamp);
    }

    /// @inheritdoc IDoefinBlockHeaderOracle
    function updateCanonicalChain(BlockHeader[] calldata newBlockHeaders) external {
        BlockHeader memory latestBlockHeader = newBlockHeaders[newBlockHeaders.length - 1];
        uint256 forkHeight = _findForkPoint(newBlockHeaders[0]);

        uint256 currentCumulativeDifficulty = cumulativeDifficulty[canonicalChainTip.tipHash];
        uint256 newCumulativeDifficulty = _calculateCumulativeDifficulty(newBlockHeaders);
        if (newCumulativeDifficulty <= currentCumulativeDifficulty) {
            revert Errors.BlockHeaderOracle_NewChainNotLonger();
        }

        _revertChain(forkHeight);
        _applyChain(newBlockHeaders);
        canonicalChainTip = ChainTip({
            tipHash: BlockHeaderUtils.calculateBlockHash(latestBlockHeader),
            blockHeight: currentBlockHeight
        });

        emit BlockReorged(latestBlockHeader.merkleRootHash);
    }

    /// @inheritdoc IDoefinBlockHeaderOracle
    function medianBlockTime() public view returns (uint256) {
        uint256[NUM_OF_TIMESTAMPS] memory timestamps;

        for (uint256 i = 0; i < NUM_OF_TIMESTAMPS; ++i) {
            uint256 j = (nextBlockIndex + 6) % NUM_OF_BLOCK_HEADERS;
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
     * @param blockNumber The latest block number to be submitted
     * @param timestamp The timestamp of the new bloc header
     * @param difficulty The difficulty of the
     */
    function _settleOrder(uint256 blockNumber, uint256 timestamp, uint256 difficulty) internal {
        address orderBook = config.getOrderBook();
        if (orderBook == address(0)) {
            revert Errors.ZeroAddress();
        }
        IDoefinV1OrderBook(orderBook).settleOrder(blockNumber, timestamp, difficulty);
    }

    /**
     * @dev Revert the chain back to a certain height
     * @param forkHeight The height to revert to
     */
    function _revertChain(uint256 forkHeight) internal {
        while (currentBlockHeight > forkHeight) {
            nextBlockIndex = (nextBlockIndex + NUM_OF_BLOCK_HEADERS - 1) % NUM_OF_BLOCK_HEADERS;
            blockHeaders[nextBlockIndex] = BlockHeader(0, 0, 0, 0, 0, 0);
            --currentBlockHeight;
        }
    }

    /**
     * @dev Apply a series of new block headers to the chain
     * @param newBlockHeaders The block headers to apply
     */
    function _applyChain(BlockHeader[] memory newBlockHeaders) internal {
        for (uint256 i = 0; i < newBlockHeaders.length; i++) {
            blockHeaders[nextBlockIndex] = newBlockHeaders[i];
            nextBlockIndex = (nextBlockIndex + 1) % NUM_OF_BLOCK_HEADERS;
            ++currentBlockHeight;

            // Update cumulative difficulty for each block
            _updateCumulativeDifficulty(
                BlockHeaderUtils.calculateBlockHash(newBlockHeaders[i]),
                newBlockHeaders[i].prevBlockHash,
                BlockHeaderUtils.calculateDifficultyTarget(newBlockHeaders[i])
            );
        }
    }

    /**
     * @dev Calculate the cumulative difficulty for a series of block headers
     * @param newBlockHeaders The headers of the new chain
     * @return _cumulativeDifficulty The total cumulative difficulty for the chain
     */
    function _calculateCumulativeDifficulty(BlockHeader[] memory newBlockHeaders)
        internal
        view
        returns (uint256 _cumulativeDifficulty)
    {
        _cumulativeDifficulty = cumulativeDifficulty[newBlockHeaders[0].prevBlockHash];
        for (uint256 i = 0; i < newBlockHeaders.length; i++) {
            _cumulativeDifficulty += BlockHeaderUtils.calculateDifficultyTarget(newBlockHeaders[i]);
        }
    }

    /**
     * @dev Update cumulative difficulty for a block hash based on its parent
     * @param blockHash The hash of the new block
     * @param prevBlockHash The hash of the previous block (parent)
     * @param difficulty The difficulty of the new block
     */
    function _updateCumulativeDifficulty(bytes32 blockHash, bytes32 prevBlockHash, uint256 difficulty) internal {
        cumulativeDifficulty[blockHash] = cumulativeDifficulty[prevBlockHash] + difficulty;
    }

    /**
     * @dev Find the fork point where the new chain diverges from the current chain
     * @param newBlockHeader The first header of the new chain
     * @return The height of the fork point
     */
    function _findForkPoint(BlockHeader calldata newBlockHeader) internal view returns (uint256) {
        for (uint256 i = 0; i < NUM_OF_BLOCK_HEADERS; i++) {
            uint256 index = (nextBlockIndex + NUM_OF_BLOCK_HEADERS - i - 1) % NUM_OF_BLOCK_HEADERS;
            bytes32 blockHash = BlockHeaderUtils.calculateBlockHash(blockHeaders[index]);
            if (blockHash == newBlockHeader.prevBlockHash) {
                return currentBlockHeight - i;
            }
        }
        revert Errors.BlockHeaderOracle_CannotFindForkPoint();
    }
}
