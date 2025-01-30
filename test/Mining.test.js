const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Mining Contract Tests", function () {
  let Neuron, Mining;
  let neuron, mining;
  let owner, miner;

  before(async function () {
    [owner, miner] = await ethers.getSigners();
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

    // Deploy Mining
    Mining = await ethers.getContractFactory("Mining");
    mining = await Mining.deploy(
      neuron.address,
      1000,                       // initialDifficulty
      ethers.utils.parseEther("1"), // initialBlockReward
      600                          // targetBlockTime
    );
    await mining.deployed();

    // Configurar permissões
    await neuron.grantRole(await neuron.MINTER_ROLE(), mining.address);
    await mining.grantRole(await mining.MINER_ROLE(), miner.address);
  });

  it("Should mine blocks correctly", async function () {
    await mining.connect(miner).mine(12345);
    expect(await neuron.balanceOf(miner.address)).to.equal(ethers.utils.parseEther("1"));
    expect(await mining.blocksMined()).to.equal(1);
  });

  it("Should adjust difficulty dynamically", async function () {
    const initialDifficulty = await mining.difficulty();
    
    // Simular mineração rápida
    for (let i = 0; i < 10; i++) {
      await mining.connect(miner).mine(i);
      await ethers.provider.send("evm_increaseTime", [300]); // 5 minutos
      await ethers.provider.send("evm_mine");
    }

    const newDifficulty = await mining.difficulty();
    expect(newDifficulty).to.be.gt(initialDifficulty);
  });

  it("Should prevent invalid mining attempts", async function () {
    // Nonce inválido
    await expect(
      mining.connect(miner).mine(0)
    ).to.be.revertedWith("Invalid proof of work");

    // Sem permissão
    await expect(
      mining.connect(owner).mine(123)
    ).to.be.revertedWith("Must have miner role to mine");
  });

  it("Should handle reward halving correctly", async function () {
    const initialReward = await mining.blockReward();
    
    // Simular halving
    await ethers.provider.send("evm_increaseTime", [86400 * 2]);
    await ethers.provider.send("evm_mine");
    
    await mining.connect(miner).mine(12345);
    const newReward = await mining.blockReward();
    expect(newReward).to.be.lt(initialReward);
  });
});
