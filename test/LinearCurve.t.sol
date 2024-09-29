// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {LinearCurveHarness} from "../src/LinearCurveHarness.sol";
import {console} from "forge-std/console.sol";

contract LinearCurveTest is Test {
    LinearCurveHarness linearCurve;
    uint256 tokenSupply = 1;
    uint256 poolBalance = 10;

    uint256 initialPrice = 10;
    uint256 reserveRatio = 50;
    uint256 private constant SCALE = 1e6;

    function setUp() public {
        linearCurve = new LinearCurveHarness(reserveRatio, initialPrice);
    }

    function testGetLinearInstantaneousPrice() public view {
        uint256 scaledReserveRatio = reserveRatio * SCALE;
        uint256 scaledInitialPrice = initialPrice * SCALE;
        uint256 expectedPrice = (scaledReserveRatio * tokenSupply + scaledInitialPrice) / SCALE;
        uint256 contractPrice = linearCurve.getLinearInstantaneousPriceExternal(tokenSupply);

        assertEq(contractPrice, expectedPrice, "Linear instantaneous price calculation is incorrect");
    }

    function testComputePurchaseAmount() public view {
        uint256 weiAmount = 1000000;
        uint256 testTokenSupply = 1000;

        uint256 currentPrice = linearCurve.getLinearInstantaneousPriceExternal(testTokenSupply);
        uint256 expectedPurchaseAmount = weiAmount / currentPrice;
        uint256 contractPurchaseAmount = linearCurve.computePurchaseAmountExternal(weiAmount, testTokenSupply);

        assertEq(contractPurchaseAmount, expectedPurchaseAmount, "Purchase amount calculation is incorrect");
    }

    function testComputeSaleAmount() public view {
        uint256 tokenAmount = 100;
        uint256 testTokenSupply = 50000;
        uint256 expectedSaleAmount = (tokenAmount * (initialPrice * SCALE)) / SCALE;
        uint256 contractSaleAmount = linearCurve.computeSaleAmountExternal(tokenAmount, testTokenSupply);

        assertEq(expectedSaleAmount, contractSaleAmount, "Sale amount calculation is incorrect");
    }
}
