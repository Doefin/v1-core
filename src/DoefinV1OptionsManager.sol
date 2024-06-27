// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Errors } from "./libraries/Errors.sol";
import { IDoefinV1OrderBook } from "./DoefinV1OrderBook.sol";
import { IDoefinFactory } from "./interfaces/IDoefinFactory.sol";
import { IDoefinOptionsManager } from "./interfaces/IDoefinOptionsManager.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title DoefinV1Factory
/// @notice See the documentation in {IDoefinFactory}.
contract DoefinV1OptionsManager is IDoefinOptionsManager, Ownable {
    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/
    /// @notice The order book address used for settling orders
    address public orderBook;

    /// @notice The options fee address for collecting option premiums
    address public optionsFeeAddress;

    /// @notice The block header oracle address used for settling orders
    address public blockHeaderOracle;

    /// @notice List of orderIds to be settled
    uint256[] public registeredOrderIds;

    modifier onlyOrderBook() {
        require(msg.sender == orderBook, "OptionsManager: caller is not the order book");
        _;
    }

    modifier onlyBlockHeaderOracle() {
        require(msg.sender == blockHeaderOracle, "OptionsManager: caller is not block header oracle");
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Initializes the options manager
    constructor(address _orderBook, address _blockHeaderOracle, address _optionsFeeAddress) Ownable() {
        orderBook = _orderBook;
        blockHeaderOracle = _blockHeaderOracle;
        optionsFeeAddress = _optionsFeeAddress;
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    //@@inheritdoc
    function registerOrderForSettlement(uint256 orderId) public onlyOrderBook {
        registeredOrderIds.push(orderId);
        emit OrderRegistered(orderId);
    }

    //@@inheritdoc
    function settleOrders(uint256 blockNumber, uint256 difficulty) public onlyBlockHeaderOracle {
        uint256 len = registeredOrderIds.length;
        for (uint256 i = 0; i < len; i++) {
            IDoefinV1OrderBook(orderBook).settleOrder(registeredOrderIds[i], blockNumber, difficulty);
            registeredOrderIds[i] = registeredOrderIds[len - 1];
            registeredOrderIds.pop();
            len--;
        }
    }

    //@@inheritdoc
    function setOrderBookAddress(address newOrderBook) public onlyOwner {
        if (newOrderBook == address(0)) {
            revert Errors.ZeroAddress();
        }

        orderBook = newOrderBook;
        emit SetOrderBookAddress(newOrderBook);
    }

    //@@inheritdoc
    function setBlockHeaderOracleAddress(address newBlockHeaderOracle) public onlyOwner {
        if (newBlockHeaderOracle == address(0)) {
            revert Errors.ZeroAddress();
        }

        blockHeaderOracle = newBlockHeaderOracle;
        emit SetBlockHeaderOracleAddress(newBlockHeaderOracle);
    }

    //@@inheritdoc
    function setOptionsFeeAddress(address newOptionsFeeAddress) public onlyOwner {
        if (newOptionsFeeAddress == address(0)) {
            revert Errors.ZeroAddress();
        }

        optionsFeeAddress = newOptionsFeeAddress;
        emit SetOptionsFeeAddress(newOptionsFeeAddress);
    }

    //@@inheritdoc
    function getOptionsFeeAddress() public returns (address) {
        if (optionsFeeAddress == address(0)) {
            revert Errors.ZeroAddress();
        }

        return optionsFeeAddress;
    }
}
