// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title IERC7390VanillaOption
 * @dev Interface for the ERC-7390 Vanilla Option Standard for creating, managing, and exercising vanilla options.
 * This interface allows for the interaction with financial derivatives known as vanilla options on Ethereum.
 */
interface IERC7390VanillaOption {
    /**
     * @dev Side of the option.
     */
    enum Side {
        Call,
        Put
    }

    /**
     * @dev Struct to store essential details about a vanilla option.
     * @param side The side of the option. Can take the value Call or Put
     * @param strike The strike price of the option in terms of the strike token.
     * @param amount The amount of the underlying asset that the option covers.
     * @param premium The premium price paid by the option holder to the writer.
     * @param exerciseWindowStart The timestamp from when the option can start to be exercised.
     * @param exerciseWindowEnd The timestamp after which the option can no longer be exercised.
     * @param underlyingToken The address of the token that the option is based on.
     * @param strikeToken The address of the token that is used to pay the strike price.
     * @param premiumToken The address of the token that is used to pay the premium.
     * @param allowed Addresses that are allowed to buy the issuance. If the array is empty, all addresses are allowed
     *        to buy the issuance.
     */
    struct VanillaOptionData {
        Side side;
        uint256 strike;
        uint256 amount;
        uint256 premium;
        uint256 exerciseWindowStart;
        uint256 exerciseWindowEnd;
        address underlyingToken;
        address strikeToken;
        address premiumToken;
        address[] allowed;
    }

    /**
     * @dev Struct to store essential details about a vanilla option.
     * @param data Struct storing essential details about a vanilla option.
     * @param writer The address that created the option.
     * @param exercisedAmount The amount of underlying tokens that have been exercised.
     * @param soldAmount The amount of underlying tokens that have been bought for this issuance.
     */
    struct OptionIssuance {
        VanillaOptionData data;
        address writer;
        uint256 exercisedAmount;
        uint256 soldAmount;
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
    event Created(uint256 indexed id);

    /// @notice Emitted when an option is bought.
    /// @param id The unique identifier of the option being bought.
    /// @param amount The amount of the option bought.
    /// @param buyer The address of the buyer.
    event Bought(uint256 indexed id, uint256 amount, address indexed buyer);

    /// @notice Emitted when an option is exercised.
    /// @param id The unique identifier of the option being exercised.
    /// @param amount The amount of the option exercised.
    event Exercised(uint256 indexed id, uint256 amount);

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
     * @notice Creates a new vanilla option.
     * @dev This function allows for the creation of a new option contract. The option specifics are passed in via the
     *      VanillaOptionData struct.
     * @param optionData The details of the option being created, including type, underlying, amounts, and time frames.
     * @return The unique identifier for the newly created option contract.
     */
    function create(VanillaOptionData calldata optionData) external returns (uint256);

    /**
     * @notice Buys a specified amount of an existing option.
     * @dev Allows a user to purchase part of an option issuance identified by `id`.
     * @param id The unique identifier of the option to buy.
     * @param amount The amount of the option to purchase.
     */
    function buy(uint256 id, uint256 amount) external;

    /**
     * @notice Exercises a specified amount of an existing option.
     * @dev Allows the holder of an option to exercise their rights as specified by the option's terms.
     * @param id The unique identifier of the option to exercise.
     * @param amount The amount of the option to exercise.
     */
    function exercise(uint256 id, uint256 amount) external;

    /**
     * @notice Retrieves unexercised tokens after an option has expired.
     * @dev This function is called by the option writer to retrieve tokens from an option that has expired without
     *      full exercise.
     * @param id The unique identifier of the expired option.
     * @param receiver The address where the unexercised tokens will be sent.
     */
    function retrieveExpiredTokens(uint256 id, address receiver) external;

    /**
     * @notice Cancels an option, returning the collateral to the writer.
     * @dev Can only be called by the writer or an authorized party to cancel the option and retrieve the collateral
     *      used to secure the option.
     * @param id The unique identifier of the option to cancel.
     * @param receiver The address where the collateral will be returned.
     */
    function cancel(uint256 id, address receiver) external;

    /**
     * @notice Updates the premium required to buy the option.
     * @dev Can only be performed by the option writer or an authorized party to adjust the option's premium cost.
     * @param id The unique identifier of the option to update.
     * @param amount The new premium amount to be set.
     */
    function updatePremium(uint256 id, uint256 amount) external;

    /**
     * @notice Updates the list of addresses allowed to buy the option.
     * @dev Can be used by the option writer to restrict or open the option buying to a list of addresses.
     * @param id The unique identifier of the option to update.
     * @param allowed An array of addresses that are allowed to purchase the option.
     */
    function updateAllowed(uint256 id, address[] memory allowed) external;

    /**
     * @notice Retrieves the details of a specific option issuance.
     * @dev Provides a way to access all details of a specific option issuance by its unique identifier.
     * @param id The unique identifier of the option.
     * @return The details of the option issuance in the form of the OptionIssuance struct.
     */
    function issuance(uint256 id) external view returns (OptionIssuance memory);

}
