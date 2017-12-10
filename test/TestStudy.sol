pragma solidity ^0.4.17;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Study.sol";
import "../contracts/Registry.sol";
import "../contracts/Membership.sol";

contract TestStudy {

    Registry _registry;
    Membership _membership;

    function beforeEach() {
        _membership = new Membership(DeployedAddresses.DeipToken(), address(_registry));
        _registry = new Registry(0, 0);
    }

    function testStudyInitialization() {
        Study study = new Study(111, "Learn Big Bang Theory", address(_membership), DeployedAddresses.DeipToken());
        // contracts cannot read strings from another contracts yet, consider using bytes32
        // see https://ethereum.stackexchange.com/questions/3795/why-do-solidity-examples-use-bytes32-type-instead-of-string
        // Assert.equal(study.name(), "Learn Big Bang Theory", "Name should be equal to provided name");
        Assert.equal(study.membershipAddress(), address(_membership), "Membership should be specified");
        Assert.equal(study.terminated(), 0, "Should not be terminated");
    }
}