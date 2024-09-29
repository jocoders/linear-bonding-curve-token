// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {LinearCurve} from "./LinearCurve.sol";

/// @title LinearCurveHarness
/// @dev Extends LinearCurve for testing purposes, providing external access to contract methods.
contract LinearCurveHarness is LinearCurve {
    /// @notice Creates a new LinearCurveHarness contract
    /// @param _reserveRatio The reserve ratio used in the pricing formula
    /// @param _initialPrice The initial price of the token
    constructor(uint256 _reserveRatio, uint256 _initialPrice) LinearCurve(_reserveRatio, _initialPrice) {}

    /// @notice Retrieves the current price based on the token supply
    /// @param tokenSupply The current token supply
    /// @return The current price per token
    function getCurrentPriceExternal(uint256 tokenSupply) external view returns (uint256) {
        return super.getLinearInstantaneousPrice(tokenSupply);
    }

    /// @notice Computes the amount of tokens that can be purchased with the specified wei amount
    /// @param weiAmount The amount of wei used to purchase tokens
    /// @param tokenSupply The current token supply
    /// @return The amount of tokens that can be purchased
    function computePurchaseAmountExternal(uint256 weiAmount, uint256 tokenSupply) external view returns (uint256) {
        return super.computePurchaseAmount(weiAmount, tokenSupply);
    }

    /// @notice Computes the amount of wei received when selling tokens
    /// @param tokenAmount The amount of tokens to sell
    /// @param tokenSupply The current token supply
    /// @return The amount of wei that will be received
    function computeSaleAmountExternal(uint256 tokenAmount, uint256 tokenSupply) external view returns (uint256) {
        return super.computeSaleAmount(tokenAmount, tokenSupply);
    }

    /// @notice Retrieves the instantaneous price for a given token supply
    /// @param tokenSupply The token supply for which the price is requested
    /// @return The instantaneous price per token
    function getLinearInstantaneousPriceExternal(uint256 tokenSupply) external view returns (uint256) {
        return super.getLinearInstantaneousPrice(tokenSupply);
    }
}
