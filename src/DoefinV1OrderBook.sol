// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Errors } from "./libraries/Errors.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC7390VanillaOption } from "./abstracts/ERC7390VanillaOption.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract DoefinV1OrderBook is ERC7390VanillaOption, ERC1155 {
    /**
     * @dev Struct to store essential details about a vanilla option.
     * @param data Struct storing essential details about a vanilla option.
     * @param isMatched Whether the option is matched by a counterparty.
     * @param writer The address that created the option.
     * @param counterparty The address of the counter party.
     * @param payOffAmount The fixed amount to pay if the condition is met
     * @param finalStrike The strike value of the bitcoin difficulty at settlement
     * @param isSettled Bool to determine whether a binary option is settled
     */
    struct BinaryOption {
        VanillaOptionData data;
        bool isMatched;
        address writer;
        address counterparty;
        uint256 payOffAmount;
        uint256 finalStrike;
        bool isSettled;
    }

    /// @notice The ERC20 token used as strike token in the trading pair
    IERC20 public immutable strikeToken;

    /// @notice The minimum strike token amount required for an order to be valid
    uint256 public immutable minStrikeTokenAmount;

    /// @dev The id of the next order to be created
    uint256 public orderIdCounter;

    /// @dev The mapping of id to option orders
    mapping(uint256 => BinaryOption) public orders;

    modifier onlyOptionsManager() {
        require(msg.sender == address(1));
        _;
    }

    constructor(address _strikeToken, uint256 _minStrikeTokenAmount) ERC1155("") {
        if (_minStrikeTokenAmount == 0) {
            revert Errors.OrderBook_InvalidMinStrikeAmount();
        }

        if (_strikeToken == address(0)) {
            revert Errors.ZeroAddress();
        }

        strikeToken = IERC20(_strikeToken);
        minStrikeTokenAmount = _minStrikeTokenAmount;
    }

    /**
     * @dev Struct to store essential details about a vanilla option.
     * @param strike The difficulty of BTC at a specified expiry
     * @param amount The amount of the underlying asset that the option covers.
     * @param expiry The timestamp from when the option can start to be exercised.
     * @param allowed Addresses that are allowed to buy the issuance. If the array is empty, all addresses are allowed
     *        to buy the issuance.
     */
    function createOrder(
        uint256 strike,
        uint256 amount,
        uint256 expiry,
        bool isLong,
        address[] memory allowed
    )
        public
        returns (uint256)
    {
        if (strike == 0) {
            revert Errors.OrderBook_ZeroStrike();
        }

        if (amount < minStrikeTokenAmount) {
            revert Errors.OrderBook_InvalidMinStrikeAmount();
        }

        if (expiry == 0 || expiry < block.timestamp) {
            revert Errors.OrderBook_ZeroExpiry();
        }

        VanillaOptionData memory optionData = VanillaOptionData({
            side: Side.Call,
            position: isLong ? Position.Long : Position.Short,
            underlyingToken: address(0),
            amount: amount,
            strikeToken: address(strikeToken),
            strike: strike,
            premiumToken: address(0),
            premium: 0,
            exerciseWindowStart: expiry,
            exerciseWindowEnd: 0,
            allowed: allowed
        });

        uint256 orderId = create(optionData);
        emit OrderCreated(orderId);
        return orderId;
    }

    //@@inheritdoc
    function create(VanillaOptionData memory optionData) public override returns (uint256) {
        uint256 newOrderId = orderIdCounter;
        BinaryOption memory newBinaryOption = BinaryOption({
            data: optionData,
            writer: msg.sender,
            counterparty: address(0),
            payOffAmount: optionData.amount,
            isMatched: false,
            finalStrike: 0,
            isSettled: false
        });

        IERC20(strikeToken).transferFrom(msg.sender, address(this), optionData.amount);
        _mint(msg.sender, newOrderId, 1, "");
        orders[newOrderId] = newBinaryOption;
        orderIdCounter++;

        return newOrderId;
    }

    /**
     * @dev Match a given order by a maker
     * @param orderId The order id of the order to match
     * @param amount The amount of the asset that the match option covers.
     */
    function matchOrder(uint256 orderId, uint256 amount) public {
        BinaryOption storage order = orders[orderId];
        if (block.timestamp > order.data.exerciseWindowStart) {
            revert Errors.OrderBook_MatchOrderExpired();
        }

        address[] memory allowed = order.data.allowed;
        if (allowed.length > 0) {
            bool isAllowed = false;
            for (uint256 i = 0; i < allowed.length; i++) {
                if (allowed[i] == msg.sender) {
                    isAllowed = true;
                }
            }

            if (!isAllowed) {
                revert Errors.OrderBook_MatchOrderNotAllowed();
            }
        }

        IERC20(strikeToken).transferFrom(msg.sender, address(this), amount);
        order.counterparty = msg.sender;
        order.payOffAmount += amount;
        order.isMatched = true;

        _mint(msg.sender, orderId, 1, "");
        _registerOrderForSettlement(orderId);
        emit OrderMatched(orderId, msg.sender, amount);
    }

    function exerciseOrder(uint256 orderId) public returns (uint256) {
        BinaryOption storage order = orders[orderId];
        if (block.timestamp < order.data.exerciseWindowStart) {
            revert Errors.OrderBook_NotWithinExerciseWindow();
        }

        //what happens when the tokens are transferred?
        _burn(order.writer, orderId, 1);
        _burn(order.counterparty, orderId, 1);

        if (
            order.data.position == Position.Long && order.finalStrike > order.data.strike
                || order.data.position == Position.Short && order.finalStrike < order.data.strike
        ) {
            IERC20(strikeToken).transfer(order.writer, order.payOffAmount);
        } else {
            IERC20(strikeToken).transfer(order.counterparty, order.payOffAmount);
        }

        emit OrderExercised(orderId, order.payOffAmount);
        return orderId;
    }

    /**
     * @dev Settle an order that has been for settlement in the options manager
     * @param orderId The order id of the order to match
     */
    function settleOrder(uint256 orderId) public onlyOptionsManager returns (bool) {
        //add integration logic for options manager
        return true;
    }

    /**
     * @dev Register an order for settlement in the options manager
     * @param orderId The order id of the order to match
     */
    function _registerOrderForSettlement(uint256 orderId) internal returns (bool) {
        //add integration logic for options manager
        return true;
    }

    function getOrder(uint256 orderId) public view returns (BinaryOption memory) {
        return orders[orderId];
    }
}
