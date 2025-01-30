const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Staking Contract Tests", function () {
  let Neuron, Staking;
  let neuron, staking;
  let owner, staker;

  before(async function () {
    [owner, staker] = await ethers.getSigners();
  });

  beforeEach(async function () {
    // Deploy Token
    Neuron = await ethers.getContractFactory("Neuron");
    neuron = await Neuron.deploy(
      ethers.utils.parseEther("1000000"),
      ethers.utils.parseEther("1"),
      86400
    );
    await neuron.deployed();

    // Deploy Staking
    Staking = await ethers.getContractFactory("Staking");
    staking = await Staking.deploy(neuron.address);
    await staking.deployed();

    // Transferir tokens para teste
    await neuron.transfer(staker.address, ethers.utils.parseEther("10000"));
  });

  it("Should stake tokens correctly", async function () {
    await neuron.connect(staker).approve(staking.address, ethers.utils.parseEther("1000"));
    await staking.connect(staker).stake(ethers.utils.parseEther("1000"));
    
    const stakeInfo = await staking.stakes(staker.address);
    expect(stakeInfo.amount).to.equal(ethers.utils.parseEther("1000"));
    expect(await neuron.balanceOf(staking.address)).to.equal(ethers.utils.parseEther("1000"));
  });

  it("Should calculate rewards accurately", async function () {
    await neuron.connect(staker).approve(staking.address, ethers.utils.parseEther("1000"));
    await staking.connect(staker).stake(ethers.utils.parseEther("1000"));
    
    // Simular 1 dia
    await ethers.provider.send("evm_increaseTime", [86400]);
    await ethers.provider.send("evm_mine");

    const rewards = await staking.calculateReward(staker.address);
    expect(rewards).to.equal(ethers.utils.parseEther("86.4")); // 1000 * 0.001 * 86400
  });

  it("Should handle unstaking correctly", async function () {
    await neuron.connect(staker).approve(staking.address, ethers.utils.parseEther("1000"));
    await staking.connect(staker).stake(ethers.utils.parseEther("1000"));
    
    // Simular 7 dias
    await ethers.provider.send("evm_increaseTime", [604800]);
    await ethers.provider.send("evm_mine");

    await staking.connect(staker).unstake(ethers.utils.parseEther("500"));
    expect(await neuron.balanceOf(staker.address)).to.equal(ethers.utils.parseEther("9500"));
  });

  it("Should prevent early unstaking", async function () {
    await neuron.connect(staker).approve(staking.address, ethers.utils.parseEther("1000"));
    await staking.connect(staker).stake(ethers.utils.parseEther("1000"));
    
    await expect(
      staking.connect(staker).unstake(ethers.utils.parseEther("500"))
    ).to.be.revertedWith("Tokens are still locked");
  });

  it("Should upgrade tiers correctly", async function () {
    await neuron.connect(staker).approve(staking.address, ethers.utils.parseEther("6000"));
    await staking.connect(staker).stake(ethers.utils.parseEther("6000"));
    
    const stakeInfo = await staking.stakes(staker.address);
    expect(stakeInfo.tier).to.equal(3); // Verificar tier correto
  });
});
