module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, get } = deployments;
    const { deployer } = await getNamedAccounts();
    const params = require('../parameters.json');
  
    const neuron = await get('Neuron');
    
    const staking = await deploy('Staking', {
      from: deployer,
      log: true,
      args: [neuron.address]
    });
  
    // Initialize staking parameters
    const stakingContract = await ethers.getContractAt('Staking', staking.address);
    await stakingContract.setRewardRates(params.staking.rewardRates);
    await stakingContract.setTierThresholds(params.staking.tierThresholds);
  
    console.log(`Staking deployed at: ${staking.address}`);
  };
  
  module.exports.tags = ['Staking'];
  module.exports.dependencies = ['Neuron'];
  