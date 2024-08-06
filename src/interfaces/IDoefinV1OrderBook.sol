// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title IDoefinV1OrderBook
 * @dev Interface for the ERC-7390 Vanilla Option Standard for creating, managing, and exercising vanilla options.
 * This interface allows for the interaction with financial derivatives known as vanilla options on Ethereum.
 */
interface IDoefinV1OrderBook {
    /// @notice Side of the option.
    enum Position {
        Call,
        Put
    }

    /// @notice The expiry type of the order to be created
    enum ExpiryType {
        BlockNumber,
        Timestamp
    }

    // @notice The status of the option
    enum Status {
        Pending,
        Matched,
        Settled,
        Exercised,
        Canceled
    }

    /**
     * @param callPremium The premium the protocol takes for the call position
     * @param putPremium The premium the protocol takes for the put position
     * @param notional The notional value of the option
     */
    struct Premiums {
        uint256 makerPremium;
        uint256 takerPremium;
        uint256 notional;
    }

    /**
     * @param makerPosition The position of maker of the option. Can take the value Call or Put
     * @param takerPosition The position of taker of the option. Can take the value Call or Put
     */
    struct Positions {
        Position makerPosition;
        Position takerPosition;
    }

    /**
     * @dev Struct to store essential details about a binary option.
     * @param status The status of the option. It can take values: Pending, Matched, Settled, Exercised, Canceled
     * @param strike The strike value of the option in terms of the strike token.
     * @param collateralToken The address of the token that is used to pay the strike price.
     * @param counterparty The address of the counter party.
     * @param payOutAmount The fixed amount to pay if the condition is met
     * @param finalStrike The strike value of the bitcoin difficulty at settlement
     * @param expiry The block number at which the strike is expected to be evaluated
     * @param expiryType The expiry type of the order to be created {BlockNumber or Timestamp}
     * @param exerciseWindowStart The timestamp from when the option can start to be exercised.
     * @param exerciseWindowEnd The timestamp after which the option can no longer be exercised.
     * @param allowed Addresses that are allowed to buy the issuance. If the array is empty, all addresses are allowed
     *        to buy the issuance.
     */
    struct Metadata {
        Status status;
        address maker;
        address taker;
        address collateralToken;
        uint256 initialStrike;
        uint256 finalStrike;
        uint256 payOut;
        uint256 expiry;
        ExpiryType expiryType;
        uint256 exerciseWindowStart;
        uint256 exerciseWindowEnd;
        address[] allowed;
    }

    /**
     * @dev Struct to store essential details about a binary option.
     * @param premium The struct of the option premium
     * @param positions The struct of the position of the maker and taker
     * @param metadata The metadata struct of the option
     */
    struct BinaryOption {
        Premiums premiums;
        Positions positions;
        Metadata metadata;
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
    event OrderCanceled(uint256 indexed id);

    /// @notice Emitted when the premium of an option is updated.
    /// @param id The unique identifier of the option whose premium is updated.
    /// @param premium The new premium amount.
    event PremiumUpdated(uint256 indexed id, uint256 premium);

    /// @notice Emitted when premium is increased
    /// @param id The order id
    /// @param premium The new premium to add
    event PremiumIncreased(uint256 indexed id, uint256 premium);

    /// @notice Emitted when premium is decreased
    /// @param id The order id
    /// @param premium The new premium to decrease
    event PremiumDecreased(uint256 indexed id, uint256 premium);

    /// @notice Emitted when a maker's order position is updated
    /// @param id The order id
    /// @param position The maker's new position
    event OrderPositionUpdated(uint256 indexed id, Position position);

    /// @notice Emitted when the order's expiry and expiry type are updated
    /// @param id The order id
    /// @param expiry The new expiry of the order
    /// @param expiryType The new expiry type of the order
    event OrderExpiryUpdated(uint256 indexed id, uint256 expiry, ExpiryType expiryType);

    /// @notice Emitted when the order's allowed list is updated
    /// @param id The order id
    /// @param allowed The new allowed list of the order
    event OrderAllowedListUpdated(uint256 indexed id, address[] allowed);

    /// @notice Emitted when the order's strike is updated
    /// @param id The order id
    /// @param strike The new strike of the order
    event OrderStrikeUpdated(uint256 indexed id, uint256 strike);

    // Interface methods

    /**
     * @dev Struct to store essential details about a vanilla option.
     * @param strike The difficulty of BTC at a specified expiry
     * @param premium The premium of the option
     * @param premium The notional of the option
     * @param expiry The block number or timestamp at which the strike is expected to be evaluated
     * @param expiryType The expiry type of the order to be created
     * @param position The position of the maker of the order
     * @param collateralToken The collateral token the order is created in
     * @param allowed Addresses that are allowed to buy the issuance. If the array is empty, all addresses are allowed
     *        to buy the issuance.
     */
    function createOrder(
        uint256 strike,
        uint256 premium,
        uint256 notional,
        uint256 expiry,
        ExpiryType expiryType,
        Position position,
        address collateralToken,
        address[] calldata allowed
    )
    external
    returns (uint256);

    /**
     * @dev Match a given order by a maker
     * @param orderId The order id of the order to match
     */
    function matchOrder(uint256 orderId) external;

    /**
     * @dev Cancel an existing order
     * @param orderId The order id of the order to cancel
     */
    function cancelOrder(uint256 orderId) external;

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
     * @param timestamp The timestamp of the block at which an order can be settled
     * @param difficulty The difficulty at the specified block number
     */
    function settleOrder(
        uint256 orderId,
        uint256 blockNumber,
        uint256 timestamp,
        uint256 difficulty
    )
        external
        returns (bool);

    /**
     * @dev Get Binary options order
     * @param orderId The order id of the order to fetch
     */
    function getOrder(uint256 orderId) external view returns (BinaryOption memory);
}
