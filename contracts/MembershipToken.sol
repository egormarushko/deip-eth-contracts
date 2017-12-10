pragma solidity ^0.4.17;

import './SafeMath.sol';
import '../common/Object.sol';

/**
 * @title Token contract represents DAO membership
 */
contract MembershipToken is Object {

  using SafeMath for uint;

  event MemberAdded(address member);
  event MemberRemoved(address member);

  uint256 public totalSupply;

  uint constant InitialMemberBalance = 1;
  
  mapping(address => uint) public balances;

  mapping(address => uint) public memberSince;

 function balanceOf(address _owner) constant returns (uint256)
    { return balances[_owner]; }

 function isMember(address _owner) constant returns (bool)
    { return balances[_owner] > 0; }

  function MembershipToken() {
    totalSupply = 0;
  }

 function addMember(address target) onlyOwner {
    if (isMember(target)) revert();
    balances[target] = InitialMemberBalance;
    memberSince[target] = now;
    totalSupply = totalSupply.add(InitialMemberBalance);
    MemberAdded(target);
 }

 function removeMember(address target) onlyOwner {
    if (!isMember(target)) revert();
    memberSince[target] = 0;
    totalSupply = totalSupply.sub(balances[target]);
    balances[target] = 0;
    MemberRemoved(target);
 }

  function () {
      revert();
  }
}
