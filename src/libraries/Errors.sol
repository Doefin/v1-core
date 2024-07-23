// SPDX-License-Identifier: UNLICENSED
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

    /*//////////////////////////////////////////////////////////////////////////
                                          ORDER_BOOK
    //////////////////////////////////////////////////////////////////////////*/
    /// @notice Thrown when strike is zero
    error OrderBook_ZeroStrike();

    /// @notice Thrown when amount is zero
    error OrderBook_ZeroAmount();

    /// @notice Thrown when expiry is zero
    error OrderBook_ZeroExpiry();

    /// @notice Thrown when min strike amount is zero
    error OrderBook_InvalidMinCollateralAmount();

    /// @notice Thrown when the period to match an order has expired
    error OrderBook_MatchOrderExpired();

    /// @notice Thrown when the period to exercise an order has not reached
    error OrderBook_NotWithinExerciseWindow();

    /// @notice Thrown when the sender is not allowed to match an order
    error OrderBook_MatchOrderNotAllowed();

    /// @notice Thrown when the token owner tries to transfer their token
    error OrderBook_OptionTokenTransferNotAllowed();

    /// @notice Thrown when the order is not settled
    error OrderBook_OrderNotSettled();

    /// @notice Thrown when the match order amount is incorrect
    error OrderBook_UnableToMatchOrder();

    /// @notice Thrown when the order is already matched
    error OrderBook_OrderAlreadyMatched();
}
