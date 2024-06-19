// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

/// @title IDoefinOptionsManager
/// @notice This interface defines the important functions to setup the DeofinV1 OrderBook
interface IDoefinOptionsManager {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new order is registered.
    /// @param id The unique identifier of the order.
    event OrderRegistered(uint256 indexed id);

    /// @notice Emitted when an order book address is set
    /// @param orderBook The order book address to set
    event SetOrderBookAddress(address indexed orderBook);

    /// @notice Emitted when the block header oracle address is set
    /// @param blockHeaderOracle The block header oracle address to set
    event SetBlockHeaderOracleAddress(address indexed blockHeaderOracle);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    /// @notice Registers an order id to be settled in the future
    /// @param orderId orderId of the order to settle
    function registerOrderForSettlement(uint256 orderId) external;

    /// @notice Set a new order book address
    /// @param newOrderBook address of the new order book
    function setOrderBookAddress(address newOrderBook) external;

    /// @notice Set a new block header oracle address
    /// @param newBlockHeaderOracle address of the block header oracle
    function setBlockHeaderOracleAddress(address newBlockHeaderOracle) external;

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
}
