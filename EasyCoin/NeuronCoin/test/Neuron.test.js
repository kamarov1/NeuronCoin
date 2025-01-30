const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Neuron Token Tests", function () {
  let Neuron;
  let neuron;
  let owner, addr1, addr2;

  before(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
  });

  beforeEach(async function () {
    Neuron = await ethers.getContractFactory("Neuron");
    neuron = await Neuron.deploy(
      ethers.utils.parseEther("1000000"), // initialSupply
      ethers.utils.parseEther("1"),      // blockReward
      86400                              // rewardHalvingPeriod
    );
    await neuron.deployed();
  });

  it("Should deploy with correct initial values", async function () {
    expect(await neuron.name()).to.equal("Neuron");
    expect(await neuron.symbol()).to.equal("NRN");
    expect(await neuron.decimals()).to.equal(18);
    expect(await neuron.totalSupply()).to.equal(ethers.utils.parseEther("1000000"));
  });

  it("Should perform token transfers correctly", async function () {
    // Test transferência básica
    await neuron.transfer(addr1.address, ethers.utils.parseEther("1000"));
    expect(await neuron.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther("1000"));

    // Test transferência entre usuários
    await neuron.connect(addr1).transfer(addr2.address, ethers.utils.parseEther("500"));
    expect(await neuron.balanceOf(addr2.address)).to.equal(ethers.utils.parseEther("500"));
    expect(await neuron.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther("500"));
  });

  it("Should handle approvals correctly", async function () {
    await neuron.approve(addr1.address, ethers.utils.parseEther("1000"));
    expect(await neuron.allowance(owner.address, addr1.address)).to.equal(ethers.utils.parseEther("1000"));

    // Test transferFrom
    await neuron.connect(addr1).transferFrom(
      owner.address,
      addr2.address,
      ethers.utils.parseEther("500")
    );
    expect(await neuron.balanceOf(addr2.address)).to.equal(ethers.utils.parseEther("500"));
    expect(await neuron.allowance(owner.address, addr1.address)).to.equal(ethers.utils.parseEther("500"));
  });

  it("Should prevent invalid transfers", async function () {
    // Saldo insuficiente
    await expect(
      neuron.connect(addr1).transfer(owner.address, 1)
    ).to.be.revertedWith("ERC20: transfer amount exceeds balance");

    // Approve insuficiente
    await neuron.approve(addr1.address, ethers.utils.parseEther("100"));
    await expect(
      neuron.connect(addr1).transferFrom(
        owner.address,
        addr2.address,
        ethers.utils.parseEther("200")
      )
    ).to.be.revertedWith("ERC20: insufficient allowance");
  });
});

