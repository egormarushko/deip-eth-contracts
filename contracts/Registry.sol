pragma solidity ^0.4.11;

import '../common/Owned.sol';
import './ERC20.sol';

/**
 * @title Token contract represents regestry of studies and memberships
 */
contract Registry is Owned {

    mapping(address => address) studies;

    mapping(address => bytes32) memberships;

    uint public studyRegistrationFee;

    uint public membershipRegistrationFee;

    ERC20 token;

    function Registry(address _token, uint _membershipRegistrationFee, uint _studyRegistrationFee) {
        studyRegistrationFee = _studyRegistrationFee;
        membershipRegistrationFee = _membershipRegistrationFee;
        token = ERC20(_token);
    }

    function registerStudy(address study) payable {
        if (memberships[msg.sender] == 0) revert();
        if (studyRegistrationFee > 0 && msg.value < studyRegistrationFee) revert();
        studies[study] = msg.sender;
    }

    function registerMembership(bytes32 name) payable {
        if (memberships[msg.sender] != 0) revert(); //seems like we should shrow exeption, to not let proposal finish successfully
        if (membershipRegistrationFee > 0 && msg.value < membershipRegistrationFee) revert();
        memberships[msg.sender] = name;
    }

    function changeStudyRegistrationFee(uint fee) onlyOwner {
        studyRegistrationFee = fee;
    }

    function changeMembershipRegistrationFee(uint fee) onlyOwner {
        membershipRegistrationFee = fee;
    }

    function withdraw(uint amount) onlyOwner payable returns (bool) {
        return this.owner().send(amount);
    }
}