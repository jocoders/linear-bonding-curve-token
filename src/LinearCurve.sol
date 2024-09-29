// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

/// @title Linear Curve Pricing Model
/// @author Evgenii Kireev
/// @notice This contract implements a linear pricing model for token sales.
/// @dev All calculations are performed with precision using a scaling factor.
/// @custom:experimental This is an experimental contract.
contract LinearCurve {
    uint256 public immutable reserveRatio; // The reserve ratio used for pricing
    uint256 public immutable initialPrice; // The initial price of the tokens
    uint256 private constant SCALE = 1e6; // Scaling factor for precision

    /// @notice Initializes the contract with reserve ratio and initial price
    /// @param _reserveRatio The reserve ratio as a percentage (in basis points)
    /// @param _initialPrice The initial price of the tokens (in wei)
    constructor(uint256 _reserveRatio, uint256 _initialPrice) {
        reserveRatio = _reserveRatio * SCALE;
        initialPrice = _initialPrice * SCALE;
    }

    /// @notice Returns the current price based on token supply
    /// @dev Calls the getLinearInstantaneousPrice function to determine the price
    /// @param tokenSupply The total supply of tokens
    /// @return The current price of tokens in wei
    function getCurrentPrice(uint256 tokenSupply) internal view returns (uint256) {
        return getLinearInstantaneousPrice(tokenSupply);
    }

    /// @notice Computes the amount of tokens that can be purchased for a given wei amount
    /// @dev This function calculates the number of tokens based on the current price.
    /// @param weiAmount The amount in wei to spend
    /// @param tokenSupply The total supply of tokens
    /// @return amountToPurchase amount of tokens that can be purchased
    function computePurchaseAmount(uint256 weiAmount, uint256 tokenSupply)
        internal
        view
        returns (uint256 amountToPurchase)
    {
        uint256 currentPrice = getLinearInstantaneousPrice(tokenSupply);
        amountToPurchase = weiAmount / currentPrice;
    }

    /// @notice Computes the sale amount based on the token amount
    /// @dev This function checks if the token amount is valid before calculating the sale amount.
    /// @param tokenAmount The amount of tokens to sell
    /// @param tokenSupply The total supply of tokens
    /// @return saleAmount amount in wei that will be received from the sale
    function computeSaleAmount(uint256 tokenAmount, uint256 tokenSupply) internal view returns (uint256 saleAmount) {
        require(tokenAmount <= tokenSupply, "Cannot sell more tokens than currently owned");
        saleAmount = (tokenAmount * initialPrice) / SCALE;
    }

    /// @notice Calculates the linear instantaneous price based on token supply
    /// @dev This function uses the formula:
    /// (reserveRatio * tokenSupply + initialPrice) / SCALE
    /// @param tokenSupply The total supply of tokens
    /// @return The linear instantaneous price in wei
    function getLinearInstantaneousPrice(uint256 tokenSupply) internal view returns (uint256) {
        return (reserveRatio * tokenSupply + initialPrice) / SCALE;
    }
}
