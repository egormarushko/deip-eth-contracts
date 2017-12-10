pragma solidity ^0.4.17;

import './Study.sol';
import './StudyAbstract.sol';

library StudyFactory {
    function createStudy(uint studyId, string name, address token) returns(StudyInterface study){
        study = StudyInterface(new Study(studyId, name, msg.sender, token));
    }
}