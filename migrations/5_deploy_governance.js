module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, get } = deployments;
    const { deployer } = await getNamedAccounts();
    const params = require('../parameters.json');
  
    const [neuron, timelock] = await Promise.all([
      get('Neuron'),
      deploy('TimelockController', {
        from: deployer,
        args: [
          params.governance.timelockDelay,
          [deployer],
          [deployer]
        ]
      })
    ]);
  
    const governance = await deploy('NeuronGovernance', {
      from: deployer,
      log: true,
      args: [
        neuron.address,
        timelock.address
      ]
    });
  
    // Setup roles
    const timelockContract = await ethers.getContractAt('TimelockController', timelock.address);
    await timelockContract.grantRole(
      await timelockContract.PROPOSER_ROLE(),
      governance.address
    );
  
    console.log(`Governance deployed at: ${governance.address}`);
  };
  
  module.exports.tags = ['Governance'];
  module.exports.dependencies = ['Neuron', 'Staking'];
  