// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {Test, console} from "forge-std/Test.sol";

/// @title LinearBondingCurveToken: ERC20 token with Bonding Curve
/// @author Evgenii Kireev
/// @notice This contract allows users to buy and sell tokens using a linear bonding curve
/// @dev This contract implements a linear bonding curve for token pricing
contract LinearBondingCurveToken is ERC20, ReentrancyGuard {
    uint256 public immutable initialPrice;
    uint256 public immutable maxBuyToken;
    uint256 public immutable ratio;
    uint256 public poolBalance;

    uint256 private constant COOLDOWN_PERIOD = 1 minutes;

    mapping(address => uint256) private lastBuyTime;

    event Buy(address indexed buyer, uint256 weiAmount, uint256 bondAmount);
    event Sell(address indexed seller, uint256 bondAmount, uint256 weiAmount);

    error IncorrectTokenAmount(uint256 value, uint256 tokenPrice);

    /// @notice Creates a bonding curve token
    /// @dev Sets initial supply and reserve ratio based on parameters
    /// @param _initialPrice Initial price per token in wei
    /// @param _ratio Reserve ratio in percentage
    constructor(uint256 _initialPrice, uint256 _maxBuyToken, uint256 _ratio) ERC20("BondingCurveToken", "BCT") {
        require(_ratio > 0, "Ratio must be greater than zero");
        require(_initialPrice > 0, "Initial price must be greater than zero");
        require(_maxBuyToken > 0, "Max buy token must be greater than zero");

        ratio = _ratio;
        initialPrice = _initialPrice;
        maxBuyToken = _maxBuyToken;
    }

    receive() external payable {
        poolBalance += msg.value;
    }

    /// @notice Allows a user to buy tokens with ETH
    /// @dev Calculates token amount based on current supply and ETH sent
    function buy() external payable nonReentrant {
        address sender = msg.sender;
        uint256 value = msg.value;

        require(value >= initialPrice);
        require(value > 0, "Amount must be greater than zero");
        uint256 bondAmount = computePurchaseAmount(value);

        if (bondAmount == 0 || bondAmount > maxBuyToken) {
            revert IncorrectTokenAmount(value, getCurrentPrice());
        }

        poolBalance += value;
        _mint(sender, bondAmount);
        emit Buy(sender, value, bondAmount);
        lastBuyTime[sender] = block.timestamp;
    }

    /// @notice Allows a user to sell tokens back to the contract
    /// @dev Calculates the amount of ETH to be returned based on the current token supply
    /// @param amount The amount of tokens to sell
    function sell(uint256 amount) external nonReentrant {
        address sender = msg.sender;
        require(block.timestamp >= lastBuyTime[sender] + COOLDOWN_PERIOD, "Cooldown period has not passed");
        require(amount > 0 && amount <= balanceOf(sender), "Insufficient tokens for sale");

        uint256 weiAmount = computeSaleAmount(amount);

        require(poolBalance >= weiAmount, "Insufficient ETH in pool");
        poolBalance -= weiAmount;

        _burn(sender, amount);
        (bool success,) = payable(sender).call{value: weiAmount}("");
        require(success, "Transfer failed");

        emit Sell(sender, amount, weiAmount);
    }

    /// @notice Calculates the linear instantaneous price based on token supply
    /// @dev This function uses the formula:
    /// reserveRatio * tokenSupply + initialPrice
    /// @return The linear instantaneous price in wei
    function getCurrentPrice() public view returns (uint256) {
        return ratio * totalSupply() + initialPrice;
    }

    /// @notice Computes the amount of tokens that can be bought with a given amount of wei
    /// @dev Calculates token amount based on the linear bonding curve formula
    /// @param weiAmount The amount of wei used to purchase tokens
    /// @return tokenAmount The amount of tokens that can be bought with the specified weiAmount
    function computePurchaseAmount(uint256 weiAmount) internal view returns (uint256 tokenAmount) {
        uint256 m = ratio;
        uint256 b = initialPrice;
        uint256 S = totalSupply();

        // value = m * ((S + N)^2 - S^2) / 2 + b * N
        uint256 a = m / 2;
        uint256 c = weiAmount;
        uint256 discriminant = sqrt((b + m * S) ** 2 + 4 * a * c) - (b + m * S);
        uint256 doubleA = 2 * a;

        if (discriminant == 0 || discriminant < doubleA) {
            tokenAmount = 0;
        } else {
            tokenAmount = discriminant / doubleA;
        }
    }

    /// @notice Computes the amount of wei that can be received by selling a given amount of tokens
    /// @dev Calculates wei amount based on the linear bonding curve formula
    /// @param tokenAmount The amount of tokens to sell
    /// @return weiAmount The amount of wei that can be received for the specified tokenAmount
    function computeSaleAmount(uint256 tokenAmount) internal view returns (uint256 weiAmount) {
        uint256 m = ratio;
        uint256 b = initialPrice;
        uint256 S = totalSupply();
        uint256 N = tokenAmount;

        require(N <= S, "Not enough supply");

        uint256 term1 = (m * ((S * S) - ((S - N) * (S - N)))) / 2;
        uint256 term2 = b * N;

        weiAmount = term1 + term2;
    }

    /// @notice Calculates the square root of a given number using the Babylonian method
    /// @dev This function uses an iterative approach to compute the square root
    /// @param x The number to compute the square root of
    /// @return y The computed square root of x
    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
