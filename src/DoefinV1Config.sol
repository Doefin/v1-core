// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Errors } from "./libraries/Errors.sol";
import { IDoefinFactory } from "./interfaces/IDoefinFactory.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./DoefinV1OrderBook.sol";
import { DoefinV1OptionsManager } from "./DoefinV1OptionsManager.sol";

/// @title DoefinV1Factory
/// @notice See the documentation in {IDoefinFactory}.
contract DoefinV1Factory is IDoefinFactory, Ownable {
    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/
    mapping(address => ApprovedToken) public approvedTokens;
    mapping(address => OrderBook) public orderBooks;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Initializes the factor and it's owner contract
    constructor() Ownable() { }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    //@@inheritdoc IDoefinFactory
    function createOrderBook(
        address collateralToken,
        uint256 minCollateralTokenAmount,
        address optionsManager
    )
        external
        override
        onlyOwner
        returns (address orderBookAddress)
    {
        orderBookAddress = address(new DoefinV1OrderBook(collateralToken, optionsManager));
        orderBooks[orderBookAddress] = OrderBook(orderBookAddress);
        emit OrderBookCreated(orderBookAddress);
        return orderBookAddress;
    }

    //@@inheritdoc IDoefinFactory
    function createOptionsManager(
        address orderBook,
        address blockHeaderOracle,
        address optionsFeeAddress
    )
        external
        override
        onlyOwner
        returns (address optionsManagerAddress)
    {
        optionsManagerAddress = address(new DoefinV1OptionsManager(orderBook, blockHeaderOracle, optionsFeeAddress));
        emit OrderBookCreated(optionsManagerAddress);
        return optionsManagerAddress;
    }

    //@@inheritdoc IDoefinFactory
    function addTokenToApprovedList(address token, uint256 minCollateralTokenAmount) external override onlyOwner {
        if (token == address(0)) {
            revert Errors.ZeroAddress();
        }

        if (minCollateralTokenAmount == 0) {
            revert Errors.OrderBook_InvalidMinCollateralAmount(); //todo rename this error
        }

        approvedTokens[token] = ApprovedToken({
            token: IERC20(token),
            minCollateralTokenAmount: minCollateralTokenAmount
        });

        emit AddTokenToApprovedList(token);
    }

    //@@inheritdoc IDoefinFactory
    function removeTokenFromApprovedList(address token) external override onlyOwner {
        if (token == address(0)) {
            revert Errors.ZeroAddress();
        }

        delete approvedTokens[token];
        emit RemoveTokenFromApprovedList(token);
    }

    //@@inheritdoc IDoefinFactory
    function tokenIsInApprovedList(address token) external returns (bool) {
        return address(approvedTokens[token].token) != address(0);
    }


    //@@inheritdoc IDoefinFactory
    function getApprovedToken(address token) external view returns (ApprovedToken memory) {
        return approvedTokens[token];
    }
}
