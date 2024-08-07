// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "../interfaces/IDoefinBlockHeaderOracle.sol";
import "./Errors.sol";

/// @title BlockHeaderUtils
/// @notice Library that implements utils for bitcoin block header hashing
library BlockHeaderUtils {
    /**
     * @dev Return true/false if the block header hash is valid
     * @param currentBlockHeader The block header to hash
     * @param nextBlockHeader The block header to hash
     * @return true/false
     */
    function isValidBlockHeaderHash(
        IDoefinBlockHeaderOracle.BlockHeader memory currentBlockHeader,
        IDoefinBlockHeaderOracle.BlockHeader memory nextBlockHeader
    )
        internal
        view
        returns (bool)
    {
        uint256 target = calculateDifficultyTarget(currentBlockHeader);
        bytes32 hash = calculateBlockHash(nextBlockHeader);

        return uint256(hash) < target;
    }

    /**
     * @dev Get the hash of the block header
     * @param blockHeader The block header to hash
     * @return the hash of the block header
     * @notice The function encodes block header data and applies a double SHA-256 hash.
     * Each element of the block header must be encoded in little-endian byte order. Since the EVM
     * uses big-endian byte order, we reverse the bytes of all values prior to encoding to follow the
     * implementation of the bitcoin double-hash algorithm. Note that we reverse the byte order
     * to allow the result to be interpreted as a uint256 value in big-endian byte order.
     */
    function calculateBlockHash(IDoefinBlockHeaderOracle.BlockHeader memory blockHeader)
        internal
        pure
        returns (bytes32)
    {
        //1. Reverse the byte order of each block header field to match the little-endian format required by Bitcoin
        //2. Serialize the block header into an 80-byte array: (4 + 32 + 32 + 4 + 4 + 4) bytes
        bytes memory data = abi.encodePacked(
            reverseUint32(blockHeader.version),
            reverseBytes32(blockHeader.prevBlockHash),
            reverseBytes32(blockHeader.merkleRootHash),
            reverseUint32(blockHeader.timestamp),
            reverseUint32(blockHeader.nBits),
            reverseUint32(blockHeader.nonce)
        );

        require(data.length == 80, "incorrect data length");

        //3. Calculate the SHA-256 hash of the serialized data
        //4. Convert bytes32 of the first hash to bytes array for second SHA-256 hash
        //5. Calculate the second SHA-256 hash of the bytes array
        bytes32 blockHashBytes32 = sha256(abi.encodePacked(sha256(data)));

        bytes memory blockHash = new bytes(32);
        assembly {
            mstore(add(blockHash, 32), blockHashBytes32)
        }

        //6. refer to step1
        return reverseBytes32(blockHashBytes32);
    }

    function reverseUint32(uint32 input) internal pure returns (uint32) {
        uint32 v = input;

        // swap bytes
        v = ((v & 0xFF00FF00) >> 8) | ((v & 0x00FF00FF) << 8);

        // swap 2-byte long pairs
        v = (v >> 16) | (v << 16);
        return v;
    }

    function reverseBytes32(bytes32 input) internal pure returns (bytes32) {
        uint256 v = uint256(input);

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8)
            | ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16)
            | ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32)
            | ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64)
            | ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);

        return bytes32(v);
    }

    /**
     * @dev Calculates the difficulty target of a block header
     * @param blockHeader The block header to hash
     * @return the difficulty target
     * @notice The difficulty target is calculated from the nBits encoding as:
     * target = coefficient * 256 ^ (exponent - 3)
     * Where the exponent is encoded as the first byte of the nBits value
     * and the coefficient is the remaining 3 bytes.
     *
     * The function extracts the first bytes (8-bits) of the nBits value by shifting the value 24 bits to the right and
     * extracts the last 3 bytes (24-bits) of the nBits by doing a bitwise AND with a 24-bit mask 0xFFFFFF.
     */
    function calculateDifficultyTarget(IDoefinBlockHeaderOracle.BlockHeader memory blockHeader)
        internal
        view
        returns (uint256)
    {
        uint256 exponent = uint256(blockHeader.nBits) >> 24;
        uint256 coefficient = uint256(blockHeader.nBits & 0xffffff);

        if (exponent <= 3) {
            return coefficient >> (8 * (3 - exponent)); //coefficient * 2 ^ (8 * (3 - exponent))
        } else {
            return coefficient << (8 * (exponent - 3)); //coefficient * 2 ^ (8 * (exponent - 3))
        }
    }

    function swap(uint256[11] memory array, uint256 i, uint256 j) internal pure {
        (array[i], array[j]) = (array[j], array[i]);
    }

    function sort(uint256[11] memory array, uint256 begin, uint256 end) internal pure {
        if (begin < end) {
            uint256 j = begin;
            uint256 pivot = array[j];
            for (uint256 i = begin + 1; i < end; ++i) {
                if (array[i] < pivot) {
                    swap(array, i, ++j);
                }
            }
            swap(array, begin, j);
            sort(array, begin, j);
            sort(array, j + 1, end);
        }
    }

    function median(uint256[11] memory array) internal pure returns (uint256) {
        sort(array, 0, 11);
        return (array[4] + array[5]) / 2;
    }

    function setupInitialBlocks() internal returns (IDoefinBlockHeaderOracle.BlockHeader[17] memory blockHeaders) {
        blockHeaders[0] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x213b8000,
            prevBlockHash: 0x000000000000000000013412024e8979a0e0c8fb22aaa5fb7b099feedd1991f9,
            merkleRootHash: 0xc44aa6dd914d3363dc92f3e83daac0f08c0844f1b5ca2f5156ccf0fb44d27f01,
            timestamp: 1_712_927_715,
            nBits: 0x17034219,
            nonce: 3_666_636_075
        });
        blockHeaders[1] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x23f4c000,
            prevBlockHash: 0x00000000000000000001d76d8631742115b772ee6ab93cdf36bd5d78e2f7f250,
            merkleRootHash: 0x7d87da258879151913787a2e8c1717e5c676b0fe5a9db0c164c3ad91eec25a15,
            timestamp: 1_712_928_324,
            nBits: 0x17034219,
            nonce: 2_001_261_904
        });
        blockHeaders[2] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x26f34000,
            prevBlockHash: 0x000000000000000000021585fe3dc4cd327d78b4a73b0c3d7d6bddb5b4f62967,
            merkleRootHash: 0xf9151897084c724b7536576d8cffd4d7ae12dda505b62b59f03c8fc9cc58d8d3,
            timestamp: 1_712_928_393,
            nBits: 0x17034219,
            nonce: 2_744_059_218
        });
        blockHeaders[3] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2d130000,
            prevBlockHash: 0x000000000000000000008674326cf976f09bcb72b7d9c957d811532ed82a061c,
            merkleRootHash: 0x7cb340f6f9e22f1e4e9efb5a0bb94026bc95264581b638aacc203977a86be4e5,
            timestamp: 1_712_928_483,
            nBits: 0x17034219,
            nonce: 232_290_002
        });
        blockHeaders[4] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2e1a4000,
            prevBlockHash: 0x00000000000000000001fae6d4e5869724d9a55c49aa317b6380d09c72dab7aa,
            merkleRootHash: 0x2fd22167d58af841377b691781db049cdd1134e363fd7462020b1103493bbe18,
            timestamp: 1_712_930_330,
            nBits: 0x17034219,
            nonce: 2_975_049_986
        });
        blockHeaders[5] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x30b38000,
            prevBlockHash: 0x00000000000000000001c935ac61685dd57ff0dd2181ab607083fac613a3d0c8,
            merkleRootHash: 0xce8cedeb8acd36ceb570e8198a40a8e2095645c62afca98c8786416c67239760,
            timestamp: 1_712_930_844,
            nBits: 0x17034219,
            nonce: 4_167_839_757
        });
        blockHeaders[6] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2ee76000,
            prevBlockHash: 0x00000000000000000000ac5d948ffa9722043f4e67d7d212d27e865a12da0d1d,
            merkleRootHash: 0x313f6f906085540f2916fc54fbebccab184b4accba25772b1fef13a6ac37e14c,
            timestamp: 1_712_931_332,
            nBits: 0x17034219,
            nonce: 2_477_280_636
        });
        blockHeaders[7] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x280c2000,
            prevBlockHash: 0x00000000000000000000040645b21b508765efe2ea272c986e8f3bc469cc0826,
            merkleRootHash: 0xe1750eae845642c53024ce3edaae7837a0a8d9dfb635525aa64daecc644a1f0f,
            timestamp: 1_712_931_713,
            nBits: 0x17034219,
            nonce: 304_578_959
        });
        blockHeaders[8] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20800000,
            prevBlockHash: 0x000000000000000000015f7d88ad5b7e8b21b6c1724947aea7042b7e1ca3f7e4,
            merkleRootHash: 0xef913f9b73c3d61b50ea8725db7d8b8c6bf58acc53b4ef301f2afa64b8396f93,
            timestamp: 1_712_932_190,
            nBits: 0x17034219,
            nonce: 1_006_604_870
        });
        blockHeaders[9] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x33b40000,
            prevBlockHash: 0x00000000000000000001c09a88c45dc7f564e26f2531b9f1ca06a53e986cfee3,
            merkleRootHash: 0x7873ec569b26d46bf030393822f1f8d5594326faea7581ac0f850c81b0713414,
            timestamp: 1_712_932_769,
            nBits: 0x17034219,
            nonce: 1_809_362_959
        });
        blockHeaders[10] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x200bc000,
            prevBlockHash: 0x00000000000000000002eabdbd35fb75019b7610dd02d020e3dc8a61bfed4d51,
            merkleRootHash: 0x701e180e1a404bfb22d957e807fde81faceb1b77529f5e251fc702ac28c830e4,
            timestamp: 1_712_934_076,
            nBits: 0x17034219,
            nonce: 2_693_788_053
        });
        blockHeaders[11] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2af58000,
            prevBlockHash: 0x000000000000000000027dd14f6e5e1fa530ea497eb31b0a9f481c3d7d26544b,
            merkleRootHash: 0xb899b04ec1e021726b2ba9bd48df189e64fa0b5a7e5fcc36532b4d62dad5b807,
            timestamp: 1_712_934_556,
            nBits: 0x17034219,
            nonce: 686_364_004
        });
        blockHeaders[12] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x36000000,
            prevBlockHash: 0x000000000000000000016ee91a82962f879e6ed54080a67da5f28185c7edab7b,
            merkleRootHash: 0x2196156490ea5d0ee09a29a31501211f3f36057b97f45bcb3b78eee166060f31,
            timestamp: 1_712_935_895,
            nBits: 0x17034219,
            nonce: 2_593_830_908
        });
        blockHeaders[13] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x2d542000,
            prevBlockHash: 0x000000000000000000026bb0108429f3bb9daf888c85ebe846b8af59d1ca7a9a,
            merkleRootHash: 0xdf308c7a701d0d2dad79c19e55f13328657cc1cd7887247fec9d637d892335fe,
            timestamp: 1_712_937_894,
            nBits: 0x17034219,
            nonce: 240_595_568
        });
        blockHeaders[14] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20800000,
            prevBlockHash: 0x000000000000000000004203bc66f562de86821b27ca038f4a3d342a12d55f6c,
            merkleRootHash: 0xfd9b761a2482ebe81592a5d0c3fc5c4101d6cb77ebb8ba0239a6aad6dc573e7e,
            timestamp: 1_712_939_811,
            nBits: 0x17034219,
            nonce: 1_203_082_080
        });
        blockHeaders[15] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x20002000,
            prevBlockHash: 0x000000000000000000017b75f32705792f5bf1f350a536b114453d6a2c15056e,
            merkleRootHash: 0x35207066c7854bcf2620029b849b5713730c856939e2cb168047abc971b23ddb,
            timestamp: 1_712_939_989,
            nBits: 0x17034219,
            nonce: 2_267_009_901
        });
        blockHeaders[16] = IDoefinBlockHeaderOracle.BlockHeader({
            version: 0x21e02000,
            prevBlockHash: 0x000000000000000000002e334d605c87463e3e063b733f1ab39b3ce33146e87c,
            merkleRootHash: 0x0c0d616463b1b888ff49c72b65d46a6ba6ee0c9d2c7b0b8d75d64a9364f7c85f,
            timestamp: 1_712_940_014,
            nBits: 0x17034219,
            nonce: 305_767_976
        });
        return blockHeaders;
    }
}
