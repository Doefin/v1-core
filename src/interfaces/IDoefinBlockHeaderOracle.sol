// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

/**
 * @title IDoefinBlockHeaderOracle
 * @dev Interface for the block header oracle
 */
interface IDoefinBlockHeaderOracle {
    /**
     * @dev Struct to store essential details of a block header
     * @param version The block version number. Indicates which set of block validation rules to follow. Miners
     * increment this number and also use it in combination with the nonce when searching for a valid block hash.
     * @param prevBlockHash A 256-bit hash of the previous block’s header. Ensures that blocks are ordered
     * chronologically and establishes the link between blocks in the blockchain.
     * @param merkleRootHash A 256-bit hash derived from the transactions in the block. Provides a single hash that
     * summarizes all transactions in the block, enabling efficient and secure verification of the block’s contents.
     * @param timestamp The approximate creation time of the block, represented as Unix time (seconds since
     * 1970-01-01T00:00 UTC). Provides a temporal ordering of blocks and helps in the difficulty adjustment process.
     * @param nBits Encoded current target threshold for the proof-of-work algorithm. Represents the difficulty target
     * that a block’s hash must meet. It is periodically adjusted to maintain the block creation rate.
     * @param nonce A 32-bit arbitrary number that miners adjust to find a hash below the target threshold. Used by
     * miners in the proof-of-work algorithm. Miners increment the nonce to generate different hashes and find a valid
     * one that meets the difficulty target.
     */
    struct BlockHeader {
        uint32 version;
        bytes32 prevBlockHash;
        bytes32 merkleRootHash;
        uint32 timestamp;
        uint32 nBits;
        uint32 nonce;
        bytes32 blockHash;
        uint256 blockNumber;
    }

    // Events
    event BlockReorged(bytes32 merkleRootHash);
    event BlockSubmitted(bytes32 blockHash, uint32 timestamp);

    // Interface methods
    /**
     * @notice Allows anyone to submit a confirmed block header
     * @dev Add block header to ring buffer, and the block timestamp to the sorted list
     * @param newBlockHeader The newest block header to the added to the head of the ring buffer
     */
    function submitNextBlock(BlockHeader calldata newBlockHeader) external;

    /**
     * @notice Allows anyone to submit a block header to update the canonical chain
     * @param newBlockHeaders The list of new block headers to be added to the canonical chain
     */
    function submitBatchBlocks(BlockHeader[] calldata newBlockHeaders) external;

    /**
     * @notice Get the median timestamp from the sorted timestamp list
     * @return the median block timestamp
     */
    function medianBlockTime() external view returns (uint256);

    /**
     * @notice Get the latest block header
     * @return the latest block header
     */
    function getLatestBlockHeader() external view returns (BlockHeader memory);
}
