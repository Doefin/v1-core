// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19;

import { Errors } from "./libraries/Errors.sol";
import { IDoefinFactory } from "./interfaces/IDoefinFactory.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./DoefinV1OrderBook.sol";

/// @title DoefinV1Factory
/// @notice See the documentation in {IDoefinFactory}.
contract DoefinV1Factory is IDoefinFactory, Ownable {
    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/
    uint8 public orderBookIdCounter;

    mapping(address => bool) public approvedTokensList;
    mapping(uint8 => address) public orderBookIdToAddress;
    mapping(address => OrderBook) public orderBooks;


    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Emits a {TransferAdmin} event.
    constructor() Ownable() {}

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    //@@inheritdoc IDoefinFactory
    function createOrderBook() external override onlyOwner returns(address orderBookAddress) {
        orderBookAddress = address (new DoefinV1OrderBook());
        uint8 orderBookId = orderBookIdCounter + 1;

        orderBookIdToAddress[orderBookId] = orderBookAddress;
        orderBooks[orderBookAddress] = OrderBook(orderBookId, orderBookAddress);
        orderBookIdCounter = orderBookId;

        emit OrderBookCreated(orderBookId, orderBookAddress);
    }

    //@@inheritdoc
    function addTokenToApprovedList(address token) external override onlyOwner {
        if(token == address(0)) {
            revert Errors.ZeroAddress();
        }

        approvedTokensList[token] = true;
        emit AddTokenToApprovedList(token, true);
    }

    //@@inheritdoc
    function removeTokenFromApprovedList(address token) external override onlyOwner {
        if(token == address(0)) {
            revert Errors.ZeroAddress();
        }

        approvedTokensList[token] = false;
        emit AddTokenToApprovedList(token, false);
    }

    //@@inheritdoc
    function getOrderBookAddress(uint8 orderBookId) external override view returns (address) {
        return orderBookIdToAddress[orderBookId];
    }

    //@@inheritdoc
    function getOrderBook(address orderBookAddress) external  view returns (OrderBook memory) {
        return orderBooks[orderBookAddress];
    }

    //@@inheritdoc
    function getOrderBookIdCounter() external view returns(uint8) {
        return orderBookIdCounter;
    }
}
