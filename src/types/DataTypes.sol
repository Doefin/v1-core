// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Namespace for the structs used in the options contracts
library OrderBookLib {
    /// @notice Struct defining vanilla option
//    struct VanillaOption {
//
//    }

    /// @notice Enum representing the different types of option.
    /// @custom:value0 PUT Stream created but not started; assets are in a pending state.
    /// @custom:value1 CALL Active stream where assets are currently being streamed.
    enum OptionType {
        PUT,
        CALL
    }
}
