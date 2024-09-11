// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;
import "forge-std/Console.sol";

import { Base_Test } from "./Base.t.sol";
import { Test } from "forge-std/Test.sol";
import { Errors, DoefinV1OrderBook, IDoefinV1OrderBook } from "../src/DoefinV1OrderBook.sol";
import {
    DoefinV1BlockHeaderOracle,
    IDoefinBlockHeaderOracle,
    Errors,
    BlockHeaderUtils
} from "../src/DoefinV1BlockHeaderOracle.sol";

/// @title DoefinV1BlockHeaderOracle_Test
contract DoefinV1BlockHeaderOracle_Test is Base_Test {
    DoefinV1OrderBook public orderBook;
    DoefinV1BlockHeaderOracle public blockHeaderOracle;

    address public collateralToken;
    uint256 public constant depositBound = 5000e6;
    uint256 public constant minCollateralAmount = 100;

    function setUp() public virtual override {
        Base_Test.setUp();
        Base_Test.deployConfig();

        collateralToken = address(dai);
        config.setFeeAddress(users.feeAddress);

        blockHeaderOracle = new DoefinV1BlockHeaderOracle(setupInitialBlocks(), 838_886, address(config));
        config.setBlockHeaderOracle(address(blockHeaderOracle));

        orderBook = new DoefinV1OrderBook(address(config));
        config.setOrderBook(address(orderBook));
    }

    function test_FailWithInvalidPrevBlockHash() public {
        IDoefinBlockHeaderOracle.BlockHeader memory invalidBlockHeader = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2a000000,
            prevBlockHash: 0x00000000000000000000057f8a11b249b7d174bf2bc5595a84ba20f9285decf6,
            merkleRootHash: 0xe2ac709ad52a66c2109c75924f82e55491f67f72642eb8eab0c8c189a7bed28b,
            timestamp: 1_712_940_152,
            nBits: 0x17034219,
            nonce: 3_138_544_259
        });

        vm.expectRevert(abi.encodeWithSelector(Errors.BlockHeaderOracle_PrevBlockHashMismatch.selector));
        blockHeaderOracle.submitNextBlock(invalidBlockHeader);
    }

    function test_FailWithInvalidTimestamp() public {
        IDoefinBlockHeaderOracle.BlockHeader memory blockHeader = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2de60000,
            prevBlockHash: 0x00000000000000000001a66adbcce19ffa90fb72f37115e43b407ea49b4a2dbf,
            merkleRootHash: 0xbb94b9f29d86433922fce640b9e95605dd29661978a9040e739ff47553595d3b,
            timestamp: 1_712_940_028,
            nBits: 0x17034219,
            nonce: 1_539_690_831
        });
        uint256 medianTimestamp = blockHeaderOracle.medianBlockTime();
        blockHeader.timestamp = uint32(medianTimestamp / 2);
        vm.expectRevert(abi.encodeWithSelector(Errors.BlockHeaderOracle_InvalidTimestamp.selector));

        blockHeaderOracle.submitNextBlock(blockHeader);
    }

    function test_FailWithInvalidBlockHeaderHash() public {
        IDoefinBlockHeaderOracle.BlockHeader memory blockHeader = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2de60000,
            prevBlockHash: 0x00000000000000000001a66adbcce19ffa90fb72f37115e43b407ea49b4a2dbf,
            merkleRootHash: 0xbb94b9f29d86433922fce640b9e95605dd29661978a9040e739ff47553595d3b,
            timestamp: 1_712_940_028,
            nBits: 0x17034219,
            nonce: 1_539_690_832
        });
        uint256 medianTimestamp = blockHeaderOracle.medianBlockTime();
        vm.expectRevert(abi.encodeWithSelector(Errors.BlockHeaderOracle_InvalidBlockHash.selector));

        blockHeaderOracle.submitNextBlock(blockHeader);
    }

    function test__submitNextBlock() public {
        IDoefinBlockHeaderOracle.BlockHeader memory blockHeader = getNextBlocks()[0];
        bytes32 blockHash = BlockHeaderUtils.calculateBlockHash(blockHeader);

        vm.expectEmit();
        emit IDoefinBlockHeaderOracle.BlockSubmitted(blockHash, blockHeader.timestamp);
        blockHeaderOracle.submitNextBlock(blockHeader);
    }

    function test__settleOrderByBlockNumberAfterSubmittingNextBlock(
        uint256 strike,
        uint256 premium,
        uint256 expiry,
        address counterparty
    )
        public
    {
        uint256 expiry = blockHeaderOracle.currentBlockHeight() + 1;
        console.log("expiry block number: ", expiry);
        vm.assume(strike != 0);
        vm.assume(premium >= minCollateralAmount && premium <= depositBound);
        vm.assume(counterparty == users.broker || counterparty == users.rick || counterparty == users.james);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](3);
        allowed[0] = users.broker;
        allowed[1] = users.rick;
        allowed[2] = users.james;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Put,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        uint256 orderId = orderBook.createOrder(createOrderInput);
        vm.stopBroadcast();

        vm.startBroadcast(counterparty);
        dai.approve(address(orderBook), premium);
        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

//        IDoefinBlockHeaderOracle.BlockHeader memory blockHeader = getNextBlocks()[0];
//        blockHeaderOracle.submitNextBlock(blockHeader);

        // Submit 6 blocks (settlement should not occur yet)
        IDoefinBlockHeaderOracle.BlockHeader[18] memory nextBlocks = getNextBlocks();
        for (uint256 i = 0; i < 6; i++) {
            blockHeaderOracle.submitNextBlock(nextBlocks[i]);
        }

        // Submit the 7th block (settlement should occur)
        blockHeaderOracle.submitNextBlock(nextBlocks[6]);

        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        assertEq(uint256(order.metadata.status), uint256(IDoefinV1OrderBook.Status.Settled));
//        assertEq(order.metadata.finalStrike, BlockHeaderUtils.calculateDifficultyTarget(blockHeader));
    }

//    function test__settleOrderByTimestampAfterSubmittingNextBlock(
//        uint256 strike,
//        uint256 premium,
//        uint256 expiry,
//        address counterparty
//    )
//        public
//    {
//        IDoefinBlockHeaderOracle.BlockHeader memory blockHeader = getNextBlocks()[1];
//
//        uint256 expiry = blockHeader.timestamp;
//        vm.assume(strike != 0);
//        vm.assume(premium >= minCollateralAmount && premium <= depositBound);
//        vm.assume(counterparty == users.broker || counterparty == users.rick || counterparty == users.james);
//
//        uint256 notional = premium + ((30 * premium) / 100);
//        address[] memory allowed = new address[](3);
//        allowed[0] = users.broker;
//        allowed[1] = users.rick;
//        allowed[2] = users.james;
//
//        vm.startBroadcast(users.alice);
//        dai.approve(address(orderBook), premium);
//
//        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
//            strike: strike,
//            premium: premium,
//            notional: notional,
//            expiry: expiry,
//            expiryType: IDoefinV1OrderBook.ExpiryType.Timestamp,
//            position: IDoefinV1OrderBook.Position.Put,
//            collateralToken: collateralToken,
//            deadline: 1 days,
//            allowed: allowed
//        });
//
//        uint256 orderId = orderBook.createOrder(createOrderInput);
//        vm.stopBroadcast();
//
//        vm.startBroadcast(counterparty);
//        dai.approve(address(orderBook), premium);
//        orderBook.matchOrder(orderId);
//        vm.stopBroadcast();
//
//        blockHeaderOracle.submitNextBlock(getNextBlocks()[0]);
//        blockHeaderOracle.submitNextBlock(blockHeader);
//
//        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
//        assertEq(uint256(order.metadata.status), uint256(IDoefinV1OrderBook.Status.Settled));
//        assertEq(order.metadata.finalStrike, BlockHeaderUtils.calculateDifficultyTarget(blockHeader));
//    }

    function test_SubmitBatchBlocks() public {
        uint256 initialBlockHeight = blockHeaderOracle.currentBlockHeight();
        IDoefinBlockHeaderOracle.BlockHeader[] memory batchBlocks = new IDoefinBlockHeaderOracle.BlockHeader[](5);
        for (uint256 i = 0; i < 5; i++) {
            batchBlocks[i] = getNextBlocks()[i];
        }

        vm.expectEmit(true, true, true, true);
        emit IDoefinBlockHeaderOracle.BlockBatchSubmitted(
            batchBlocks[0].merkleRootHash, batchBlocks[4].merkleRootHash, 5
        );

        blockHeaderOracle.submitBatchBlocks(batchBlocks);

        assertEq(blockHeaderOracle.currentBlockHeight(), initialBlockHeight + 5);
        assertEq(blockHeaderOracle.getLatestBlockHeader().merkleRootHash, batchBlocks[4].merkleRootHash);
    }

    function test_SubmitBatchBlocks_Reorg() public {
        // First, submit some initial blocks
        for (uint256 i = 0; i < 5; i++) {
            blockHeaderOracle.submitNextBlock(getNextBlocks()[i]);
        }

        uint256 initialBlockHeight = blockHeaderOracle.currentBlockHeight();

        // Create a new chain that forks from the third block (index 2)
        IDoefinBlockHeaderOracle.BlockHeader[] memory reorgBlocks = new IDoefinBlockHeaderOracle.BlockHeader[](4);
        reorgBlocks[0] = getNextBlocks()[2];
        reorgBlocks[1] = getNextBlocks()[3];
        reorgBlocks[2] = getNextBlocks()[4];
        reorgBlocks[3] = getNextBlocks()[5];

        // Expect a reorg event
        vm.expectEmit(true, true, true, true);
        emit IDoefinBlockHeaderOracle.BlockReorged(reorgBlocks[3].merkleRootHash);

        blockHeaderOracle.submitBatchBlocks(reorgBlocks);

        // Verify the new state
        assertEq(blockHeaderOracle.currentBlockHeight(), initialBlockHeight + 1);
        assertEq(blockHeaderOracle.getLatestBlockHeader().merkleRootHash, reorgBlocks[3].merkleRootHash);
    }

    function test_SubmitBatchBlocks_FailNewChainNotLonger() public {
        for (uint256 i = 0; i < 5; i++) {
            blockHeaderOracle.submitNextBlock(getNextBlocks()[i]);
        }

        // Create a new chain that forks from the 3rd block but is not longer
        IDoefinBlockHeaderOracle.BlockHeader[] memory newChain = new IDoefinBlockHeaderOracle.BlockHeader[](3);
        newChain[0] = getNextBlocks()[2]; // Fork point
        newChain[1] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20000000,
            prevBlockHash: BlockHeaderUtils.calculateBlockHash(newChain[0]),
            merkleRootHash: bytes32(uint256(1)),
            timestamp: getNextBlocks()[2].timestamp + 600,
            nBits: 0x1701ffff,
            nonce: 0
        });
        newChain[2] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20000000,
            prevBlockHash: BlockHeaderUtils.calculateBlockHash(newChain[1]),
            merkleRootHash: bytes32(uint256(2)),
            timestamp: getNextBlocks()[2].timestamp + 1200,
            nBits: 0x1701ffff,
            nonce: 0
        });

        vm.expectRevert(abi.encodeWithSelector(Errors.BlockHeaderOracle_NewChainNotLonger.selector));
        blockHeaderOracle.submitBatchBlocks(newChain);
    }

    function test_SubmitBatchBlocks_FailCannotFindForkPoint() public {
        for (uint256 i = 0; i < 5; i++) {
            blockHeaderOracle.submitNextBlock(getNextBlocks()[i]);
        }

        // Create a new chain that doesn't fork from any known point
        IDoefinBlockHeaderOracle.BlockHeader[] memory newChain = new IDoefinBlockHeaderOracle.BlockHeader[](3);
        newChain[0] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20000000,
            prevBlockHash: bytes32(uint256(123_456)),
            merkleRootHash: bytes32(uint256(1)),
            timestamp: uint32(block.timestamp),
            nBits: 0x1703ffff,
            nonce: 0
        });
        newChain[1] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20000000,
            prevBlockHash: BlockHeaderUtils.calculateBlockHash(newChain[0]),
            merkleRootHash: bytes32(uint256(2)),
            timestamp: uint32(block.timestamp) + 600,
            nBits: 0x1703ffff,
            nonce: 0
        });
        newChain[2] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20000000,
            prevBlockHash: BlockHeaderUtils.calculateBlockHash(newChain[1]),
            merkleRootHash: bytes32(uint256(3)),
            timestamp: uint32(block.timestamp) + 1200,
            nBits: 0x1703ffff,
            nonce: 0
        });

        vm.expectRevert(abi.encodeWithSelector(Errors.BlockHeaderOracle_CannotFindForkPoint.selector));
        blockHeaderOracle.submitBatchBlocks(newChain);
    }

    function test_InitialMedianBlockTime() public {
        uint256 medianTime = blockHeaderOracle.medianBlockTime();

        // The median should be the 6th timestamp (index 5) in the last 11 blocks
        uint256 expectedMedian = initialBlockHeaders[11].timestamp;
        assertEq(medianTime, expectedMedian);
    }

    function test_MedianBlockTimeAfterNewBlocks() public {
        IDoefinBlockHeaderOracle.BlockHeader[18] memory nextBlocks = getNextBlocks();

        // Submit 5 new blocks
        for (uint256 i = 0; i < 5; i++) {
            blockHeaderOracle.submitNextBlock(nextBlocks[i]);
        }

        uint256 medianTime = blockHeaderOracle.medianBlockTime();

        // The median should now be the 6th timestamp in the last 11 blocks
        uint256 expectedMedian = initialBlockHeaders[16].timestamp;
        assertEq(medianTime, expectedMedian);
    }
}
