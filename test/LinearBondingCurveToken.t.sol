// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {LinearBondingCurveToken} from "../src/LinearBondingCurveToken.sol";

contract LinearBondingCurveTokenTest is Test {
    LinearBondingCurveToken token;

    uint256 constant INITIAL_PRICE = 130_000;
    uint256 constant MAX_BUY_TOKEN = 200 * 1e18;
    uint256 constant RATIO = 200;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address zeroAddress = makeAddr("zero");

    function setUp() public {
        token = new LinearBondingCurveToken(INITIAL_PRICE, MAX_BUY_TOKEN, RATIO);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function testInitialState() public {
        uint256 poolBalance = token.poolBalance();
        assertEq(poolBalance, 0);
        assertEq(token.initialPrice(), INITIAL_PRICE);
        assertEq(token.maxBuyToken(), MAX_BUY_TOKEN);
        assertEq(token.ratio(), RATIO);
    }

    function testGetInitCurrentPrice() public {
        uint256 currentPrice = token.getCurrentPrice();
        assertEq(currentPrice, INITIAL_PRICE);
    }

    function testSuccessfulBuy() public {
        uint256 poolBalance = token.poolBalance();
        uint256 ethAmount = 0.1 ether;

        assertEq(token.balanceOf(alice), 0);

        vm.prank(alice);
        token.buy{value: ethAmount}();

        assertGt(token.balanceOf(alice), 0);
        assertEq(token.poolBalance(), poolBalance + ethAmount);
    }

    function testBuyZeroTokens() public {
        vm.startPrank(bob);
        vm.expectRevert();
        token.buy{value: 0}();
        vm.stopPrank();
    }

    function testSellWithCooldownRevert() public {
        vm.startPrank(alice);
        token.buy{value: 0.1 ether}();

        vm.expectRevert("Cooldown period has not passed");
        token.sell(100);
        vm.stopPrank();
    }

    function testSuccessfulSellAfterCooldown() public {
        uint256 ethAmount = 0.1 ether;
        vm.prank(alice);
        token.buy{value: ethAmount}();

        vm.prank(bob);
        token.buy{value: ethAmount}();

        uint256 aliceTokenBalance = token.balanceOf(alice);
        vm.warp(block.timestamp + 2 minutes);

        vm.prank(alice);
        token.sell(1000);
        assertEq(token.balanceOf(alice), aliceTokenBalance - 1000, "Alice should have less tokens after sale");
    }

    function testSellZeroTokens() public {
        vm.startPrank(alice);
        vm.expectRevert("Insufficient tokens for sale");
        vm.warp(block.timestamp + 2 minutes);
        token.sell(0);
        vm.stopPrank();
    }

    function testSellMoreThanBalance() public {
        vm.prank(alice);
        token.buy{value: 0.1 ether}();

        uint256 aliceTokenBalance = token.balanceOf(alice);

        vm.warp(block.timestamp + 2 minutes);

        vm.expectRevert("Insufficient tokens for sale");
        token.sell(aliceTokenBalance + 1000);
        vm.stopPrank();
    }

    function testBalanceOf() public {
        uint256 ethAmount = 0.1 ether;

        vm.prank(alice);
        token.buy{value: ethAmount}();

        vm.prank(bob);
        token.buy{value: ethAmount}();

        uint256 aliceTokenBalance = token.balanceOf(alice);
        uint256 bobTokenBalance = token.balanceOf(bob);

        assertEq(token.balanceOf(alice), aliceTokenBalance, "Alice should have correct balance");
        assertEq(token.balanceOf(bob), bobTokenBalance, "Bob should have correct balance");
    }
}
