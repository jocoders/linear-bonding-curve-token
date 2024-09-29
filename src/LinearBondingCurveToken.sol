// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {LinearCurve} from "./LinearCurve.sol";

/// @title LinearBondingCurveToken: ERC20 token with Bonding Curve
/// @author Evgenii Kireev
/// @notice This contract allows users to buy and sell tokens using a linear bonding curve
/// @dev This contract implements a linear bonding curve for token pricing
contract LinearBondingCurveToken is ERC20, LinearCurve, ReentrancyGuard {
    uint256 public poolBalance;
    uint256 public tokenSupply;
    uint256 private constant COOLDOWN_PERIOD = 1 minutes;

    mapping(address => uint256) private lastBuyTime;

    event Buy(uint256 weiAmount, uint256 bondAmount);
    event Sell(uint256 bondAmount, uint256 weiAmount);

    error ZeroMintError(uint256 tokenPrice);

    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    /// @notice Creates a bonding curve token
    /// @dev Sets initial supply and reserve ratio based on parameters
    /// @param _initialPrice Initial price per token in wei
    /// @param _reserveRatio Reserve ratio in percentage
    /// @param _tokenSupply Initial token supply
    constructor(uint256 _initialPrice, uint256 _reserveRatio, uint256 _tokenSupply)
        payable
        ERC20("BondingCurveToken", "BCT")
        LinearCurve(_initialPrice, _reserveRatio)
    {
        require(_tokenSupply > 0, "Token supply must be greater than zero");
        tokenSupply = _tokenSupply;
        poolBalance = address(this).balance;
    }

    /// @notice Allows a user to buy tokens with ETH
    /// @dev Calculates token amount based on current supply and ETH sent
    function buy() external payable validAddress(msg.sender) nonReentrant {
        address sender = msg.sender;
        uint256 value = msg.value;

        require(value > 0, "Amount must be greater than zero");
        uint256 bondAmount = computePurchaseAmount(value, tokenSupply);

        if (bondAmount == 0) {
            revert ZeroMintError(getCurrentPrice(1));
        }

        poolBalance += value;
        tokenSupply += bondAmount;

        _mint(sender, bondAmount);
        emit Buy(value, bondAmount);
        lastBuyTime[sender] = block.timestamp;
    }

    /// @notice Allows a user to sell tokens back to the contract
    /// @dev Calculates the amount of ETH to be returned based on the current token supply
    /// @param amount The amount of tokens to sell
    function sell(uint256 amount) external validAddress(msg.sender) nonReentrant {
        address sender = msg.sender;
        require(block.timestamp >= lastBuyTime[sender] + COOLDOWN_PERIOD, "Cooldown period has not passed");
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= balanceOf(sender), "Insufficient tokens for sale");

        uint256 weiAmount = computeSaleAmount(amount, tokenSupply);
        poolBalance -= weiAmount;
        tokenSupply -= amount;

        _burn(sender, amount);
        (bool success,) = payable(sender).call{value: weiAmount}("");
        require(success, "Transfer failed");

        emit Sell(amount, weiAmount);
    }
}
