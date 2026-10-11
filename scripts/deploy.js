const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  // 1. Deploy Mock Underlying Asset (USDC)
  const MockERC20 = await hre.ethers.getContractFactory("MockERC20");
  const usdc = await MockERC20.deploy("USD Coin Mock", "USDC", 6);
  await usdc.waitForDeployment();
  console.log("Mock USDC deployed to:", await usdc.getAddress());

  // 2. Deploy Aegis Vault
  const AegisVault = await hre.ethers.getContractFactory("AegisVault");
  const feeBps = 100; // 1%
  const vault = await AegisVault.deploy(
    await usdc.getAddress(),
    "Aegis Vault Shares",
    "avgUSDC",
    deployer.address,
    feeBps
  );
  await vault.waitForDeployment();
  console.log("Aegis Vault deployed to:", await vault.getAddress());

  // 3. Deploy Reward Token & Distributor
  const rewardToken = await MockERC20.deploy("Aegis Governance Token", "AEGIS", 18);
  await rewardToken.waitForDeployment();

  const RewardDistributor = await hre.ethers.getContractFactory("RewardDistributor");
  const distributor = await RewardDistributor.deploy(
    await vault.getAddress(),
    await rewardToken.getAddress()
  );
  await distributor.waitForDeployment();
  console.log("Reward Distributor deployed to:", await distributor.getAddress());

  console.log("--- Deployment Completed Successfully ---");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
