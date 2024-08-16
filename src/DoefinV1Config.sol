// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Errors } from "./libraries/Errors.sol";
import { IDoefinConfig } from "./interfaces/IDoefinConfig.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title DoefinV1Config
/// @notice See the documentation in {DoefinV1Config}.
contract DoefinV1Config is IDoefinConfig, Ownable {
    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/
    address public feeAddress;
    address public orderBook;
    address public trustedForwarder;
    address public blockHeaderOracle;
    address public authorizedRelayer;
    mapping(address => OrderBook) public orderBooks;
    mapping(address => ApprovedToken) public approvedTokens;

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Initializes the factor and it's owner contract
    constructor() Ownable() { }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    //@@inheritdoc IDoefinConfig
    function addTokenToApprovedList(address token, uint256 minCollateralAmount) external override onlyOwner {
        if (token == address(0)) {
            revert Errors.ZeroAddress();
        }

        if (minCollateralAmount == 0) {
            revert Errors.OrderBook_InvalidMinCollateralAmount();
        }

        approvedTokens[token] = ApprovedToken({ token: IERC20(token), minCollateralAmount: minCollateralAmount });

        emit AddTokenToApprovedList(token);
    }

    //@@inheritdoc IDoefinConfig
    function removeTokenFromApprovedList(address token) external override onlyOwner {
        if (token == address(0)) {
            revert Errors.ZeroAddress();
        }

        delete approvedTokens[token];
        emit RemoveTokenFromApprovedList(token);
    }

    //@@inheritdoc IDoefinConfig
    function tokenIsInApprovedList(address token) public returns (bool) {
        return address(approvedTokens[token].token) != address(0);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    //@@inheritdoc IDoefinConfig
    function setOrderBook(address newOrderBook) external override onlyOwner {
        if (newOrderBook == address(0)) {
            revert Errors.ZeroAddress();
        }

        orderBook = newOrderBook;
        emit SetOrderBook(newOrderBook);
    }

    //@@inheritdoc IDoefinConfig
    function setFeeAddress(address newFeeAddress) external override onlyOwner {
        if (newFeeAddress == address(0)) {
            revert Errors.ZeroAddress();
        }

        feeAddress = newFeeAddress;
        emit SetFeeAddress(newFeeAddress);
    }

    //@@inheritdoc
    function setBlockHeaderOracle(address newBlockHeaderOracle) external onlyOwner {
        if (newBlockHeaderOracle == address(0)) {
            revert Errors.ZeroAddress();
        }

        blockHeaderOracle = newBlockHeaderOracle;
        emit SetBlockHeaderOracle(newBlockHeaderOracle);
    }

    //@@inheritdoc
    function setTrustedForwarder(address newTrustedForwarder) external {
        if (newTrustedForwarder == address(0)) {
            revert Errors.ZeroAddress();
        }

        trustedForwarder = newTrustedForwarder;
        emit SetTrustedForwarder(newTrustedForwarder);
    }

    //@@inheritdoc
    function setAuthorizedRelayer(address newAuthorizedRelayer) external {
        if (newAuthorizedRelayer == address(0)) {
            revert Errors.ZeroAddress();
        }

        authorizedRelayer = newAuthorizedRelayer;
        emit SetAuthorizedRelayer(newAuthorizedRelayer);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    //@@inheritdoc IDoefinConfig
    function getApprovedToken(address token) public view returns (ApprovedToken memory) {
        return approvedTokens[token];
    }

    //@@inheritdoc IDoefinConfig
    function getFeeAddress() public view returns (address) {
        return feeAddress;
    }

    //@@inheritdoc IDoefinConfig
    function getBlockHeaderOracle() public view returns (address) {
        return blockHeaderOracle;
    }

    //@@inheritdoc IDoefinConfig
    function getOrderBook() public view returns (address) {
        return orderBook;
    }

    //@@inheritdoc IDoefinConfig
    function getTrustedForwarder() public view returns (address) {
        return trustedForwarder;
    }

    //@@inheritdoc IDoefinConfig
    function getAuthorizedRelayer() public view returns (address) {
        return authorizedRelayer;
    }
}
