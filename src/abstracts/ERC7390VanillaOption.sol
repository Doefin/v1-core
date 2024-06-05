// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC7390VanillaOption } from "../interfaces/IERC7390VanillaOption.sol";

abstract contract ERC7390VanillaOption is IERC7390VanillaOption {
    //@inheritdoc
    function create(VanillaOptionData memory optionData) public virtual returns (uint256) { }

    //@@inheritdoc
    function buy(uint256 id, uint256 amount) public { }

    //@@inheritdoc
    function exercise(uint256 id, uint256 amount) public { }

    //@@inheritdoc
    function retrieveExpiredTokens(uint256 id, address receiver) public { }

    //@@inheritdoc
    function cancel(uint256 id, address receiver) public { }

    //@@inheritdoc
    function updatePremium(uint256 id, uint256 amount) public { }

    //@@inheritdoc
    function updateAllowed(uint256 id, address[] memory allowed) public { }

    //@@inheritdoc
    function issuance(uint256 id) public view returns (OptionIssuance memory) { }
}
