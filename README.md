# AegisVault: Decentralized ERC-4626 Yield Staking Protocol

![Solidity](https://img.shields.io/badge/Solidity-^0.8.20-blue)
![Hardhat](https://img.shields.io/badge/Framework-Hardhat-yellow)
![License](https://img.shields.io/badge/License-MIT-green)

A production-grade, secure, and gas-optimized implementation of the **ERC-4626 Tokenized Vault Standard**, engineered for cross-protocol DeFi liquidity aggregation, fee management, and modular staking reward distribution.

---

## 🌟 Key Features

- **ERC-4626 Compliance**: Seamless interoperability across DeFi protocols with unified share minting and redemption math.
- **Inflation Protection & Safety**: Safeguarded against classic first-depositor front-running inflation attacks.
- **Automated Performance Fee Collection**: Configurable management/performance fee accrual mechanism.
- **Reentrancy Protection**: Built-in non-reentrant guards ensuring bulletproof reentrancy safety.
- **Emergency Circuit Breaker**: Granular pausing mechanism allowing governance to pause deposits during market anomalies.
- **Modular Staking Rewards**: `RewardDistributor` module for linear programmatic distribution of secondary incentives.

---

## 🏗 Architecture

```text
                  +-----------------------+
                  |     Liquidity User    |
                  +-----------+-----------+
                              |
                     Deposit / Withdraw
                              |
                              v
                  +-----------+-----------+
                  |      AegisVault       |  <--- ERC-4626 Standard
                  +-----------+-----------+
                              |
               +--------------+--------------+
               |                             |
               v                             v
      +--------+---------+          +--------+---------+
      | Underlying Asset |          | RewardDistributor|
      |   (ERC-20 Mock)  |          | (Yield Incentives|
      +------------------+          +------------------+
```

---

## 📂 Project Structure

```bash
├── contracts/
│   ├── AegisVault.sol          # Main ERC-4626 yield tokenized vault
│   ├── RewardDistributor.sol   # Synthetix-style linear staking reward engine
│   ├── MockERC20.sol           # Mock ERC20 token for development
│   └── IERC20.sol              # Clean minimal interface definition
├── scripts/
│   └── deploy.js               # Multi-contract deployment pipeline
├── test/
│   └── AegisVault.test.js      # Comprehensive Mocha/Chai test suite
├── hardhat.config.js           # Hardhat network & compiler configuration
└── package.json
```

---

## 🚀 Quick Start

### 1. Installation

```bash
git clone https://github.com/aromaticthrif/aegis-yield-vault.git
cd aegis-yield-vault
npm install
```

### 2. Compile Contracts

```bash
npx hardhat compile
```

### 3. Run Automated Tests

```bash
npx hardhat test
```

### 4. Deploy to Local/Testnet

```bash
npx hardhat run scripts/deploy.js --network localhost
```

---

## 🔒 Security & Best Practices

- All transfers follow the Checks-Effects-Interactions pattern.
- Zero-address and boundary checks implemented across administrative interfaces.
- Custom events emitted for indexers and subgraphs.

---

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.
