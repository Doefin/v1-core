// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.24;

import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

/// @title IDoefinConfig
/// @notice This interface defines the important functions to setup the DeofinV1 OrderBook
interface IDoefinConfig {
    struct ApprovedToken {
        IERC20Metadata token;
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

    /// @notice Emitted when the fee address is set
    event SetFeeAddress(address indexed feeAddress);

    /// @notice Emitted when the block header address is set
    event SetBlockHeaderOracle(address indexed blockHeaderOracle);

    /// @notice Emitted when the trusted forwarder address is set
    event SetTrustedForwarder(address indexed trustedForwarder);

    /// @notice Emitted when the authorized relayer address is set
    event SetAuthorizedRelayer(address indexed authorizedRelayer);

    event FeeSet(uint256 newFee);

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
    function tokenIsInApprovedList(address token) external view returns (bool);

    /// @notice Set the fee of the order book
    /// @param newFee The fee charged to an order
    function setFee(uint256 newFee) external;

    /// @notice Set the order book address
    /// @param orderBook The order book address
    function setOrderBook(address orderBook) external;

    /// @notice Updates the options manager address
    /// @param feeAddress The fee address of the options contract
    function setFeeAddress(address feeAddress) external;

    /// @notice Updates the block header oracle
    /// @param blockHeaderOracle The new block header oracle address
    function setBlockHeaderOracle(address blockHeaderOracle) external;

    /// @notice Set the trusted forwarder
    /// @param trustedForwarder The trusted forwarder address
    function setTrustedForwarder(address trustedForwarder) external;

    /// @notice Set the authorized relayer address
    /// @param authorizedRelayer The authorized relayer address
    function setAuthorizedRelayer(address authorizedRelayer) external;

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    /// @notice Return the order book fee
    /// @return The fee of the order book
    function getFee() external view returns (uint256);

    /// @notice Returns the approved token struct
    /// @param token The approved token
    /// @return ApprovedToken The ApprovedToken
    function getApprovedToken(address token) external view returns (ApprovedToken memory);

    /// @notice Returns the fee address of the options contract
    /// @return The fee address
    function getFeeAddress() external view returns (address);

    /// @notice Returns the address of the block header oracle
    /// @return The block header oracle address
    function getBlockHeaderOracle() external view returns (address);

    /// @notice Returns the address of the order book contract
    /// @return The order book contract address
    function getOrderBook() external view returns (address);

    /// @notice Return the trusted forwarder address
    /// @return The trusted forwarder address
    function getTrustedForwarder() external view returns (address);

    /// @notice Return the authorized relayer address
    /// @return The authorized relayer address
    function getAuthorizedRelayer() external view returns (address);
}
