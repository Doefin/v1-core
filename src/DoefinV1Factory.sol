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
    mapping(address => bool) public approvedTokensList;
    mapping(address => OrderBook) public orderBooks;


    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Initializes the factor and it's owner contract
    constructor() Ownable() {}

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    //@@inheritdoc IDoefinFactory
    function createOrderBook() external override onlyOwner returns(address orderBookAddress) {
        orderBookAddress = address (new DoefinV1OrderBook());
        orderBooks[orderBookAddress] = OrderBook(orderBookAddress);
        emit OrderBookCreated(orderBookAddress);
    }

    //@@inheritdoc
    function addTokenToApprovedList(address token) external override onlyOwner {
        if(token == address(0)) {
            revert Errors.ZeroAddress();
        }

        approvedTokensList[token] = true;
        emit AddTokenToApprovedList(token);
    }

    //@@inheritdoc
    function removeTokenFromApprovedList(address token) external override onlyOwner {
        if(token == address(0)) {
            revert Errors.ZeroAddress();
        }

        delete approvedTokensList[token];
        emit RemoveTokenFromApprovedList(token);
    }

    //@@inheritdoc
    function getOrderBook(address orderBookAddress) external view returns (OrderBook memory) {
        return orderBooks[orderBookAddress];
    }
}
