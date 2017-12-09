pragma solidity ^0.4.11;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/DeipToken.sol";

contract TestDeipToken {
  
  function testInitialBalanceUsingDeployedContract() {
    DeipToken deipToken = DeipToken(DeployedAddresses.DeipToken());
    uint expected = 10000;
    Assert.equal(deipToken.balanceOf(tx.origin), expected, "Owner should have 10000 DeipToken initially");
  }

  function testInitialBalanceWithNewMetaCoin() {
    DeipToken deipToken = new DeipToken("deip", "D", 0, 10000);
    uint expected = 10000;
    Assert.equal(deipToken.balanceOf(this), expected, "Owner should have 10000 DeipToken initially");
  }
}
