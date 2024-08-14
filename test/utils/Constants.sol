// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import "../../src/interfaces/IDoefinBlockHeaderOracle.sol";

abstract contract Constants {
    IDoefinBlockHeaderOracle.BlockHeader[17] public initialBlockHeaders;
    IDoefinBlockHeaderOracle.BlockHeader[18] public nextBlockHeaders;

    function setupInitialBlocks() internal returns (IDoefinBlockHeaderOracle.BlockHeader[17] memory) {
        initialBlockHeaders[0] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x213b8000,
            prevBlockHash: 0x000000000000000000013412024e8979a0e0c8fb22aaa5fb7b099feedd1991f9,
            merkleRootHash: 0xc44aa6dd914d3363dc92f3e83daac0f08c0844f1b5ca2f5156ccf0fb44d27f01,
            timestamp: 1_712_927_715,
            nBits: 0x17034219,
            nonce: 3_666_636_075
        });
        initialBlockHeaders[1] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x23f4c000,
            prevBlockHash: 0x00000000000000000001d76d8631742115b772ee6ab93cdf36bd5d78e2f7f250,
            merkleRootHash: 0x7d87da258879151913787a2e8c1717e5c676b0fe5a9db0c164c3ad91eec25a15,
            timestamp: 1_712_928_324,
            nBits: 0x17034219,
            nonce: 2_001_261_904
        });
        initialBlockHeaders[2] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x26f34000,
            prevBlockHash: 0x000000000000000000021585fe3dc4cd327d78b4a73b0c3d7d6bddb5b4f62967,
            merkleRootHash: 0xf9151897084c724b7536576d8cffd4d7ae12dda505b62b59f03c8fc9cc58d8d3,
            timestamp: 1_712_928_393,
            nBits: 0x17034219,
            nonce: 2_744_059_218
        });
        initialBlockHeaders[3] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2d130000,
            prevBlockHash: 0x000000000000000000008674326cf976f09bcb72b7d9c957d811532ed82a061c,
            merkleRootHash: 0x7cb340f6f9e22f1e4e9efb5a0bb94026bc95264581b638aacc203977a86be4e5,
            timestamp: 1_712_928_483,
            nBits: 0x17034219,
            nonce: 232_290_002
        });
        initialBlockHeaders[4] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2e1a4000,
            prevBlockHash: 0x00000000000000000001fae6d4e5869724d9a55c49aa317b6380d09c72dab7aa,
            merkleRootHash: 0x2fd22167d58af841377b691781db049cdd1134e363fd7462020b1103493bbe18,
            timestamp: 1_712_930_330,
            nBits: 0x17034219,
            nonce: 2_975_049_986
        });
        initialBlockHeaders[5] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x30b38000,
            prevBlockHash: 0x00000000000000000001c935ac61685dd57ff0dd2181ab607083fac613a3d0c8,
            merkleRootHash: 0xce8cedeb8acd36ceb570e8198a40a8e2095645c62afca98c8786416c67239760,
            timestamp: 1_712_930_844,
            nBits: 0x17034219,
            nonce: 4_167_839_757
        });
        initialBlockHeaders[6] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2ee76000,
            prevBlockHash: 0x00000000000000000000ac5d948ffa9722043f4e67d7d212d27e865a12da0d1d,
            merkleRootHash: 0x313f6f906085540f2916fc54fbebccab184b4accba25772b1fef13a6ac37e14c,
            timestamp: 1_712_931_332,
            nBits: 0x17034219,
            nonce: 2_477_280_636
        });
        initialBlockHeaders[7] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x280c2000,
            prevBlockHash: 0x00000000000000000000040645b21b508765efe2ea272c986e8f3bc469cc0826,
            merkleRootHash: 0xe1750eae845642c53024ce3edaae7837a0a8d9dfb635525aa64daecc644a1f0f,
            timestamp: 1_712_931_713,
            nBits: 0x17034219,
            nonce: 304_578_959
        });
        initialBlockHeaders[8] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20800000,
            prevBlockHash: 0x000000000000000000015f7d88ad5b7e8b21b6c1724947aea7042b7e1ca3f7e4,
            merkleRootHash: 0xef913f9b73c3d61b50ea8725db7d8b8c6bf58acc53b4ef301f2afa64b8396f93,
            timestamp: 1_712_932_190,
            nBits: 0x17034219,
            nonce: 1_006_604_870
        });
        initialBlockHeaders[9] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x33b40000,
            prevBlockHash: 0x00000000000000000001c09a88c45dc7f564e26f2531b9f1ca06a53e986cfee3,
            merkleRootHash: 0x7873ec569b26d46bf030393822f1f8d5594326faea7581ac0f850c81b0713414,
            timestamp: 1_712_932_769,
            nBits: 0x17034219,
            nonce: 1_809_362_959
        });
        initialBlockHeaders[10] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x200bc000,
            prevBlockHash: 0x00000000000000000002eabdbd35fb75019b7610dd02d020e3dc8a61bfed4d51,
            merkleRootHash: 0x701e180e1a404bfb22d957e807fde81faceb1b77529f5e251fc702ac28c830e4,
            timestamp: 1_712_934_076,
            nBits: 0x17034219,
            nonce: 2_693_788_053
        });
        initialBlockHeaders[11] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2af58000,
            prevBlockHash: 0x000000000000000000027dd14f6e5e1fa530ea497eb31b0a9f481c3d7d26544b,
            merkleRootHash: 0xb899b04ec1e021726b2ba9bd48df189e64fa0b5a7e5fcc36532b4d62dad5b807,
            timestamp: 1_712_934_556,
            nBits: 0x17034219,
            nonce: 686_364_004
        });
        initialBlockHeaders[12] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x36000000,
            prevBlockHash: 0x000000000000000000016ee91a82962f879e6ed54080a67da5f28185c7edab7b,
            merkleRootHash: 0x2196156490ea5d0ee09a29a31501211f3f36057b97f45bcb3b78eee166060f31,
            timestamp: 1_712_935_895,
            nBits: 0x17034219,
            nonce: 2_593_830_908
        });
        initialBlockHeaders[13] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2d542000,
            prevBlockHash: 0x000000000000000000026bb0108429f3bb9daf888c85ebe846b8af59d1ca7a9a,
            merkleRootHash: 0xdf308c7a701d0d2dad79c19e55f13328657cc1cd7887247fec9d637d892335fe,
            timestamp: 1_712_937_894,
            nBits: 0x17034219,
            nonce: 240_595_568
        });
        initialBlockHeaders[14] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20800000,
            prevBlockHash: 0x000000000000000000004203bc66f562de86821b27ca038f4a3d342a12d55f6c,
            merkleRootHash: 0xfd9b761a2482ebe81592a5d0c3fc5c4101d6cb77ebb8ba0239a6aad6dc573e7e,
            timestamp: 1_712_939_811,
            nBits: 0x17034219,
            nonce: 1_203_082_080
        });
        initialBlockHeaders[15] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20002000,
            prevBlockHash: 0x000000000000000000017b75f32705792f5bf1f350a536b114453d6a2c15056e,
            merkleRootHash: 0x35207066c7854bcf2620029b849b5713730c856939e2cb168047abc971b23ddb,
            timestamp: 1_712_939_989,
            nBits: 0x17034219,
            nonce: 2_267_009_901
        });
        initialBlockHeaders[16] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x21e02000,
            prevBlockHash: 0x000000000000000000002e334d605c87463e3e063b733f1ab39b3ce33146e87c,
            merkleRootHash: 0x0c0d616463b1b888ff49c72b65d46a6ba6ee0c9d2c7b0b8d75d64a9364f7c85f,
            timestamp: 1_712_940_014,
            nBits: 0x17034219,
            nonce: 305_767_976
        });
        return initialBlockHeaders;
    }

    function getNextBlocks() internal returns (IDoefinBlockHeaderOracle.BlockHeader[18] memory) {
        nextBlockHeaders[0] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2de60000,
            prevBlockHash: 0x00000000000000000001a66adbcce19ffa90fb72f37115e43b407ea49b4a2dbf,
            merkleRootHash: 0xbb94b9f29d86433922fce640b9e95605dd29661978a9040e739ff47553595d3b,
            timestamp: 1_712_940_028,
            nBits: 0x17034219,
            nonce: 1_539_690_831
        });
        nextBlockHeaders[1] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2a000000,
            prevBlockHash: 0x00000000000000000000057f8a11b249b7d174bf2bc5595a84ba20f9285decf6,
            merkleRootHash: 0xe2ac709ad52a66c2109c75924f82e55491f67f72642eb8eab0c8c189a7bed28b,
            timestamp: 1_712_940_152,
            nBits: 0x17034219,
            nonce: 3_138_544_259
        });
        nextBlockHeaders[2] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x3fffe000,
            prevBlockHash: 0x0000000000000000000038cbd371231c4c0aafb9c8603f2a684125f3d635411e,
            merkleRootHash: 0xa99db6eb092600b1f2b8574319e57bf63185708ce37a0888640d4c95a4fbc4dd,
            timestamp: 1_712_940_570,
            nBits: 0x17034219,
            nonce: 1_777_110_086
        });
        nextBlockHeaders[3] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20a00000,
            prevBlockHash: 0x00000000000000000002c6445f756e0eb1c6022a50e78201468dd180d647eaa9,
            merkleRootHash: 0xc037d2717895182afd5223f465ff8be73d23b13fbecde7e7677a5ed7a8ee6bf8,
            timestamp: 1_712_940_639,
            nBits: 0x17034219,
            nonce: 487_615_248
        });
        nextBlockHeaders[4] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20036000,
            prevBlockHash: 0x00000000000000000002fd5d39884412f0446bc517ef98c53e23d5b54832985a,
            merkleRootHash: 0x46aecf8d4610afe7f1de2877aad4a2508e9a427c98f4b2d1f9062ce445921d66,
            timestamp: 1_712_941_874,
            nBits: 0x17034219,
            nonce: 1_779_769_965
        });
        nextBlockHeaders[5] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2c00a000,
            prevBlockHash: 0x000000000000000000022e0e4688f614e65e71758977a4ca1c539de77eb450ec,
            merkleRootHash: 0x15c7cdbe97e526806846ea2da1080b63e00be54d7f17416d71ffbf1f18bd492c,
            timestamp: 1_712_941_987,
            nBits: 0x17034219,
            nonce: 1_601_322_590
        });
        nextBlockHeaders[6] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x36000000,
            prevBlockHash: 0x00000000000000000000b1b1f92b9a66f78b5b804a6f83cf0178c44a263a02bf,
            merkleRootHash: 0x62db2da74545a7d50e3897e2597be90414e768857845b8fdee6c819dc367b8cc,
            timestamp: 1_712_942_598,
            nBits: 0x17034219,
            nonce: 2_334_851_291
        });
        nextBlockHeaders[7] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x26e3c000,
            prevBlockHash: 0x00000000000000000001b277b77bf1ddaa996e3a8e4b70ab6ddd5ad19279c726,
            merkleRootHash: 0xfc1e91224b17e1eeef526f88f1e2945d56d4b81804fe74371d163ccca3327395,
            timestamp: 1_712_943_743,
            nBits: 0x17034219,
            nonce: 3_766_774_278
        });
        nextBlockHeaders[8] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x3fffe000,
            prevBlockHash: 0x00000000000000000002c278299e7d9a95de1a3e2bdb8e7545aa27721ad2a0ec,
            merkleRootHash: 0x1c9274c9cb7482fcb2dfb444e4cdd397579c3aeb994d09d4db66e700918f4bac,
            timestamp: 1_712_943_963,
            nBits: 0x17034219,
            nonce: 941_197_712
        });
        nextBlockHeaders[9] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x26e66000,
            prevBlockHash: 0x00000000000000000002b8386290fb862947822a4907e719293d984e418fdb1a,
            merkleRootHash: 0xb2b57500a124a83b84b9c9fa5e9772a3b606a931f028b2ccf1b9a472816d6460,
            timestamp: 1_712_943_999,
            nBits: 0x17034219,
            nonce: 1_746_360_673
        });
        nextBlockHeaders[10] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2e998000,
            prevBlockHash: 0x000000000000000000015896e5f75849029357203dc6720659b0ca5ce9cdcf7f,
            merkleRootHash: 0x11d6216e29f4de6f664891b2e4d29a56aa2ad9413fa298c2a8a88f2c650a0051,
            timestamp: 1_712_944_410,
            nBits: 0x17034219,
            nonce: 2_584_716_920
        });
        nextBlockHeaders[11] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x252de000,
            prevBlockHash: 0x00000000000000000003255e96d188a721203cbdf7685ab2430c526893fc66ca,
            merkleRootHash: 0x859af318218f255ac37b18654cdb9c7422dc891dc66aff111802ca85699e7fc1,
            timestamp: 1_712_944_526,
            nBits: 0x17034219,
            nonce: 1_226_973_589
        });
        nextBlockHeaders[12] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2b784000,
            prevBlockHash: 0x00000000000000000000cf6bb153df21ce3ccae6362131fc8b75be639e230c4c,
            merkleRootHash: 0xd26f3b741d039ffa78f105d7e63e71bd9cd485bc77f31303d24b4e41c44ec2b3,
            timestamp: 1_712_945_776,
            nBits: 0x17034219,
            nonce: 3_824_826_725
        });
        nextBlockHeaders[13] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2be3e000,
            prevBlockHash: 0x0000000000000000000269f3dd78535d45dd858ec4d4633bcc9efa4e6c6e448d,
            merkleRootHash: 0x7fa3ec76a3422830e89c8abba5eb46429249a9f889af3bb824b2f1811f419bdd,
            timestamp: 1_712_946_418,
            nBits: 0x17034219,
            nonce: 3_076_934_352
        });
        nextBlockHeaders[14] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20c00000,
            prevBlockHash: 0x0000000000000000000302c6ad4ca5653e7e558668466315f25bf26695682024,
            merkleRootHash: 0x5e3159b7a12093be466fcf14760ae4753113e2224947262d42fe075ece22abeb,
            timestamp: 1_712_947_211,
            nBits: 0x17034219,
            nonce: 4_278_066_754
        });
        nextBlockHeaders[15] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x21586000,
            prevBlockHash: 0x0000000000000000000338ead7f223b943cd77c89cf9da7f535d18f33ea497fc,
            merkleRootHash: 0x895204a9e18365fe8f5cffe14079169136a4a477760babe65f8c160e01b335ba,
            timestamp: 1_712_947_657,
            nBits: 0x17034219,
            nonce: 3_164_567_700
        });
        nextBlockHeaders[16] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x24d72000,
            prevBlockHash: 0x00000000000000000000fc5e87990b998d3c1c1701724ffd23be220625c07c40,
            merkleRootHash: 0x00180be331a0176467c32b8203ebc67a80371377d8aed943c9121730a1331e09,
            timestamp: 1_712_947_903,
            nBits: 0x17034219,
            nonce: 1_577_974_910
        });
        nextBlockHeaders[17] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20b30000,
            prevBlockHash: 0x0000000000000000000172459d2b973905971c72949d356a0380abd3782ebef8,
            merkleRootHash: 0x4cb0db074560b8adaffc5c0b393b5b3660c98ce57d11c9ea0b1adb647ab4cc23,
            timestamp: 1_712_948_448,
            nBits: 0x17034219,
            nonce: 3_136_838_180
        });
        return nextBlockHeaders;
    }
}
