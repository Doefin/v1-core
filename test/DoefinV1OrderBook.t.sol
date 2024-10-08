// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { IERC20, Base_Test } from "./Base.t.sol";
import { Test } from "forge-std/Test.sol";
import { Errors, DoefinV1OrderBook, IDoefinV1OrderBook, Ownable } from "../src/DoefinV1OrderBook.sol";
import { DoefinV1BlockHeaderOracle } from "../src/DoefinV1BlockHeaderOracle.sol";

/// @title DoefinV1OrderBook_Test
contract DoefinV1OrderBook_Test is Base_Test {
    DoefinV1OrderBook public orderBook;
    DoefinV1BlockHeaderOracle public blockHeaderOracle;
    address public collateralToken;
    uint256 public constant minCollateralAmount = 100;
    uint256 public constant depositBound = 5000e6;

    function setUp() public virtual override {
        Base_Test.setUp();
        Base_Test.deployConfig();

        collateralToken = address(dai);
        blockHeaderOracle = new DoefinV1BlockHeaderOracle(setupInitialBlocks(), 838_886, address(config));

        config.setFeeAddress(users.feeAddress);
        config.setBlockHeaderOracle(address(blockHeaderOracle));
        orderBook = new DoefinV1OrderBook(address(config));

        config.setOrderBook(address(orderBook));
    }

    /*//////////////////////////////////////////////////////////////
                      CREATE ORDER
    //////////////////////////////////////////////////////////////*/

    function testFail__createOrderWithZeroStrike(
        uint256 strike,
        uint256 premium,
        uint256 expiry,
        address counterparty
    )
        public
    {
        vm.assume(strike == 0);
        vm.assume(expiry != 0);
        vm.assume(counterparty != address(0));
        vm.assume(premium >= minCollateralAmount);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        orderBook.createOrder(createOrderInput);
    }

    function testFail__createOrderWithAmountLessThanMinStrike(
        uint256 strike,
        uint256 premium,
        uint256 expiry,
        address counterparty
    )
        public
    {
        vm.assume(strike != 0);
        vm.assume(expiry != 0);
        vm.assume(counterparty != address(0));
        vm.assume(premium < minCollateralAmount);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        orderBook.createOrder(createOrderInput);
    }

    function testFail__createOrderWithZeroExpiry(
        uint256 strike,
        uint256 premium,
        uint256 expiry,
        address counterparty
    )
        public
    {
        vm.assume(strike != 0);
        vm.assume(expiry == 0);
        vm.assume(counterparty != address(0));
        vm.assume(premium >= minCollateralAmount);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        orderBook.createOrder(createOrderInput);
    }

    function testFail__TransferTokenAfterCreateOrder(
        uint256 strike,
        uint256 premium,
        uint256 expiry,
        address counterparty
    )
        public
    {
        vm.assume(strike != 0);
        vm.assume(expiry != 0);
        vm.assume(counterparty != address(0));
        vm.assume(premium >= minCollateralAmount && premium <= depositBound);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        uint256 orderId = orderBook.createOrder(createOrderInput);

        orderBook.safeTransferFrom(users.alice, users.broker, orderId, 1, "");
    }

    function test__createOrder(uint256 strike, uint256 premium, uint256 expiry, address counterparty) public {
        vm.assume(strike != 0);
        vm.assume(expiry != 0);
        vm.assume(counterparty != address(0));
        vm.assume(premium >= minCollateralAmount && premium <= depositBound);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderCreated(0);

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        uint256 orderId = orderBook.createOrder(createOrderInput);

        assertEq(orderBook.balanceOf(users.alice, orderId), 1);
    }

    function test__createAndMatchOrder(uint256 strike, uint256 premium, uint256 expiry, address counterparty) public {
        vm.assume(strike != 0);
        vm.assume(expiry != 0);
        vm.assume(counterparty != address(0));
        vm.assume(premium >= minCollateralAmount && premium <= depositBound);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](0);

        IDoefinV1OrderBook.CreateAndMatchOrderInput memory matchedOrder = IDoefinV1OrderBook.CreateAndMatchOrderInput({
            maker: users.alice,
            taker: users.james,
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            allowed: allowed
        });

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);
        vm.stopBroadcast();

        vm.startBroadcast(users.james);
        dai.approve(address(orderBook), premium);
        vm.stopBroadcast();

        vm.expectRevert("Caller is not an authorized relayer");
        orderBook.createAndMatchOrder(matchedOrder);

        vm.startBroadcast(users.relayer);
        matchedOrder.strike = 0;
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_ZeroStrike.selector));
        orderBook.createAndMatchOrder(matchedOrder);
        matchedOrder.strike = strike;
        vm.stopBroadcast();

        vm.startBroadcast(users.relayer);
        matchedOrder.collateralToken = address(0);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_InvalidCollateralToken.selector));
        orderBook.createAndMatchOrder(matchedOrder);
        matchedOrder.collateralToken = collateralToken;
        vm.stopBroadcast();

        vm.startBroadcast(users.relayer);
        matchedOrder.premium = minCollateralAmount - 10;
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_InvalidMinCollateralAmount.selector));
        orderBook.createAndMatchOrder(matchedOrder);
        matchedOrder.premium = premium;
        vm.stopBroadcast();

        vm.startBroadcast(users.relayer);
        matchedOrder.expiry = 0;
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_ZeroExpiry.selector));
        orderBook.createAndMatchOrder(matchedOrder);
        matchedOrder.expiry = expiry;
        vm.stopBroadcast();

        vm.startBroadcast(users.relayer);
        matchedOrder.notional = 0;
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_InvalidNotional.selector));
        orderBook.createAndMatchOrder(matchedOrder);
        matchedOrder.notional = notional;
        vm.stopBroadcast();

        uint256 feeBalBefore = IERC20(matchedOrder.collateralToken).balanceOf(users.feeAddress);

        vm.startBroadcast(users.relayer);
        uint256 orderId = orderBook.createAndMatchOrder(matchedOrder);
        assertEq(orderBook.balanceOf(matchedOrder.maker, orderId), 1);
        assertEq(orderBook.balanceOf(matchedOrder.taker, orderId), 1);
        vm.stopBroadcast();

        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        uint256 orderBookBalAfter = IERC20(order.metadata.collateralToken).balanceOf(address(orderBook));

        assertEq(order.metadata.taker, matchedOrder.taker);
        assertEq(order.metadata.payOut, order.premiums.notional - (order.premiums.notional / 100));

        assertEq(
            IERC20(order.metadata.collateralToken).balanceOf(users.feeAddress) - feeBalBefore,
            order.premiums.notional - order.metadata.payOut
        );
        assertEq(order.premiums.takerPremium + order.premiums.makerPremium, order.premiums.notional);
    }

    function test__CancelOrder(uint256 strike, uint256 premium, uint256 expiry, address counterparty) public {
        vm.assume(strike != 0);
        vm.assume(expiry != 0);
        vm.assume(counterparty != address(0));
        vm.assume(premium >= minCollateralAmount && premium <= depositBound);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = users.broker;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderCreated(0);

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        uint256 orderId = orderBook.createOrder(createOrderInput);

        vm.stopBroadcast();

        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);

        // Revert if caller is not maker
        vm.startBroadcast(users.james);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_CallerNotMaker.selector));
        orderBook.cancelOrder(orderId);
        vm.stopBroadcast();

        //Match order
        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), premium);
        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

        // Revert if order is not pending
        vm.startBroadcast(users.alice);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_OrderMustBePending.selector));
        orderBook.cancelOrder(orderId);
        vm.stopBroadcast();

        // Cancel an order
        vm.startBroadcast(users.admin);
        dai.approve(address(orderBook), premium);
        orderId = orderBook.createOrder(createOrderInput);

        order = orderBook.getOrder(orderId);
        uint256 makerPrevBalance = IERC20(order.metadata.collateralToken).balanceOf(order.metadata.maker);

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderCanceled(orderId);
        emit IDoefinV1OrderBook.OrderDeleted(orderId);
        orderBook.cancelOrder(orderId);

        uint256 makerCurrBalance = IERC20(order.metadata.collateralToken).balanceOf(order.metadata.maker);

        assertEq(makerCurrBalance - makerPrevBalance, order.premiums.makerPremium);
        assertEq(orderBook.balanceOf(order.metadata.maker, 1), 0);
        vm.stopBroadcast();
    }

    function test__UpdateOrder(uint256 strike, uint256 premium, uint256 expiry, address counterparty) public {
        vm.assume(strike != 0);
        vm.assume(expiry != 0);
        vm.assume(counterparty != address(0));
        vm.assume(premium >= minCollateralAmount && premium <= depositBound);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        uint256 orderId = orderBook.createOrder(createOrderInput);

        // Prepare update parameters
        IDoefinV1OrderBook.UpdateOrder memory updateParams;
        updateParams.notional = notional + (notional / 10); // Increase notional by 10%
        updateParams.premium = premium + (premium / 20); // Increase premium by 5%
        updateParams.position = IDoefinV1OrderBook.Position.Above;
        updateParams.expiry = 10;
        updateParams.expiryType = IDoefinV1OrderBook.ExpiryType.Timestamp;
        address[] memory newAllowed = new address[](2);
        newAllowed[0] = users.broker;
        newAllowed[1] = users.james;
        updateParams.allowed = newAllowed;
        updateParams.strike = 100;

        dai.approve(address(orderBook), uint256(updateParams.premium));

        vm.expectEmit();
        emit IDoefinV1OrderBook.NotionalIncreased(orderId, updateParams.notional);
        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderPositionUpdated(orderId, updateParams.position);
        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderExpiryUpdated(orderId, updateParams.expiry, updateParams.expiryType);
        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderAllowedListUpdated(orderId, updateParams.allowed);
        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderStrikeUpdated(orderId, updateParams.strike);
        vm.expectEmit();
        emit IDoefinV1OrderBook.PremiumIncreased(orderId, updateParams.premium);

        orderBook.updateOrder(orderId, updateParams);

        IDoefinV1OrderBook.BinaryOption memory updatedOrder = orderBook.getOrder(orderId);
        assertEq(updatedOrder.premiums.notional, updateParams.notional);
        assertEq(updatedOrder.premiums.makerPremium, updateParams.premium);
        assertEq(uint8(updatedOrder.positions.makerPosition), uint8(updateParams.position));
        assertEq(updatedOrder.metadata.expiry, updateParams.expiry);
        assertEq(uint8(updatedOrder.metadata.expiryType), uint8(updateParams.expiryType));
        assertEq(updatedOrder.metadata.allowed.length, updateParams.allowed.length);
        assertEq(updatedOrder.metadata.allowed[0], updateParams.allowed[0]);
        assertEq(updatedOrder.metadata.allowed[1], updateParams.allowed[1]);
        assertEq(updatedOrder.metadata.initialStrike, updateParams.strike);

        vm.stopBroadcast();

        // Revert if caller is not maker
        vm.startBroadcast(users.james);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_CallerNotMaker.selector));
        orderBook.updateOrder(orderId, updateParams);
        vm.stopBroadcast();

        // Revert if notional is invalid
        updateParams.notional -= notional; // This will make makerPremium >= notional
        vm.startBroadcast(users.alice);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_InvalidNotional.selector));
        orderBook.updateOrder(orderId, updateParams);
        vm.stopBroadcast();

        //Match order
        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), premium);
        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

        // Revert if order is not pending
        vm.startBroadcast(users.alice);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_OrderMustBePending.selector));
        orderBook.updateOrder(orderId, updateParams);
        vm.stopBroadcast();
    }

    function test__UpdateOrderDecreasePremiumAndNotional(
        uint256 strike,
        uint256 premium,
        uint256 expiry,
        address counterparty
    )
        public
    {
        vm.assume(strike != 0);
        vm.assume(expiry != 0);
        vm.assume(counterparty != address(0));
        vm.assume(premium >= minCollateralAmount * 2 && premium <= depositBound);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        uint256 orderId = orderBook.createOrder(createOrderInput);

        vm.stopBroadcast();

        // Prepare update parameters
        IDoefinV1OrderBook.UpdateOrder memory updateParams;
        updateParams.notional = notional - (notional / 10); // Decrease notional by 10%
        updateParams.premium = premium - (premium / 2); // Decrease premium by 20%
        updateParams.position = IDoefinV1OrderBook.Position.Above;
        updateParams.expiry = 10;
        updateParams.expiryType = IDoefinV1OrderBook.ExpiryType.Timestamp;
        address[] memory newAllowed = new address[](2);
        newAllowed[0] = users.broker;
        newAllowed[1] = users.james;
        updateParams.allowed = newAllowed;
        updateParams.strike = 100;

        vm.startBroadcast(users.alice);
        vm.expectEmit();
        emit IDoefinV1OrderBook.NotionalDecreased(orderId, updateParams.notional);
        vm.expectEmit();
        emit IDoefinV1OrderBook.PremiumDecreased(orderId, updateParams.premium);
        orderBook.updateOrder(orderId, updateParams);

        IDoefinV1OrderBook.BinaryOption memory updatedOrder = orderBook.getOrder(orderId);
        assertEq(updatedOrder.premiums.notional, updateParams.notional);
        assertEq(updatedOrder.premiums.makerPremium, updateParams.premium);
        vm.stopBroadcast();
    }

    /*//////////////////////////////////////////////////////////////
                  MATCH ORDER
    //////////////////////////////////////////////////////////////*/

    function testFail__matchOrderAfterExpiry(
        uint256 strike,
        uint256 premium,
        uint256 expiry,
        address counterparty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(counterparty != address(0));
        vm.assume(premium >= minCollateralAmount && premium <= depositBound);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        uint256 orderId = orderBook.createOrder(createOrderInput);

        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        vm.warp(block.timestamp + 3 days);
        dai.approve(address(orderBook), premium);
        orderBook.matchOrder(orderId);
        vm.stopBroadcast();
    }

    function testFail__matchOrderWithCounterPartyNotAllowed(
        uint256 strike,
        uint256 premium,
        uint256 expiry,
        address counterparty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(counterparty != address(0) && counterparty != users.broker);
        vm.assume(premium >= minCollateralAmount && premium <= depositBound);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        uint256 orderId = orderBook.createOrder(createOrderInput);

        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), premium);
        orderBook.matchOrder(orderId);
        vm.stopBroadcast();
    }

    function testFail__TransferTokenAfterMatchOrder(
        uint256 strike,
        uint256 premium,
        uint256 expiry,
        address counterparty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(counterparty != address(0));
        vm.assume(premium >= minCollateralAmount && premium <= depositBound);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = users.broker;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        uint256 orderId = orderBook.createOrder(createOrderInput);

        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), premium);

        orderBook.matchOrder(orderId);
        orderBook.safeTransferFrom(users.broker, users.alice, orderId, 1, "");
        vm.stopBroadcast();
    }

    function test__matchOrderWithEmptyAllowedList(uint256 strike, uint256 premium, uint256 expiry) public {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(premium >= minCollateralAmount && premium <= depositBound);

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](0);

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        uint256 orderId = orderBook.createOrder(createOrderInput);

        vm.stopBroadcast();
        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), premium);

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderMatched(
            orderId, users.broker, order.premiums.notional - order.premiums.makerPremium
        );

        uint256 feeBalBefore = IERC20(order.metadata.collateralToken).balanceOf(users.feeAddress);
        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

        order = orderBook.getOrder(orderId);
        uint256 orderBookBalAfter = IERC20(order.metadata.collateralToken).balanceOf(address(orderBook));

        assertEq(order.metadata.taker, users.broker);
        assertEq(order.metadata.payOut, order.premiums.notional - (order.premiums.notional / 100));

        assertEq(orderBook.balanceOf(users.broker, orderId), 1);
        assertEq(
            IERC20(order.metadata.collateralToken).balanceOf(users.feeAddress) - feeBalBefore,
            order.premiums.notional - order.metadata.payOut
        );
        assertEq(order.premiums.takerPremium + order.premiums.makerPremium, order.premiums.notional);
    }

    function test__FailToMatchOrderWhenOrderIsAlreadyMatched(
        uint256 strike,
        uint256 premium,
        uint256 expiry,
        address counterparty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(premium >= minCollateralAmount && premium <= depositBound);
        vm.assume(counterparty == users.rick || counterparty == users.james);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](3);
        allowed[0] = users.broker;
        allowed[1] = users.rick;
        allowed[2] = users.james;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        uint256 orderId = orderBook.createOrder(createOrderInput);

        vm.stopBroadcast();

        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), premium);

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderMatched(
            orderId, users.broker, order.premiums.notional - order.premiums.makerPremium
        );

        uint256 feeBalBefore = IERC20(order.metadata.collateralToken).balanceOf(users.feeAddress);
        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

        vm.startBroadcast(counterparty);
        dai.approve(address(orderBook), premium);

        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_OrderMustBePending.selector));
        orderBook.matchOrder(orderId);
        vm.stopBroadcast();
    }

    function test__matchOrderWithNonEmptyAllowedList(
        uint256 strike,
        uint256 premium,
        uint256 expiry,
        address counterparty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(premium >= minCollateralAmount && premium <= depositBound);
        vm.assume(counterparty == users.broker || counterparty == users.rick || counterparty == users.james);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](3);
        allowed[0] = users.broker;
        allowed[1] = users.rick;
        allowed[2] = users.james;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        uint256 orderId = orderBook.createOrder(createOrderInput);

        vm.stopBroadcast();

        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);

        vm.startBroadcast(counterparty);
        dai.approve(address(orderBook), premium);

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderMatched(
            orderId, counterparty, order.premiums.notional - order.premiums.makerPremium
        );

        uint256 feeBalBefore = IERC20(order.metadata.collateralToken).balanceOf(users.feeAddress);
        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

        order = orderBook.getOrder(orderId);
        uint256 orderBookBalAfter = IERC20(order.metadata.collateralToken).balanceOf(address(orderBook));

        assertEq(order.metadata.taker, counterparty);
        assertEq(order.metadata.payOut, order.premiums.notional - (order.premiums.notional / 100));

        assertEq(orderBook.balanceOf(counterparty, orderId), 1);
        assertEq(
            IERC20(order.metadata.collateralToken).balanceOf(users.feeAddress) - feeBalBefore,
            order.premiums.notional - order.metadata.payOut
        );
        assertEq(order.premiums.takerPremium + order.premiums.makerPremium, order.premiums.notional);
    }

    /*//////////////////////////////////////////////////////////////
              EXERCISE ORDER
    //////////////////////////////////////////////////////////////*/
    function testFail__exerciseOrderWhenOrderIsNotSettled(
        uint256 strike,
        uint256 premium,
        uint256 expiry,
        address counterparty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(counterparty != address(0));
        vm.assume(premium >= minCollateralAmount && premium <= depositBound);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = users.broker;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        uint256 orderId = orderBook.createOrder(createOrderInput);

        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), premium);

        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

        orderBook.exerciseOrder(orderId);
    }

    function test__exerciseOrderWhenExpiryIsBlockNumber(
        uint256 strike,
        uint256 premium,
        uint256 expiry,
        uint256 timestamp,
        address counterparty,
        uint256 blockNumber,
        uint256 difficulty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(timestamp != 0);
        vm.assume(counterparty != address(0));
        vm.assume(blockNumber > expiry);
        vm.assume(premium >= minCollateralAmount && premium <= depositBound);

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = users.broker;

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.BlockNumber,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        uint256 orderId = orderBook.createOrder(createOrderInput);

        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), premium);

        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

        vm.startBroadcast(orderBook.blockHeaderOracle());
        orderBook.settleOrder(blockNumber, timestamp, difficulty);
        vm.stopBroadcast();

        address winner;
        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        if (order.metadata.finalStrike > order.metadata.initialStrike) {
            if (order.positions.makerPosition == IDoefinV1OrderBook.Position.Above) {
                winner = order.metadata.maker;
            } else {
                winner = order.metadata.taker;
            }
        } else if (order.metadata.finalStrike < order.metadata.initialStrike) {
            if (order.positions.makerPosition == IDoefinV1OrderBook.Position.Below) {
                winner = order.metadata.maker;
            } else {
                winner = order.metadata.taker;
            }
        }

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderExercised(orderId, order.metadata.payOut, winner);
        orderBook.exerciseOrder(orderId);
    }

    function test__exerciseOrderWhenExpiryIsTimestamp(
        uint256 strike,
        uint256 premium,
        uint256 expiry,
        uint256 timestamp,
        address counterparty,
        uint256 blockNumber,
        uint256 difficulty
    )
        public
    {
        uint256 expiry = block.timestamp + 2 days;

        vm.assume(strike != 0);
        vm.assume(timestamp > expiry);
        vm.assume(counterparty != address(0));
        vm.assume(blockNumber != 0);
        vm.assume(premium >= minCollateralAmount && premium <= depositBound);

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = users.broker;

        IDoefinV1OrderBook.CreateOrderInput memory createOrderInput = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: IDoefinV1OrderBook.ExpiryType.Timestamp,
            position: IDoefinV1OrderBook.Position.Below,
            collateralToken: collateralToken,
            deadline: 1 days,
            allowed: allowed
        });

        uint256 orderId = orderBook.createOrder(createOrderInput);

        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), premium);

        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

        vm.startBroadcast(orderBook.blockHeaderOracle());
        orderBook.settleOrder(blockNumber, timestamp, difficulty);
        vm.stopBroadcast();

        address winner;
        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        if (order.metadata.finalStrike > order.metadata.initialStrike) {
            if (order.positions.makerPosition == IDoefinV1OrderBook.Position.Above) {
                winner = order.metadata.maker;
            } else {
                winner = order.metadata.taker;
            }
        } else if (order.metadata.finalStrike < order.metadata.initialStrike) {
            if (order.positions.makerPosition == IDoefinV1OrderBook.Position.Below) {
                winner = order.metadata.maker;
            } else {
                winner = order.metadata.taker;
            }
        }

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderExercised(orderId, orderBook.getOrder(orderId).metadata.payOut, winner);
        orderBook.exerciseOrder(orderId);
    }

    function test_DeleteOrders_OnlyOwnerCanCall() public {
        vm.prank(users.alice);
        vm.expectRevert(Ownable.Unauthorized.selector);
        orderBook.deleteOrders();
    }

    function test_DeleteOrders_DeletesExpiredUnmatchedOrders() public {
        uint256 currentBlockNumber = blockHeaderOracle.currentBlockHeight(); //().blockNumber;
        uint256 currentTimestamp = block.timestamp;

        // Create an expired order (by block number)
        uint256 orderId1 = _createOrder(
            users.alice,
            1000,
            minCollateralAmount,
            minCollateralAmount * 2,
            currentBlockNumber - 1,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Above,
            currentTimestamp + 1 hours
        );

        // Create an expired order (by timestamp)
        uint256 orderId2 = _createOrder(
            users.james,
            2000,
            minCollateralAmount,
            minCollateralAmount * 2,
            currentTimestamp,
            IDoefinV1OrderBook.ExpiryType.Timestamp,
            IDoefinV1OrderBook.Position.Below,
            currentTimestamp + 1 hours
        );

        // Create a non-expired order
        uint256 orderId3 = _createOrder(
            users.alice,
            3000,
            minCollateralAmount,
            minCollateralAmount * 2,
            currentBlockNumber + 100,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Above,
            currentTimestamp + 1 hours
        );

        vm.warp(100);
        vm.prank(address(this));
        orderBook.deleteOrders();

        // Verify deleted orders
        IDoefinV1OrderBook.BinaryOption memory deletedOrder1 = orderBook.getOrder(orderId1);
        assertEq(uint256(deletedOrder1.metadata.status), 0);

        IDoefinV1OrderBook.BinaryOption memory deletedOrder2 = orderBook.getOrder(orderId2);
        assertEq(uint256(deletedOrder2.metadata.status), 0);

        // Verify non-deleted order
        IDoefinV1OrderBook.BinaryOption memory nonDeletedOrder = orderBook.getOrder(orderId3);
        assertEq(uint256(nonDeletedOrder.metadata.status), uint256(IDoefinV1OrderBook.Status.Pending));
    }

    function test_DeleteOrders_DoesNotDeleteMatchedOrders() public {
        uint256 currentBlockNumber = blockHeaderOracle.currentBlockHeight();
        uint256 currentTimestamp = block.timestamp;

        // Create an expired matched order
        uint256 orderId = _createOrder(
            users.alice,
            1000,
            minCollateralAmount,
            minCollateralAmount * 2,
            currentBlockNumber - 1,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Above,
            currentTimestamp + 1 hours
        );

        // Match the order
        vm.startPrank(users.broker);
        dai.approve(address(orderBook), minCollateralAmount);
        orderBook.matchOrder(orderId);
        vm.stopPrank();

        vm.prank(address(this));
        orderBook.deleteOrders();

        // Verify the order is still there and matched
        IDoefinV1OrderBook.BinaryOption memory matchedOrder = orderBook.getOrder(orderId);
        assertEq(uint256(matchedOrder.metadata.status), uint256(IDoefinV1OrderBook.Status.Matched));
    }

    function test_DeleteOrders_DeletesPastDeadlineOrders() public {
        uint256 currentBlockNumber = blockHeaderOracle.currentBlockHeight();
        uint256 currentTimestamp = block.timestamp;

        // Create an order past its deadline
        uint256 orderId1 = _createOrder(
            users.alice,
            1000,
            minCollateralAmount,
            minCollateralAmount * 2,
            currentBlockNumber + 100,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Above,
            currentTimestamp - 1 // Past deadline
        );

        // Create a non-expired order
        uint256 orderId2 = _createOrder(
            users.james,
            2000,
            minCollateralAmount,
            minCollateralAmount * 2,
            currentBlockNumber + 100,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Below,
            currentTimestamp + 1 hours
        );

        vm.prank(address(this));
        orderBook.deleteOrders();

        // Verify deleted order
        IDoefinV1OrderBook.BinaryOption memory deletedOrder = orderBook.getOrder(orderId1);
        assertEq(uint256(deletedOrder.metadata.status), 0);

        // Verify non-deleted order
        IDoefinV1OrderBook.BinaryOption memory nonDeletedOrder = orderBook.getOrder(orderId2);
        assertEq(uint256(nonDeletedOrder.metadata.status), uint256(IDoefinV1OrderBook.Status.Pending));
    }

    function _createOrder(
        address maker,
        uint256 strike,
        uint256 premium,
        uint256 notional,
        uint256 expiry,
        IDoefinV1OrderBook.ExpiryType expiryType,
        IDoefinV1OrderBook.Position position,
        uint256 deadline
    )
        internal
        returns (uint256)
    {
        vm.startPrank(maker);
        dai.approve(address(orderBook), premium);

        address[] memory allowed = new address[](1);
        allowed[0] = users.broker;

        IDoefinV1OrderBook.CreateOrderInput memory input = IDoefinV1OrderBook.CreateOrderInput({
            strike: strike,
            premium: premium,
            notional: notional,
            expiry: expiry,
            expiryType: expiryType,
            position: position,
            collateralToken: collateralToken,
            deadline: deadline,
            allowed: allowed
        });

        uint256 orderId = orderBook.createOrder(input);
        vm.stopPrank();
        return orderId;
    }
}
