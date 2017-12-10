pragma solidity ^0.4.17;
import './Owned.sol';

/**
 * @title Generic owned destroyable contract
 */
contract Object is Owned {
    function Object() public {
        owner  = msg.sender;
    }
}
