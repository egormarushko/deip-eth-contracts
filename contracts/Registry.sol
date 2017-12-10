pragma solidity ^0.4.17;

import '../common/Owned.sol';
import './ERC20.sol';

/**
 * @title Token contract represents regestry of studies and memberships
 */
contract Registry is Owned {

    mapping(address => address) public studies;

    mapping(address => bytes32) public memberships;

    mapping(bytes32 => address) public uniqMembershipNames;

    uint public studyRegistrationFee;

    uint public membershipRegistrationFee;

    ERC20 public token;

    function Registry(address _token, uint _membershipRegistrationFee, uint _studyRegistrationFee) public {
        studyRegistrationFee = _studyRegistrationFee;
        membershipRegistrationFee = _membershipRegistrationFee;
        token = ERC20(_token);
    }

    function registerStudy(address study) public payable {
        require(memberships[msg.sender] != 0);
        require(studyRegistrationFee == 0 || msg.value >= studyRegistrationFee);
        studies[study] = msg.sender;
    }

    function registerMembership(bytes32 name) public payable {
        require(memberships[msg.sender] == 0); 
        require(membershipRegistrationFee == 0 || msg.value >= membershipRegistrationFee);
        require(uniqMembershipNames[name] == address(0));
        memberships[msg.sender] = name;
        uniqMembershipNames[name] = msg.sender;
    }

    function changeStudyRegistrationFee(uint fee) public onlyOwner {
        studyRegistrationFee = fee;
    }

    function changeMembershipRegistrationFee(uint fee) public onlyOwner {
        membershipRegistrationFee = fee;
    }

    function withdraw(uint amount) public onlyOwner payable returns (bool) {
        return this.owner().send(amount);
    }
}