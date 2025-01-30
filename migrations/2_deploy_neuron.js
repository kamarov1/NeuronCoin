module.exports = async ({ getNamedAccounts, deployments, network }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    const params = require('../parameters.json');
  
    const neuron = await deploy('Neuron', {
      from: deployer,
      log: true,
      args: [
        ethers.utils.parseEther(params.token.initialSupply.toString()),
        ethers.utils.parseEther(params.token.blockReward.toString()),
        params.token.rewardHalvingPeriod
      ]
    });
  
    console.log(`Neuron deployed at: ${neuron.address}`);
  };
  
  module.exports.tags = ['Neuron'];
  module.exports.dependencies = ['Migrations'];
  