const Migrations = artifacts.require("./Ibere.sol");

module.exports = function (deployer) {
  deployer.deploy(Ibere);
};
