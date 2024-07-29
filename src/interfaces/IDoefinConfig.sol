// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IDoefinConfig
/// @notice This interface defines the important functions to setup the DeofinV1 OrderBook
interface IDoefinConfig {
    struct ApprovedToken {
        IERC20 token;
        uint256 minCollateralTokenAmount;
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

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    /// @notice Returns the approved token struct
    /// @param token The approved token
    /// @return ApprovedToken The ApprovedToken
    function getApprovedToken(address token) external view returns (ApprovedToken memory);
}
