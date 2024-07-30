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
        Base_Test.deployConfig();

        blockHeaderOracle = new DoefinV1BlockHeaderOracle(setupInitialBlocks(), 838_886);
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
        IDoefinBlockHeaderOracle.BlockHeader memory blockHeader = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2de60000,
            prevBlockHash: 0x00000000000000000001a66adbcce19ffa90fb72f37115e43b407ea49b4a2dbf,
            merkleRootHash: 0xbb94b9f29d86433922fce640b9e95605dd29661978a9040e739ff47553595d3b,
            timestamp: 1_712_940_028,
            nBits: 0x17034219,
            nonce: 1_539_690_831
        });

        blockHeaderOracle.submitNextBlock(blockHeader);
    }
}
