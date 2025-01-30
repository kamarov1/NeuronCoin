const hre = require("hardhat");

async function main() {
    const Neuron = await hre.ethers.getContractFactory("Neuron");
    const Staking = await hre.ethers.getContractFactory("Staking");

    const neuronToken = await Neuron.attach("NEURON_TOKEN_ADDRESS");
    const stakingContract = await Staking.attach("STAKING_CONTRACT_ADDRESS");

    const amountToStake = hre.ethers.utils.parseEther("100"); // Stake 100 tokens

    // Aprove o contrato de staking para gastar seus tokens
    await neuronToken.approve(stakingContract.address, amountToStake);

    // Realize o staking
    const tx = await stakingContract.stake(amountToStake);
    await tx.wait();

    console.log("Staking successful!");

    // Verifique as informações de stake
    const stakeInfo = await stakingContract.getStakeInfo(await hre.ethers.getSigner().getAddress());
    console.log("Stake amount:", hre.ethers.utils.formatEther(stakeInfo.amount));
    console.log("Stake tier:", stakeInfo.tier.toString());
    console.log("Pending reward:", hre.ethers.utils.formatEther(stakeInfo.pendingReward));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });