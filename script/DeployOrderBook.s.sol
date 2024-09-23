// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

import { BaseScript } from "./Base.s.sol";
import { DoefinV1Config } from "../src/DoefinV1Config.sol";

import { BaseScript } from "./Base.s.sol";
import { DoefinV1OrderBook } from "../src/DoefinV1OrderBook.sol";
import { DoefinV1Config } from "../src/DoefinV1Config.sol";

contract DeployOrderBook is BaseScript {
    function run(address configAddress) public virtual returns (DoefinV1OrderBook orderBook) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        orderBook = new DoefinV1OrderBook(configAddress);
        DoefinV1Config(configAddress).setOrderBook(address(orderBook));

        vm.stopBroadcast();
    }
}
