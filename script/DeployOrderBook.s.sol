// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;
import { Lib } from "./Lib.sol";
import { console } from "forge-std/console.sol";

import { BaseScript } from "./Base.s.sol";
import { DoefinV1Config } from "../src/DoefinV1Config.sol";

import { BaseScript } from "./Base.s.sol";
import { DoefinV1OrderBook } from "../src/DoefinV1OrderBook.sol";
import { DoefinV1Config } from "../src/DoefinV1Config.sol";
import { Defender, DefenderOptions } from "openzeppelin-foundry-upgrades/Defender.sol";

contract DeployOrderBook is BaseScript {
    function run(address configAddress) public virtual returns (DoefinV1OrderBook orderBook) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        orderBook = new DoefinV1OrderBook(configAddress);
        DoefinV1Config(configAddress).setOrderBook(address(orderBook));

        vm.stopBroadcast();
    }

    function runWithDefender(address configAddress) public virtual returns (address blockHeaderOracle) {
        DefenderOptions memory opts;
        opts.salt = Lib._generateSalt(msg.sender);

        bytes memory constructorArgs = abi.encode(configAddress);
        blockHeaderOracle = Defender.deployContract("DoefinV1OrderBook.sol", constructorArgs, opts);
        console.log("Deployed contract to address: ", blockHeaderOracle);

        return blockHeaderOracle;
    }
}
