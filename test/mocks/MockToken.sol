// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "DMT") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount * 10 ** decimals());
    }
}
