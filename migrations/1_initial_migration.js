const { deployments } = require('hardhat');

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  
  await deploy('Migrations', {
    from: deployer,
    log: true,
    args: []
  });
};

module.exports.tags = ['Migrations'];
