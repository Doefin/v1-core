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
    mapping(address => bool) public approvedTokensList;
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
        orderBookAddress = address(new DoefinV1OrderBook(collateralToken, minCollateralTokenAmount, optionsManager));
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
    function addTokenToApprovedList(address token) external override onlyOwner {
        if (token == address(0)) {
            revert Errors.ZeroAddress();
        }

        approvedTokensList[token] = true;
        emit AddTokenToApprovedList(token);
    }

    //@@inheritdoc IDoefinFactory
    function removeTokenFromApprovedList(address token) external override onlyOwner {
        if (token == address(0)) {
            revert Errors.ZeroAddress();
        }

        delete approvedTokensList[token];
        emit RemoveTokenFromApprovedList(token);
    }

    //@@inheritdoc IDoefinFactory
    function getOrderBook(address orderBookAddress) external view returns (OrderBook memory) {
        return orderBooks[orderBookAddress];
    }
}
