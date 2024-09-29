# Linear Bonding Curve Token

## Overview

`LinearBondingCurveToken` is an ERC-20 token implemented with a linear bonding curve, allowing users to buy and sell tokens with dynamic pricing based on supply. The token supports a pool balance and can be traded for ETH through the contract. The implementation is built using Solidity and includes reentrancy protection.

## Features

- **ERC-20 Compliance**: The token adheres to the standard ERC-20 interface.
- **Linear Bonding Curve**: Token pricing is based on a linear bonding curve, where the price increases or decreases depending on the current token supply.
- **CoolDown Period**: To prevent frequent trading, a cooldown period is enforced between purchases and sales.
- **Reentrancy Guard**: Protects the contract from reentrancy attacks, ensuring secure transactions.

## Technology

The token is written in Solidity 0.8.20, using OpenZeppelin’s standard libraries for ERC-20 compliance and reentrancy protection.

## Getting Started

### Prerequisites

- Node.js and npm
- Foundry (for local deployment and testing)

### Installation

Install Foundry if it’s not already installed:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Clone the repository

```bash
git clone https://github.com/evgenii-kireev/linear-bonding-curve-token.git
cd linear-bonding-curve-token
```

### Install dependencies

```bash
forge install
```

### Build

```bash
forge build
```

### Test
```bash
forge test
```

## Contributing

Contributions are welcome! Please fork the repository and open a pull request with your features or fixes.

## License

This project is unlicensed and free for use by anyone.

This README provides a comprehensive guide tailored to the `SupremeToken` and its unique features, ensuring users and developers can easily understand and interact with the token.


