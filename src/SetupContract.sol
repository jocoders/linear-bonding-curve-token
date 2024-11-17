// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {LinearBondingCurveToken} from "./LinearBondingCurveToken.sol";

contract SetupContract {
    LinearBondingCurveToken token;

    constructor() payable {
        token = new LinearBondingCurveToken(100_500, 500 * 1e18, 99);
    }

    event Amounts(uint256 amountIn, uint256 amountOut);
    event Balances(uint256 poolBalance, uint256 echidnaBalanceEth, uint256 echidnaBalanceToken);

    receive() external payable {}

    function echidna_test_initialPrice() public view returns (bool) {
        return token.initialPrice() > 0;
    }

    function echidna_test_maxBuyToken() public view returns (bool) {
        return token.maxBuyToken() > 0;
    }

    function echidna_test_ratio() public view returns (bool) {
        return token.ratio() > 0;
    }

    function echidna_test_setup_balance() public view returns (bool) {
        return address(this).balance == 100 ether;
    }

    function echidna_test_receive() public returns (bool) {
        uint256 balance = token.poolBalance();
        (bool success,) = address(token).call{value: 1 ether}("");

        return token.poolBalance() == balance + 1 ether;
    }

    function test_current_price(uint256 ratio, uint256 totalSupply, uint256 initialPrice) public {
        require(ratio > 0, "Ratio must be greater than zero");
        require(totalSupply > 0, "Total supply must be greater than zero");

        uint256 price = ratio * totalSupply + initialPrice;

        assert(price > 0);
    }

    function test_sell_amount(uint256 amount, uint256 ratio, uint256 initialPrice, uint256 totalSupply) public {
        require(amount > 0, "Amount must be greater than zero");
        require(ratio > 0, "Ratio must be greater than zero");
        require(totalSupply > 0, "Total supply must be greater than zero");
        require(initialPrice > 0, "Initial price must be greater than zero");
        require(totalSupply >= amount, "Total supply must be greater than zero");

        uint256 m = ratio;
        uint256 b = initialPrice;
        uint256 S = totalSupply;
        uint256 N = amount;

        require(N <= S, "Not enough supply");

        uint256 term1 = (m * ((S * S) - ((S - N) * (S - N)))) / 2;
        uint256 term2 = b * N;

        uint256 amountSell = term1 + term2;

        emit Amounts(amount, amountSell);
        assert(amountSell > 0);
    }

    function pool_balance_change_correctly(uint256 amount) public {
        uint256 balance = token.poolBalance();
        token.buy{value: amount}();

        assert(token.poolBalance() == balance + amount);
    }

    function buy_test(uint256 amount) public {
        uint256 poolBalance = token.poolBalance();
        uint256 echidnaBalanceEth = address(this).balance;
        uint256 echidnaBalanceToken = token.balanceOf(address(this));

        token.buy{value: amount}();

        emit Balances(token.poolBalance(), address(this).balance, token.balanceOf(address(this)));

        assert(token.poolBalance() == poolBalance + amount);
        assert(address(this).balance == echidnaBalanceEth - amount);
        assert(token.balanceOf(address(this)) >= echidnaBalanceToken);
    }

    function sell_test(uint256 amountIn) public {
        uint256 poolBalance = token.poolBalance();
        uint256 echidnaBalanceEth = address(this).balance;
        uint256 echidnaBalanceToken = token.balanceOf(address(this));

        token.buy{value: amountIn}();

        uint256 amountTokenSell = token.balanceOf(address(this));
        token.sell(amountTokenSell);

        emit Amounts(amountIn, amountTokenSell);

        assert(token.poolBalance() == poolBalance);
        assert(address(this).balance == echidnaBalanceEth);
        assert(token.balanceOf(address(this)) == echidnaBalanceToken);
    }

    function sqrt(uint256 x) private pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
