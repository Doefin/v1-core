// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title IDoefinV1OrderBook
 * @dev Interface for the ERC-7390 Vanilla Option Standard for creating, managing, and exercising vanilla options.
 * This interface allows for the interaction with financial derivatives known as vanilla options on Ethereum.
 */
interface IDoefinV1OrderBook {
    /**
     * @dev Side of the option.
     */
    enum Position {
        Long,
        Short
    }

    /**
     * @dev Struct to store essential details about a vanilla option.
     * @param amount The amount of the underlying asset that the option covers.
     * @param position The position of the option. Can take the value Long or Short
     * @param strike The strike value of the option in terms of the strike token.
     * @param strikeToken The address of the token that is used to pay the strike price.
     * @param writer The address that created the option.
     * @param counterparty The address of the counter party.
     * @param payOffAmount The fixed amount to pay if the condition is met
     * @param finalStrike The strike value of the bitcoin difficulty at settlement
     * @param expiry The block number at which the strike is expected to be evaluated
     * @param isSettled Bool to determine whether a binary option is settled
     * @param exerciseWindowStart The timestamp from when the option can start to be exercised.
     * @param exerciseWindowEnd The timestamp after which the option can no longer be exercised.
     */
    struct BinaryOption {
        uint256 amount;
        Position position;
        address writer;
        uint256 initialStrike;
        uint256 finalStrike;
        address strikeToken;
        address counterparty;
        uint256 payOffAmount;
        uint256 expiry;
        bool isSettled;
        uint256 exerciseWindowStart;
        uint256 exerciseWindowEnd;
    }

    // Errors

    /// @notice Error thrown when an action is not allowed by the rules.
    error Forbidden();

    /// @notice Error thrown when a token transfer fails (e.g., due to a `transferFrom` or `transfer` call failing).
    error TransferFailed();

    /// @notice Error thrown when an action is attempted outside of the allowed time window.
    error TimeForbidden();

    /// @notice Error thrown when an invalid amount is used, such as zero or exceeding limits.
    error AmountForbidden();

    /// @notice Error thrown when the caller has insufficient balance to perform the action.
    error InsufficientBalance();

    // Events

    /// @notice Emitted when a new option is created.
    /// @param id The unique identifier of the created option.
    event OrderCreated(uint256 indexed id);

    /// @notice Emitted when a new option order is matched.
    /// @param id The unique identifier of the created option.
    /// @param counterparty The address of the counterparty
    /// @param amount The amount the counter party submitted
    event OrderMatched(uint256 indexed id, address indexed counterparty, uint256 indexed amount);

    /// @notice Emitted when an option is bought.
    /// @param id The unique identifier of the option being bought.
    /// @param amount The amount of the option bought.
    /// @param buyer The address of the buyer.
    event Bought(uint256 indexed id, uint256 amount, address indexed buyer);

    /// @notice Emitted when an option is exercised.
    /// @param id The unique identifier of the option being exercised.
    /// @param amount The amount of the option exercised.
    /// @param winner The winner of the bet.
    event OrderExercised(uint256 indexed id, uint256 amount, address winner);

    /// @notice Emitted when the tokens from an expired option are retrieved by the writer.
    /// @param id The unique identifier of the option that has expired.
    event Expired(uint256 indexed id);

    /// @notice Emitted when an option is canceled by the writer.
    /// @param id The unique identifier of the canceled option.
    event Canceled(uint256 indexed id);

    /// @notice Emitted when the premium of an option is updated.
    /// @param id The unique identifier of the option whose premium is updated.
    /// @param amount The new premium amount.
    event PremiumUpdated(uint256 indexed id, uint256 amount);

    /// @notice Emitted when the list of allowed addresses for buying an option is updated.
    /// @param id The unique identifier of the option whose allowed list is updated.
    /// @param allowed The new list of addresses that are allowed to buy the option.
    event AllowedUpdated(uint256 indexed id, address[] allowed);

    // Interface methods

    /**
     * @dev Struct to store essential details about a vanilla option.
     * @param strike The difficulty of BTC at a specified expiry
     * @param amount The amount of the underlying asset that the option covers.
     * @param expiry The block number at which the strike is expected to be evaluated
     * @param allowed Addresses that are allowed to buy the issuance. If the array is empty, all addresses are allowed
     *        to buy the issuance.
     */
    function createOrder(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address allowed
    )
        external
        returns (uint256);

    /**
     * @dev Match a given order by a maker
     * @param orderId The order id of the order to match
     * @param amount The amount of the asset that the match option covers.
     */
    function matchOrder(uint256 orderId, uint256 amount) external;

    /**
     * @notice Exercises a specified amount of an existing option.
     * @dev Allows the holder of an option to exercise their rights as specified by the option's terms.
     * @param orderId The unique identifier of the option to exercise.
     */
    function exerciseOrder(uint256 orderId) external returns (uint256);

    /**
     * @dev Settle an order that has been registered for settlement in the options manager
     * @param orderId The order id of the order to match
     * @param blockNumber The number at which an order can be settled
     * @param difficulty The difficulty at the specified block number
     */
    function settleOrder(uint256 orderId, uint256 blockNumber, uint256 difficulty) external returns (bool);

    /**
     * @dev Get Binary options order
     * @param orderId The order id of the order to fetch
     */
    function getOrder(uint256 orderId) external view returns (BinaryOption memory);
}
