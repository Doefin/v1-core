// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { DoefinV1Config } from "../src/DoefinV1Config.sol";
import { DoefinV1BlockHeaderOracle } from "../src/DoefinV1BlockHeaderOracle.sol";
import { IDoefinBlockHeaderOracle } from "../src/interfaces/IDoefinBlockHeaderOracle.sol";

/// @dev Reverts if any contract has already been deployed.
contract DeployBlockHeaderOracle is BaseScript {
    uint256 public initialBlockHeight;

    function run(address configAddress) public virtual returns (DoefinV1BlockHeaderOracle blockHeaderOracle) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        initialBlockHeight = 864_536;

        blockHeaderOracle = new DoefinV1BlockHeaderOracle(setupInitialBlocks(), initialBlockHeight, configAddress);
        DoefinV1Config(configAddress).setBlockHeaderOracle(address(blockHeaderOracle));

        vm.stopBroadcast();
    }

    function setupInitialBlocks() internal returns (IDoefinBlockHeaderOracle.BlockHeader[17] memory blockHeaders) {
        blockHeaders[0] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x24496000,
            prevBlockHash: 0x0000000000000000000191c9ba0172d5dc92b793038062b4482ca56601da1b15,
            merkleRootHash: 0x573a30f9fef04fde717a57addd5d14da64bb4621df75a9ce41bae134859ea74a,
            timestamp: 1_728_271_417,
            nBits: 386_084_628,
            nonce: 758_774_834,
            blockHash: 0x000000000000000000029004e05aa88800f664e31be3305233cbcbe873bc05b8,
            blockNumber: 864_536
        });
        blockHeaders[1] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x30000000,
            prevBlockHash: 0x000000000000000000029004e05aa88800f664e31be3305233cbcbe873bc05b8,
            merkleRootHash: 0xa15532dea786b75a0f119ac5089991d92d7df5ad56471c9077ebfdfa8d035487,
            timestamp: 1_728_271_414,
            nBits: 386_084_628,
            nonce: 856_830_594,
            blockHash: 0x00000000000000000000f24c82b2696cef5adcc20d1cc16f42e4e81c016b4ce2,
            blockNumber: 864_537
        });
        blockHeaders[2] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x3e4a8000,
            prevBlockHash: 0x00000000000000000000f24c82b2696cef5adcc20d1cc16f42e4e81c016b4ce2,
            merkleRootHash: 0x777d8ea101f4c9d2d4b928eeb3869ba40d7f7ce9aa2c60cfe62f212339e3bef3,
            timestamp: 1_728_271_474,
            nBits: 386_084_628,
            nonce: 4_163_663_897,
            blockHash: 0x0000000000000000000016247d9acc6bc963d4b31d5feee6f09534131e6ae409,
            blockNumber: 864_538
        });
        blockHeaders[3] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2d434000,
            prevBlockHash: 0x0000000000000000000016247d9acc6bc963d4b31d5feee6f09534131e6ae409,
            merkleRootHash: 0x185635a49b82d5de5271397f55c947b732e5bd54c5f346b0f32366fe31043687,
            timestamp: 1_728_271_768,
            nBits: 386_084_628,
            nonce: 1_697_399_562,
            blockHash: 0x000000000000000000003b7021a60182556f221f0ee7204bac4c5785e662e8d4,
            blockNumber: 864_539
        });
        blockHeaders[4] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20800000,
            prevBlockHash: 0x000000000000000000003b7021a60182556f221f0ee7204bac4c5785e662e8d4,
            merkleRootHash: 0x4c943c38ab6d257d58015961d414200afd30844e4991d753f20cf4726b863f6e,
            timestamp: 1_728_272_309,
            nBits: 386_084_628,
            nonce: 3_281_017_360,
            blockHash: 0x0000000000000000000148edcc37fe3f0c97d0ac9e0e1cc82258246f265cb433,
            blockNumber: 864_540
        });
        blockHeaders[5] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x278ca000,
            prevBlockHash: 0x0000000000000000000148edcc37fe3f0c97d0ac9e0e1cc82258246f265cb433,
            merkleRootHash: 0x1982f5184e4773ccc9285b95eb375ee59b504a64e319d57299f2f5bb8fad768b,
            timestamp: 1_728_272_630,
            nBits: 386_084_628,
            nonce: 3_489_960_332,
            blockHash: 0x000000000000000000012303670d1e55715caefa18605df2dde76c51bbf6491d,
            blockNumber: 864_541
        });
        blockHeaders[6] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2b3f2000,
            prevBlockHash: 0x000000000000000000012303670d1e55715caefa18605df2dde76c51bbf6491d,
            merkleRootHash: 0xe12098a3faaa72c0a14d1870a32aa1e8defac36ae2b2114b3a7688d8bcd41ae4,
            timestamp: 1_728_273_202,
            nBits: 386_084_628,
            nonce: 2_074_363_943,
            blockHash: 0x00000000000000000001709efd2bdac6c74ca9610ff352d48712e62a38b0b2b9,
            blockNumber: 864_542
        });
        blockHeaders[7] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2e4dc000,
            prevBlockHash: 0x00000000000000000001709efd2bdac6c74ca9610ff352d48712e62a38b0b2b9,
            merkleRootHash: 0x709f9adac795086e8e2cc2353719ef565b251bbd93279f122bf35958aa326f40,
            timestamp: 1_728_273_366,
            nBits: 386_084_628,
            nonce: 4_013_320_293,
            blockHash: 0x00000000000000000001847a92b19f165056f5858070f1004b1d31d066ff0daf,
            blockNumber: 864_543
        });
        blockHeaders[8] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2aa0c000,
            prevBlockHash: 0x00000000000000000001847a92b19f165056f5858070f1004b1d31d066ff0daf,
            merkleRootHash: 0x25fbacddb0fed4d93a3a649978a261a08b20c236f82a8daf3662cdcb774853fc,
            timestamp: 1_728_274_004,
            nBits: 386_084_628,
            nonce: 602_224_772,
            blockHash: 0x0000000000000000000306b24df0fb118bda21810cbabf88c759af60d3dfbaf5,
            blockNumber: 864_544
        });
        blockHeaders[9] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20000000,
            prevBlockHash: 0x0000000000000000000306b24df0fb118bda21810cbabf88c759af60d3dfbaf5,
            merkleRootHash: 0x3e35b1ef45e22a90c05f0a5aab3479dd163456f8c1627f1e4e0a9896a49ac802,
            timestamp: 1_728_274_202,
            nBits: 386_084_628,
            nonce: 3_962_862_598,
            blockHash: 0x00000000000000000002dc0017798f6af4f8c05e701858c192fd280b351a5927,
            blockNumber: 864_545
        });
        blockHeaders[10] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x30a36000,
            prevBlockHash: 0x00000000000000000002dc0017798f6af4f8c05e701858c192fd280b351a5927,
            merkleRootHash: 0x7e9b204dc06da2d556ad332cf5e77feb416b306183d22cc06216bc5e777634e3,
            timestamp: 1_728_274_519,
            nBits: 386_084_628,
            nonce: 3_506_156_865,
            blockHash: 0x00000000000000000002663d5fd62c7d5bf64f1e04dc9a6ad4e8423cb2b00857,
            blockNumber: 864_546
        });
        blockHeaders[11] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x264f2000,
            prevBlockHash: 0x00000000000000000002663d5fd62c7d5bf64f1e04dc9a6ad4e8423cb2b00857,
            merkleRootHash: 0xf33c80dc214d83c511316ebf2a467bf4aa07ecfe1ad87c5ed0c1319a027d8773,
            timestamp: 1_728_274_864,
            nBits: 386_084_628,
            nonce: 3_036_165_646,
            blockHash: 0x00000000000000000000ba6b421a68d3ae508b99e10a3168270e31adcefaa1ad,
            blockNumber: 864_547
        });
        blockHeaders[12] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x30bc8000,
            prevBlockHash: 0x00000000000000000000ba6b421a68d3ae508b99e10a3168270e31adcefaa1ad,
            merkleRootHash: 0xfd10f8c74cc0eab38180e2eb46811d1614520c3a7809c8f7513c6dfc0c267f62,
            timestamp: 1_728_274_891,
            nBits: 386_084_628,
            nonce: 2_698_974_798,
            blockHash: 0x000000000000000000010db2df8b74f0f0ddfdffa2a72e5bc149fbf1958b2702,
            blockNumber: 864_548
        });
        blockHeaders[13] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2652a000,
            prevBlockHash: 0x000000000000000000010db2df8b74f0f0ddfdffa2a72e5bc149fbf1958b2702,
            merkleRootHash: 0xb2f5e56d56391e683db42b9704725a8815eed06abbe1de259fca67b4e623f35b,
            timestamp: 1_728_276_049,
            nBits: 386_084_628,
            nonce: 524_964_201,
            blockHash: 0x00000000000000000001fedb9a3ddb3b92b0fd7d7a9296bdd7e008ff16d5adb2,
            blockNumber: 864_549
        });
        blockHeaders[14] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x31f76000,
            prevBlockHash: 0x00000000000000000001fedb9a3ddb3b92b0fd7d7a9296bdd7e008ff16d5adb2,
            merkleRootHash: 0x50470760563a962d76a9a81c181615565e29949ef8d20dadd4bbf5ab46f684ec,
            timestamp: 1_728_276_563,
            nBits: 386_084_628,
            nonce: 4_015_164_048,
            blockHash: 0x00000000000000000000a7f472ec32a28cfdd4ca7d9ba8a6377f79ff18bae1a7,
            blockNumber: 864_550
        });
        blockHeaders[15] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x242d8004,
            prevBlockHash: 0x00000000000000000000a7f472ec32a28cfdd4ca7d9ba8a6377f79ff18bae1a7,
            merkleRootHash: 0x9dfc34c38d4e473c0be47cd0a378c3ffebdc9dbb2d07dcafc3c9a2fe801e38b8,
            timestamp: 1_728_277_174,
            nBits: 386_084_628,
            nonce: 2_462_354_002,
            blockHash: 0x0000000000000000000016f7033bf77aeb8c97da12a809e89beb17d204091af9,
            blockNumber: 864_551
        });
        blockHeaders[16] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2001c000,
            prevBlockHash: 0x0000000000000000000016f7033bf77aeb8c97da12a809e89beb17d204091af9,
            merkleRootHash: 0x98c64379dd50f68a6fa573d3f3612e4cfef6933e5749b7d48cf3c9fd8848de4f,
            timestamp: 1_728_278_685,
            nBits: 386_084_628,
            nonce: 562_970_331,
            blockHash: 0x00000000000000000002742e4d0a0bd028a8984bba1ee6332d602916872951f6,
            blockNumber: 864_552
        });
        return blockHeaders;
    }
}
