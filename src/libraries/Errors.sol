// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/// @title Errors
/// @notice Library containing all custom errors the protocol may revert with.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                         GENERICS
    //////////////////////////////////////////////////////////////////////////*/
    /// @notice Thrown when trying to delegate call to a function that disallows delegate calls.
    error DelegateCall();

    /// @notice Thrown when address zero is used
    error ZeroAddress();

    /*//////////////////////////////////////////////////////////////////////////
                                          FACTORY
    //////////////////////////////////////////////////////////////////////////*/
    /// @notice Thrown when `msg.sender` is not the admin.
    error DoefinV1Factory_CallerNotAdmin(address caller);
}
