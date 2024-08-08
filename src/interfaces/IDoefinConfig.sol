// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IDoefinConfig
/// @notice This interface defines the important functions to setup the DeofinV1 OrderBook
interface IDoefinConfig {
    struct ApprovedToken {
        IERC20 token;
        uint256 minCollateralAmount;
    }

    struct OrderBook {
        address orderBookAddress;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/
    /// @notice Event emitted when a new order book is created
    /// @param orderBookAddress The address of the new order book
    event OrderBookCreated(address indexed orderBookAddress);

    /// @notice Emitted when the token is added to approved list
    event AddTokenToApprovedList(address indexed token);

    /// @notice Emitted when the token is removed from approved list
    event RemoveTokenFromApprovedList(address indexed token);

    /// @notice Emitted when the order book address is set
    event SetOrderBook(address indexed optionsManager);

    /// @notice Emitted when the fee address is updated
    event SetFeeAddress(address indexed feeAddress);

    /// @notice Emitted when the block header address is updated
    event SetBlockHeaderOracle(address indexed blockHeaderOracle);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Updates the token approved list
    /// @param token Token to add to the approved list
    function addTokenToApprovedList(address token, uint256 minCollateralTokenAmount) external;

    /// @notice Updates the token approved list
    /// @param token Token to remove from the approved list
    function removeTokenFromApprovedList(address token) external;

    /// @notice Checks if  the token is in the approved list
    /// @param token Token to be check in the approved list
    /// @return true/false
    function tokenIsInApprovedList(address token) external returns (bool);

    /// @notice Set the order book address
    /// @param orderBook The order book address

    function setOrderBook(address orderBook) external;

    /// @notice Updates the options manager address
    /// @param feeAddress The fee address of the options contract
    function setFeeAddress(address feeAddress) external;

    /// @notice Updates the block header oracle
    /// @param newBlockHeaderOracle The new block header oracle address
    function setBlockHeaderOracle(address newBlockHeaderOracle) external;

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    /// @notice Returns the approved token struct
    /// @param token The approved token
    /// @return ApprovedToken The ApprovedToken
    function getApprovedToken(address token) external view returns (ApprovedToken memory);

    /// @notice Returns the address of the options manager
    /// @return The options manager address
    function getOptionsManager() external view returns (address);

    /// @notice Returns the fee address of the options contract
    /// @return The fee address
    function getFeeAddress() external view returns (address);

    /// @notice Returns the address of the block header oracle
    /// @return The block header oracle address
    function getBlockHeaderOracle() external view returns (address);
}
