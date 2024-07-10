// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;
import { Base_Test } from "./Base.t.sol";
import { Test } from "forge-std/Test.sol";
import { DoefinV1BlockHeaderOracle, IDoefinBlockHeaderOracle, Errors } from "../src/DoefinV1BlockHeaderOracle.sol";

/// @title DoefinV1BlockHeaderOracle_Test
contract DoefinV1BlockHeaderOracle_Test is Base_Test {
    DoefinV1BlockHeaderOracle public blockHeaderOracle;

    function setUp() public virtual override {
        Base_Test.setUp();
        Base_Test.deployFactory();

        blockHeaderOracle = new DoefinV1BlockHeaderOracle(setupInitialBlocks());
    }

    function test_FailWithInvalidPrevBlockHash() public {
        IDoefinBlockHeaderOracle.BlockHeader memory invalidBlockHeader = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2de60000,
            prevBlockHash: 0x00000000000000000001a66adbcce19ffa90fb72f37115e43b407ea49b4a2dbf,
            merkleRootHash: 0xbb94b9f29d86433922fce640b9e95605dd29661978a9040e739ff47553595d3b,
            timestamp: 1712940028,
            nBits: 0x17034219,
            nonce: 1539690831
        });

        vm.expectRevert(abi.encodeWithSelector(Errors.BlockHeaderOracle_PrevBlockHashMismatch.selector));
        blockHeaderOracle.submitNextBlock(invalidBlockHeader);
    }

    function test_FailWithInvalidTimestamp() public {
        IDoefinBlockHeaderOracle.BlockHeader memory blockHeader = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x21e02000,
            prevBlockHash: 0x000000000000000000002e334d605c87463e3e063b733f1ab39b3ce33146e87c,
            merkleRootHash: 0x0c0d616463b1b888ff49c72b65d46a6ba6ee0c9d2c7b0b8d75d64a9364f7c85f,
            timestamp: 1712940014,
            nBits: 0x17034219,
            nonce: 305767976
        });
        uint256 medianTimestamp = blockHeaderOracle.medianBlockTime();
        blockHeader.timestamp = uint32(medianTimestamp / 2);
        vm.expectRevert(abi.encodeWithSelector(Errors.BlockHeaderOracle_InvalidTimestamp.selector));
        blockHeaderOracle.submitNextBlock(blockHeader);
    }

    function test_FailWithInvalidBlockHeaderHash() public {
        IDoefinBlockHeaderOracle.BlockHeader memory blockHeader = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x21e02000,
            prevBlockHash: 0x000000000000000000002e334d605c87463e3e063b733f1ab39b3ce33146e87c,
            merkleRootHash: 0x0c0d616463b1b888ff49c72b65d46a6ba6ee0c9d2c7b0b8d75d64a9364f7c85f,
            timestamp: 1712940014,
            nBits: 0x17034219,
            nonce: 305767977
        });
        uint256 medianTimestamp = blockHeaderOracle.medianBlockTime();
        vm.expectRevert(abi.encodeWithSelector(Errors.BlockHeaderOracle_InvalidBlockHash.selector));
        blockHeaderOracle.submitNextBlock(blockHeader);
    }

    function test__submitNextBlock() public {
        IDoefinBlockHeaderOracle.BlockHeader memory blockHeader = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x21e02000,
            prevBlockHash: 0x000000000000000000002e334d605c87463e3e063b733f1ab39b3ce33146e87c,
            merkleRootHash: 0x0c0d616463b1b888ff49c72b65d46a6ba6ee0c9d2c7b0b8d75d64a9364f7c85f,
            timestamp: 1712940014,
            nBits: 0x17034219,
            nonce: 305767976
        });

        blockHeaderOracle.submitNextBlock(blockHeader);
    }

}
