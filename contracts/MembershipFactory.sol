pragma solidity ^0.4.11;

import './Membership.sol';

library MembershipFactory {
    function createMembership(address deipToken, address registry, string name, address[] members) returns(Membership membership){
        membership = new Membership(deipToken, registry, name, members);
    }
}