// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

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
                                    CONFIG
    //////////////////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////////////////
                                    ORDER_BOOK
    //////////////////////////////////////////////////////////////////////////*/
    /// @notice Thrown when strike is zero
    error OrderBook_ZeroStrike();

    /// @notice Thrown when amount is zero
    error OrderBook_ZeroAmount();

    /// @notice Thrown when notional is not correct
    error OrderBook_InvalidNotional();

    /// @notice Thrown when expiry is zero
    error OrderBook_ZeroExpiry();

    /// @notice Thrown when a amount is less than the min collateral amount
    error OrderBook_LessThanMinCollateralAmount();

    /// @notice Thrown when min strike amount is zero
    error OrderBook_InvalidMinCollateralAmount();

    /// @notice Thrown when the period to match an order has expired
    error OrderBook_OrderExpired();

    /// @notice Thrown when the period to exercise an order has not reached
    error OrderBook_NotWithinExerciseWindow();

    /// @notice Thrown when the sender is not allowed to match an order
    error OrderBook_MatchOrderNotAllowed();

    /// @notice Thrown when the token owner tries to transfer their token
    error OrderBook_OptionTokenTransferNotAllowed();

    /// @notice Thrown when the order is not settled
    error OrderBook_OrderMustBeSettled();

    /// @notice Thrown when the match order amount is incorrect
    error OrderBook_UnableToMatchOrder();

    /// @notice Thrown when the order is already matched
    error OrderBook_OrderAlreadyMatched();

    /// @notice Thrown when collateral token is not valid
    error OrderBook_InvalidCollateralToken();

    /// @notice Thrown when a non pending order is edited
    error OrderBook_CannotCancelOrder();

    /// @notice Thrown when a non pending order is canceled
    error OrderBook_CanOnlyUpdatePendingOrder();

    /// @notice Thrown when a non pending order is canceled
    error OrderBook_OrderMustBePending();

    /// @notice Thrown when a non-trader is trying to cancel an order
    error OrderBook_CallerNotMaker();

    /// @notice Thrown when an order cannot be deleted
    error OrderBook_CannotDeleteOrder();

    /*//////////////////////////////////////////////////////////////////////////
                              BLOCK HEADER ORACLE
    //////////////////////////////////////////////////////////////////////////*/
    /// @notice Thrown when timestamps are insufficient
    error BlockHeaderOracle_InsufficientTimeStamps();

    /// @notice Thrown when the there is a block hash mismatch
    error BlockHeaderOracle_PrevBlockHashMismatch();

    /// @notice Thrown when the timestamp is invalid
    error BlockHeaderOracle_InvalidTimestamp();

    /// @notice Thrown when the data length is not correct
    error BlockHeaderOracle_IncorrectDataLength();

    /// @notice Thrown when there are no block added
    error BlockHeaderOracle_NoBlocksAdded();

    /// @notice Thrown when the block hash is invalid
    error BlockHeaderOracle_InvalidBlockHash();

    /// @notice Thrown when the fork point cannot be found
    error BlockHeaderOracle_CannotFindForkPoint();

    /// @notice Thrown when a reorg did not occur
    error BlockHeaderOracle_NewChainNotLonger();
}
