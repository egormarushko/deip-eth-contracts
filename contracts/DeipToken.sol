pragma solidity ^0.4.17;

import './Token.sol';
import './StudyAbstract.sol';

contract DeipToken is Token {

    function DeipToken()
             Token("DEIP", "DEIP", 9, 100000000000000000) public
    {
    }
}