// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Base_Test } from "./Base.t.sol";
import { Test } from "forge-std/Test.sol";
import { DoefinV1BlockHeaderOracle } from "../src/DoefinV1BlockHeaderOracle.sol";

/// @title DoefinV1BlockHeaderOracle_Test
contract DoefinV1BlockHeaderOracle_Test is Base_Test {
    DoefinV1BlockHeaderOracle public blockHeaderOracle;

    function setUp() public virtual override {
        Base_Test.setUp();
        Base_Test.deployFactory();

        //        blockHeaderOracle = new DoefinV1BlockHeaderOracle();
    }

    function testAddTimestamp() public {
        // Add some timestamps
        //        blockHeaderOracle.addTimestamp(10);
        //        blockHeaderOracle.addTimestamp(20);
        //        blockHeaderOracle.addTimestamp(30);
        //        blockHeaderOracle.addTimestamp(40);
        //        blockHeaderOracle.addTimestamp(50);
        //        blockHeaderOracle.addTimestamp(60);
        //        blockHeaderOracle.addTimestamp(70);
        //        blockHeaderOracle.addTimestamp(80);
        //        blockHeaderOracle.addTimestamp(90);
        //        blockHeaderOracle.addTimestamp(100);
        //        blockHeaderOracle.addTimestamp(110);
        //
        //        // Test median calculation
        //        uint256 median = blockHeaderOracle.blockHeaderOracle();
        //        assertEq(median, 60, "Median should be 60");
        //
        //        // Add one more timestamp and check if the oldest is removed
        //        blockHeaderOracle.addTimestamp(120);
        //        median = blockHeaderOracle.blockHeaderOracle();
        //        assertEq(median, 70, "Median should be 70 after adding 120");
    }

    function testMedianBeforeBufferFull() public {
        // Add fewer than 11 timestamps
        //        blockHeaderOracle.addTimestamp(10);
        //        blockHeaderOracle.addTimestamp(20);
        //
        //        // Test median calculation should fail
        //        (bool success,) = address(blockHeaderOracle).call(abi.encodeWithSignature("blockHeaderOracle()"));
        //        assertTrue(!success, "Median calculation should fail before buffer is full");
    }
}
