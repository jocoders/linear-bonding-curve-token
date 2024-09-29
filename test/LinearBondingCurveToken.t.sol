// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {LinearBondingCurveToken} from "../src/LinearBondingCurveToken.sol";

contract LinearBondingCurveTokenTest is Test {
    LinearBondingCurveToken token;
    address alice = address(0x1);
    address bob = address(0x2);
    address zeroAddress = address(0x0);

    function setUp() public {
        token = new LinearBondingCurveToken{value: 0.1 ether}(200_000, 20, 500_000);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function testSuccessfulBuy() public {
        uint256 tokenSupply = token.tokenSupply();
        uint256 poolBalance = token.poolBalance();
        uint256 ethAmount = 0.1 ether;

        assertEq(token.balanceOf(alice), 0);

        vm.prank(alice);
        token.buy{value: ethAmount}();

        assertGt(token.balanceOf(alice), 0);
        assertEq(token.poolBalance(), poolBalance + ethAmount);
        assertEq(token.tokenSupply(), tokenSupply + token.balanceOf(alice));
    }

    function testBuyZeroTokens() public {
        vm.startPrank(bob);
        vm.expectRevert("Amount must be greater than zero");
        token.buy{value: 0}();
        vm.stopPrank();
    }

    function testSellWithCooldownRevert() public {
        vm.startPrank(alice);
        token.buy{value: 0.1 ether}();

        vm.expectRevert("Cooldown period has not passed");
        token.sell(1000);
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
        vm.expectRevert("Amount must be greater than zero");

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
