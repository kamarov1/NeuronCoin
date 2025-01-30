const hre = require("hardhat");

async function main() {
    const Neuron = await hre.ethers.getContractFactory("Neuron");
    const Mining = await hre.ethers.getContractFactory("Mining");
    const Staking = await hre.ethers.getContractFactory("Staking");
    const Governance = await hre.ethers.getContractFactory("NeuronGovernance");

    // Deploy Neuron token
    const neuronToken = await Neuron.deploy(hre.ethers.utils.parseEther("1000000"), hre.ethers.utils.parseEther("1"), 86400);
    await neuronToken.deployed();
    console.log("Neuron deployed to:", neuronToken.address);

    // Deploy Mining contract
    const miningContract = await Mining.deploy(neuronToken.address, 1000, hre.ethers.utils.parseEther("1"), 600);
    await miningContract.deployed();
    console.log("Mining contract deployed to:", miningContract.address);

    // Deploy Staking contract
    const stakingContract = await Staking.deploy(neuronToken.address);
    await stakingContract.deployed();
    console.log("Staking contract deployed to:", stakingContract.address);

    // Deploy Governance contract
    const timelockAddress = "0xYourTimelockAddress"; // Substitua pelo endereço real do timelock
    const governanceContract = await Governance.deploy(neuronToken.address, timelockAddress);
    await governanceContract.deployed();
    console.log("Governance contract deployed to:", governanceContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });