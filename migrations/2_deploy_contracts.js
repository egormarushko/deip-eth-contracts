var Owned = artifacts.require("../common/Owned.sol");
var ObjectC = artifacts.require("../common/Object.sol");
var ERC20 = artifacts.require("./ERC20.sol");
var Token = artifacts.require("./Token.sol");
var DeipToken = artifacts.require("./DeipToken.sol");
var MembershipToken = artifacts.require("./MembershipToken.sol");
var Membership = artifacts.require("./Membership.sol");
var Registry = artifacts.require("./Registry.sol");
var Study = artifacts.require("./Study.sol");
var StudyFactory = artifacts.require("./StudyFactory.sol");


module.exports = function(deployer) {
     deployer.deploy(DeipToken)
        .then(function() {
            return deployer.deploy(Registry, DeipToken.address, 0, 0);
        })
        .then(function() {
            return deployer.deploy(StudyFactory);
        })
        .then(function(){
            deployer.link(StudyFactory, Membership);
        })
};