// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { IERC20, Base_Test } from "./Base.t.sol";
import { Test } from "forge-std/Test.sol";
import {Errors, DoefinV1OrderBook, IDoefinV1OrderBook} from "../src/DoefinV1OrderBook.sol";
import {DoefinV1BlockHeaderOracle} from "../src/DoefinV1BlockHeaderOracle.sol";

/// @title DoefinV1OrderBook_Test
contract DoefinV1OrderBook_Test is Base_Test {
    DoefinV1OrderBook public orderBook;
    DoefinV1BlockHeaderOracle public blockHeaderOracle;
    address public collateralToken = address(dai);
    uint256 public constant minCollateralAmount = 100;
    uint256 public constant depositBound = 5000e6;

    function setUp() public virtual override {
        Base_Test.setUp();
        Base_Test.deployConfig();

        collateralToken = address(dai);
        blockHeaderOracle = new DoefinV1BlockHeaderOracle(setupInitialBlocks(), 838_886);

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

        orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
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

        orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
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

        orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
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

        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
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

        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
        assertEq(orderBook.balanceOf(users.alice, orderId), 1);
    }

    function test__IncreasePremium(uint256 strike, uint256 premium, uint256 expiry, address counterparty) public {
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

        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );

        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        uint256 orderBookBalBefore = IERC20(order.metadata.collateralToken).balanceOf(address(orderBook));
        uint256 oldPremium = order.premiums.makerPremium;

        uint256 increasePremium = (10 * premium) / 100; //increase premium by 10%
        dai.approve(address(orderBook), increasePremium);
        vm.expectEmit();
        emit IDoefinV1OrderBook.PremiumIncreased(orderId, increasePremium);
        orderBook.increasePremium(orderId, increasePremium);

        uint256 orderBookBalAfter = IERC20(order.metadata.collateralToken).balanceOf(address(orderBook));

        order = orderBook.getOrder(orderId);
        uint256 newPremium = order.premiums.makerPremium;

        assertEq(newPremium, oldPremium + increasePremium);
        assertEq(orderBookBalAfter - orderBookBalBefore, increasePremium);
        vm.stopBroadcast();

        //Revert if caller is not maker
        vm.startBroadcast(users.james);
        increasePremium = (5 * premium) / 100; //increase premium by 5%
        dai.approve(address(orderBook), increasePremium);

        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_CallerNotMaker.selector));
        orderBook.increasePremium(orderId, increasePremium);
        vm.stopBroadcast();

        //Revert if order if notional is invalid
        vm.startBroadcast(users.alice);
        increasePremium = (50 * premium) / 100; //increase premium by 50%
        dai.approve(address(orderBook), increasePremium);

        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_InvalidNotional.selector));
        orderBook.increasePremium(orderId, increasePremium);
        vm.stopBroadcast();

        //Revert if order is not pending
        vm.startBroadcast(users.alice);
        increasePremium = (5 * premium) / 100; //increase premium by 5%
        dai.approve(address(orderBook), increasePremium);
        orderBook.cancelOrder(orderId);

        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_OrderMustBePending.selector));
        orderBook.increasePremium(orderId, increasePremium);
        vm.stopBroadcast();
    }

    function test__DecreasePremium(uint256 strike, uint256 premium, uint256 expiry, address counterparty) public {
        vm.assume(strike != 0);
        vm.assume(expiry != 0);
        vm.assume(counterparty != address(0));
        vm.assume(premium >= minCollateralAmount * 10 && premium <= depositBound);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderCreated(0);

        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );

        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        uint256 orderBookBalBefore = IERC20(order.metadata.collateralToken).balanceOf(address(orderBook));
        uint256 oldPremium = order.premiums.makerPremium;

        uint256 decreasePremium = (10 * premium) / 100; //decrease premium by 10%
        dai.approve(address(orderBook), decreasePremium);
        vm.expectEmit();
        emit IDoefinV1OrderBook.PremiumDecreased(orderId, decreasePremium);
        orderBook.decreasePremium(orderId, decreasePremium);

        uint256 orderBookBalAfter = IERC20(order.metadata.collateralToken).balanceOf(address(orderBook));

        order = orderBook.getOrder(orderId);
        uint256 newPremium = order.premiums.makerPremium;

        assertEq(newPremium, oldPremium - decreasePremium);
        assertEq(orderBookBalBefore - orderBookBalAfter, decreasePremium);
        vm.stopBroadcast();

        //Revert if caller is not maker
        vm.startBroadcast(users.james);
        decreasePremium = (5 * premium) / 100; //increase premium by 5%

        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_CallerNotMaker.selector));
        orderBook.decreasePremium(orderId, decreasePremium);
        vm.stopBroadcast();

        //Revert if order if premium is less than minimum collateral
        vm.startBroadcast(users.alice);
        decreasePremium = (90 * premium) / 100; //increase premium by 50%
        dai.approve(address(orderBook), decreasePremium);

        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_LessThanMinCollateralAmount.selector));
        orderBook.decreasePremium(orderId, decreasePremium);
        vm.stopBroadcast();

        //Revert if order is not pending
        vm.startBroadcast(users.alice);
        decreasePremium = (5 * premium) / 100; //increase premium by 5%
        dai.approve(address(orderBook), decreasePremium);
        orderBook.cancelOrder(orderId);

        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_OrderMustBePending.selector));
        orderBook.decreasePremium(orderId, decreasePremium);
        vm.stopBroadcast();
    }

    function test__UpdateOrderPosition(uint256 strike, uint256 premium, uint256 expiry, address counterparty) public {
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

        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
        vm.stopBroadcast();

        // Revert if caller is not maker
        vm.startBroadcast(users.james);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_CallerNotMaker.selector));
        orderBook.updateOrderPosition(orderId, IDoefinV1OrderBook.Position.Call);
        vm.stopBroadcast();

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderPositionUpdated(orderId, IDoefinV1OrderBook.Position.Call);

        vm.startBroadcast(users.alice);
        orderBook.updateOrderPosition(orderId, IDoefinV1OrderBook.Position.Call);
        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        assert(order.positions.makerPosition == IDoefinV1OrderBook.Position.Call);
        vm.stopBroadcast();

        // Revert if order is not pending
        vm.startBroadcast(users.alice);
        orderBook.cancelOrder(orderId);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_OrderMustBePending.selector));
        orderBook.updateOrderPosition(orderId, IDoefinV1OrderBook.Position.Call);
        vm.stopBroadcast();
    }

    function test__UpdateOrderExpiry(uint256 strike, uint256 premium, uint256 expiry, address counterparty) public {
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

        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
        vm.stopBroadcast();

        // Revert if caller is not maker
        vm.startBroadcast(users.james);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_CallerNotMaker.selector));
        orderBook.updateOrderExpiry(orderId, block.timestamp, IDoefinV1OrderBook.ExpiryType.Timestamp);
        vm.stopBroadcast();

        uint256 timestamp = block.timestamp;
        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderExpiryUpdated(orderId, timestamp, IDoefinV1OrderBook.ExpiryType.Timestamp);

        vm.startBroadcast(users.alice);
        orderBook.updateOrderExpiry(orderId, timestamp, IDoefinV1OrderBook.ExpiryType.Timestamp);
        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        assertEq(order.metadata.expiry, timestamp);
        assert(order.metadata.expiryType == IDoefinV1OrderBook.ExpiryType.Timestamp);
        vm.stopBroadcast();

        // Revert if order is not pending
        vm.startBroadcast(users.alice);
        orderBook.cancelOrder(orderId);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_OrderMustBePending.selector));
        orderBook.updateOrderExpiry(orderId, block.timestamp, IDoefinV1OrderBook.ExpiryType.Timestamp);
        vm.stopBroadcast();
    }

    function test__UpdateOrderStrike(uint256 strike, uint256 premium, uint256 expiry, address counterparty) public {
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

        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
        vm.stopBroadcast();

        uint256 newStrike = 125;

        // Revert if caller is not maker
        vm.startBroadcast(users.james);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_CallerNotMaker.selector));
        orderBook.updateOrderStrike(orderId, newStrike);
        vm.stopBroadcast();

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderStrikeUpdated(orderId, newStrike);

        vm.startBroadcast(users.alice);
        orderBook.updateOrderStrike(orderId, newStrike);
        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        assertEq(order.metadata.initialStrike, newStrike);
        vm.stopBroadcast();

        // Revert if order is not pending
        vm.startBroadcast(users.alice);
        orderBook.cancelOrder(orderId);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_OrderMustBePending.selector));
        orderBook.updateOrderStrike(orderId, newStrike);
        vm.stopBroadcast();
    }

    function test__UpdateAllowedList(uint256 strike, uint256 premium, uint256 expiry, address counterparty) public {
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

        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
        vm.stopBroadcast();

        address[] memory newAllowed = new address[](2);
        newAllowed[0] = users.admin;
        newAllowed[1] = users.rick;

        // Revert if caller is not maker
        vm.startBroadcast(users.james);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_CallerNotMaker.selector));
        orderBook.updateOrderAllowedList(orderId, newAllowed);
        vm.stopBroadcast();

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderAllowedListUpdated(orderId, newAllowed);

        vm.startBroadcast(users.alice);
        orderBook.updateOrderAllowedList(orderId, newAllowed);
        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        assertEq(order.metadata.allowed[0], newAllowed[0]);
        assertEq(order.metadata.allowed[1], newAllowed[1]);
        vm.stopBroadcast();

        // Revert if order is not pending
        vm.startBroadcast(users.alice);
        orderBook.cancelOrder(orderId);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_OrderMustBePending.selector));
        orderBook.updateOrderAllowedList(orderId, newAllowed);
        vm.stopBroadcast();
    }

    function test__CancelOrder(uint256 strike, uint256 premium, uint256 expiry, address counterparty) public {
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

        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
        vm.stopBroadcast();

        IDoefinV1OrderBook.BinaryOption memory order = orderBook.getOrder(orderId);
        uint256 makerPrevBalance = IERC20(order.metadata.collateralToken).balanceOf(order.metadata.maker);

        // Revert if caller is not maker
        vm.startBroadcast(users.james);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_CallerNotMaker.selector));
        orderBook.cancelOrder(orderId);
        vm.stopBroadcast();

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderCanceled(orderId);

        // Revert if order is not pending
        vm.startBroadcast(users.alice);
        orderBook.cancelOrder(orderId);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_OrderMustBePending.selector));
        orderBook.cancelOrder(orderId);
        vm.stopBroadcast();

        order = orderBook.getOrder(orderId);
        uint256 makerCurrBalance = IERC20(order.metadata.collateralToken).balanceOf(order.metadata.maker);

        assertEq(makerCurrBalance - makerPrevBalance, order.premiums.makerPremium);
        assertEq(orderBook.balanceOf(order.metadata.maker, 1), 0);
        assert(order.metadata.status == IDoefinV1OrderBook.Status.Canceled);
    }

    function test__UpdateOrderD(uint256 strike, uint256 premium, uint256 expiry, address counterparty) public {
        vm.assume(strike != 0);
        vm.assume(expiry != 0);
        vm.assume(counterparty != address(0));
        vm.assume(premium >= minCollateralAmount && premium <= depositBound);

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = counterparty;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);

        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );

        // Prepare update parameters
        IDoefinV1OrderBook.UpdateOrder memory updateParams;
        updateParams.notional = int256(notional / 10); // Increase notional by 10%
        updateParams.premium = int256(premium / 20); // Increase premium by 5%
        updateParams.position = IDoefinV1OrderBook.Position.Call;
        updateParams.expiry = 10;
        updateParams.expiryType = IDoefinV1OrderBook.ExpiryType.Timestamp;
        address[] memory newAllowed = new address[](2);
        newAllowed[0] = users.broker;
        newAllowed[1] = users.james;
        updateParams.allowed = newAllowed;
        updateParams.strike = 100;

        dai.approve(address(orderBook), uint256(updateParams.premium));

        vm.expectEmit();
        emit IDoefinV1OrderBook.NotionalIncreased(orderId, uint256(updateParams.notional));
        vm.expectEmit();
        emit IDoefinV1OrderBook.PremiumIncreased(orderId, uint256(updateParams.premium));
        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderPositionUpdated(orderId, updateParams.position);
        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderExpiryUpdated(orderId, updateParams.expiry, updateParams.expiryType);
        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderAllowedListUpdated(orderId, updateParams.allowed);
        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderStrikeUpdated(orderId, updateParams.strike);

        orderBook.updateOrder(orderId, updateParams);

        IDoefinV1OrderBook.BinaryOption memory updatedOrder = orderBook.getOrder(orderId);
        assertEq(updatedOrder.premiums.notional, notional + uint256(updateParams.notional));
        assertEq(updatedOrder.premiums.makerPremium, premium + uint256(updateParams.premium));
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
        updateParams.notional = - int256(notional); // This will make makerPremium >= notional
        vm.startBroadcast(users.alice);
        vm.expectRevert(abi.encodeWithSelector(Errors.OrderBook_InvalidNotional.selector));
        orderBook.updateOrder(orderId, updateParams);
        vm.stopBroadcast();

        // Revert if order is not pending
        vm.startBroadcast(users.alice);
        orderBook.cancelOrder(orderId);
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

        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
        vm.stopBroadcast();

        // Prepare update parameters
        IDoefinV1OrderBook.UpdateOrder memory updateParams;
        updateParams.notional = - int256((10 * notional) / 100); // Decrease notional by 10%
        updateParams.premium = - int256((20 * premium) / 100); // Decrease premium by 20%
        updateParams.position = IDoefinV1OrderBook.Position.Call;
        updateParams.expiry = 10;
        updateParams.expiryType = IDoefinV1OrderBook.ExpiryType.Timestamp;
        address[] memory newAllowed = new address[](2);
        newAllowed[0] = users.broker;
        newAllowed[1] = users.james;
        updateParams.allowed = newAllowed;
        updateParams.strike = 100;

        vm.startBroadcast(users.alice);
        vm.expectEmit();
        emit IDoefinV1OrderBook.NotionalDecreased(orderId, uint256(- updateParams.notional));
        vm.expectEmit();
        emit IDoefinV1OrderBook.PremiumDecreased(orderId, uint256(- updateParams.premium));
        orderBook.updateOrder(orderId, updateParams);

        IDoefinV1OrderBook.BinaryOption memory updatedOrder = orderBook.getOrder(orderId);
        assertEq(updatedOrder.premiums.notional, notional - uint256(- updateParams.notional));
        assertEq(updatedOrder.premiums.makerPremium, premium - uint256(- updateParams.premium));
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
        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
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
        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
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
        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
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

        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
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
        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
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
        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
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
        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), premium);

        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

        orderBook.exerciseOrder(orderId);
    }

    function testFail__exerciseOrderWhenExerciseWindowHasNotStarted(
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

        uint256 notional = premium + ((30 * premium) / 100);
        address[] memory allowed = new address[](1);
        allowed[0] = users.broker;

        vm.startBroadcast(users.alice);
        dai.approve(address(orderBook), premium);
        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
        vm.stopBroadcast();

        vm.startBroadcast(users.broker);
        dai.approve(address(orderBook), premium);

        orderBook.matchOrder(orderId);
        vm.stopBroadcast();

        vm.startBroadcast(orderBook.blockHeaderOracle());
        orderBook.settleOrder(blockNumber, timestamp, difficulty);
        vm.stopBroadcast();

        rewind(1);
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

        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.BlockNumber,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
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
            if (order.positions.makerPosition == IDoefinV1OrderBook.Position.Call) {
                winner = order.metadata.maker;
            } else {
                winner = order.metadata.taker;
            }
        } else if (order.metadata.finalStrike < order.metadata.initialStrike) {
            if (order.positions.makerPosition == IDoefinV1OrderBook.Position.Put) {
                winner = order.metadata.maker;
            } else {
                winner = order.metadata.taker;
            }
        }

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderExercised(orderId, orderBook.getOrder(orderId).metadata.payOut, winner);
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

        uint256 orderId = orderBook.createOrder(
            strike,
            premium,
            notional,
            expiry,
            IDoefinV1OrderBook.ExpiryType.Timestamp,
            IDoefinV1OrderBook.Position.Put,
            collateralToken,
            allowed
        );
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
            if (order.positions.makerPosition == IDoefinV1OrderBook.Position.Call) {
                winner = order.metadata.maker;
            } else {
                winner = order.metadata.taker;
            }
        } else if (order.metadata.finalStrike < order.metadata.initialStrike) {
            if (order.positions.makerPosition == IDoefinV1OrderBook.Position.Put) {
                winner = order.metadata.maker;
            } else {
                winner = order.metadata.taker;
            }
        }

        vm.expectEmit();
        emit IDoefinV1OrderBook.OrderExercised(orderId, orderBook.getOrder(orderId).metadata.payOut, winner);
        orderBook.exerciseOrder(orderId);
    }
}
