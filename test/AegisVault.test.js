const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AegisVault Protocol Test Suite", function () {
  let deployer, alice, bob, feeCollector;
  let asset, vault;

  beforeEach(async function () {
    [deployer, alice, bob, feeCollector] = await ethers.getSigners();

    const MockERC20 = await ethers.getContractFactory("MockERC20");
    asset = await MockERC20.deploy("Mock Token", "MTK", 18);
    await asset.waitForDeployment();

    const AegisVault = await ethers.getContractFactory("AegisVault");
    vault = await AegisVault.deploy(
      await asset.getAddress(),
      "Vault Shares",
      "vMTK",
      feeCollector.address,
      100 // 1%
    );
    await vault.waitForDeployment();

    // Mint test tokens to alice & bob
    await asset.mint(alice.address, ethers.parseEther("1000"));
    await asset.mint(bob.address, ethers.parseEther("1000"));

    await asset.connect(alice).approve(await vault.getAddress(), ethers.MaxUint256);
    await asset.connect(bob).approve(await vault.getAddress(), ethers.MaxUint256);
  });

  it("Should deposit underlying assets and mint vault shares 1:1 initially", async function () {
    const depositAmount = ethers.parseEther("100");
    await vault.connect(alice).deposit(depositAmount, alice.address);

    expect(await vault.balanceOf(alice.address)).to.equal(depositAmount);
    expect(await vault.totalAssets()).to.equal(depositAmount);
  });

  it("Should withdraw assets proportionally", async function () {
    const depositAmount = ethers.parseEther("100");
    await vault.connect(alice).deposit(depositAmount, alice.address);

    await vault.connect(alice).withdraw(depositAmount, alice.address, alice.address);
    expect(await vault.balanceOf(alice.address)).to.equal(0);
    expect(await asset.balanceOf(alice.address)).to.equal(ethers.parseEther("1000"));
  });

  it("Should respect pause flag", async function () {
    await vault.setPaused(true);
    await expect(
      vault.connect(alice).deposit(ethers.parseEther("10"), alice.address)
    ).to.be.revertedWith("AegisVault: contract is paused");
  });
});
