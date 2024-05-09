// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;
import { IAdminable } from "./IAdminable.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/// @title IDoefinFactory
/// @notice This interface defines the important functions to setup the Deofin v1 configuration
interface IDoefinFactory is IAdminable {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the token is set
    event SetTokenWhitelist(address indexed token);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/


    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Updates the token whitelist
    ///
    /// @dev Emits a {SetTokenWhitelist} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the contract admin.
    ///
    /// @param token Token to whitelist
    function setTokenWhitelist(address token) external;
}
