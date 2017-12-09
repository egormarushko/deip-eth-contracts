pragma solidity ^0.4.11;
import './Owned.sol';

/**
 * @title Generic owned destroyable contract
 */
contract Object is Owned {
    function Object() {
        owner  = msg.sender;
    }
}
