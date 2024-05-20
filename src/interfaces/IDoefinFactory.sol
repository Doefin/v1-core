// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import "../types/DataTypes.sol";

/// @title IDoefinFactory
/// @notice This interface defines the important functions to setup the DeofinV1 OrderBook
interface IDoefinFactory {
    struct OrderBook {
        uint8 orderBookId;
        address orderBookAddress;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/
    /// @notice Event emitted when the owner is changed
    /// @param owner Address of the new owner
    event OwnerChanged(address indexed owner);

    /// @notice Event emitted when a new order book is created
    /// @param orderBookId The id of the new order book
    /// @param orderBookAddress The address of the new order book
    event OrderBookCreated (
        uint8 indexed orderBookId,
        address indexed orderBookAddress
    );

    /// @notice Emitted when the token is added to approved list
    event AddTokenToApprovedList(address indexed token, bool indexed isApproved);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a new orderBook
    function createOrderBook() external returns (address);

    /// @notice Updates the token approved list
    /// @param token Token to add to the approved list
    function addTokenToApprovedList(address token) external;

    /// @notice Updates the token approved list
    /// @param token Token to remove from the approved list
    function removeTokenFromApprovedList(address token) external;

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the address of the order book for the given order book id
    /// @param orderBookId The id of the order book to lookup
    /// @return orderBook The OrderBook
    function getOrderBookAddress(uint8 orderBookId) external view returns (address);

    /// @notice Returns the address of the order book for the given order book id
    /// @param orderBookAddress The address of the order book to lookup
    /// @return orderBook The OrderBook
    function getOrderBook(address orderBookAddress) external view returns (OrderBook memory);

    /// @notice Returns the orderBookId counter
    /// @return orderBook The orderBookIdCounter
    function getOrderBookIdCounter() external view returns(uint8);
}
