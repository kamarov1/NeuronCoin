module.exports = async ({ getNamedAccounts, deployments }) => {
    const { execute } = deployments;
    const { deployer } = await getNamedAccounts();
    const params = require('../parameters.json');
  
    // Configure Mining contract
    await execute(
      'Mining',
      { from: deployer, log: true },
      'setBlockReward',
      ethers.utils.parseEther(params.mining.blockReward.toString())
    );
  
    // Configure Governance parameters
    await execute(
      'NeuronGovernance',
      { from: deployer, log: true },
      'setVotingDelay',
      params.governance.votingDelay
    );
  
    await execute(
      'NeuronGovernance',
      { from: deployer, log: true },
      'setVotingPeriod',
      params.governance.votingPeriod
    );
  
    console.log('Ecosystem configuration completed');
  };
  
  module.exports.tags = ['Configuration'];
  module.exports.dependencies = ['Governance'];
  