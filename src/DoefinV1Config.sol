// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import {Errors} from "./libraries/Errors.sol";
import {IDoefinConfig} from "./interfaces/IDoefinConfig.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {DoefinV1OptionsManager} from "./DoefinV1OptionsManager.sol";

/// @title DoefinV1Config
/// @notice See the documentation in {DoefinV1Config}.
contract DoefinV1Config is IDoefinConfig, Ownable {
    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/
    mapping(address => ApprovedToken) public approvedTokens;
    mapping(address => OrderBook) public orderBooks;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Initializes the factor and it's owner contract
    constructor() Ownable() {}

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    //@@inheritdoc IDoefinConfig
    function addTokenToApprovedList(address token, uint256 minCollateralAmount) external override onlyOwner {
        if (token == address(0)) {
            revert Errors.ZeroAddress();
        }

        if (minCollateralAmount == 0) {
            revert Errors.OrderBook_InvalidMinCollateralAmount(); //todo rename this error
        }

        approvedTokens[token] = ApprovedToken({token: IERC20(token), minCollateralAmount: minCollateralAmount});

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
    function tokenIsInApprovedList(address token) external returns (bool) {
        return address(approvedTokens[token].token) != address(0);
    }

    //@@inheritdoc IDoefinConfig
    function getApprovedToken(address token) external view returns (ApprovedToken memory) {
        return approvedTokens[token];
    }
}
