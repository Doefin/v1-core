// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Adminable } from "./abstracts/Adminable.sol";
import { IAdminable } from "./interfaces/IAdminable.sol";
import { IDoefinFactory } from "./interfaces/IDoefinFactory.sol";

/// @title DoefinV1Factory
/// @notice See the documentation in {IDoefinFactory}.
contract DoefinV1Factory is IDoefinFactory, Adminable {
    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/


    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Emits a {TransferAdmin} event.
    /// @param initialAdmin The address of the initial contract admin.
    constructor(address initialAdmin) {
        admin = initialAdmin;
        emit IAdminable.TransferAdmin({ oldAdmin: address(0), newAdmin: initialAdmin });
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
}
