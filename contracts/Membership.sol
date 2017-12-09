pragma solidity ^0.4.11;

import './MembershipToken.sol';
import './DeipToken.sol';
import './StudyAbstract.sol';
import './StudyFactory.sol';

contract RegistryInterface {
    function registerStudy(address study);
    function registerMembership(bytes32 name);
}

contract StudyFactoryInterface {
    function createStudy(uint studyId, string name, address token) returns(address study);
}

contract Membership {

    DeipToken deipToken;

    Proposal[] proposals;

    StudyInterface[] studies;
    
    MembershipToken public membershipToken;

    string public name;

    StudyFactoryInterface studyFactory;


    /* First time setup */
    function Membership(address deipTokenAddress, address registryAddress, string _name, address[] members) payable {
        membershipToken = new MembershipToken();
        name = _name;
        deipToken = DeipToken(deipTokenAddress);
        for (uint i=0; i < members.length; i++) {
            membershipToken.addMember(members[i]);
        }
    }


    enum ProposalType { InviteNewMember, ExcludeMember, StartNewStudy, RequestStudyFunds, ExecuteFundsRequest, AbortFundsRequest, SendEther, SendDeipToken /*, RegisterStudy, RegisterMembership */ }

    function inviteNewMember(address target) private {
        membershipToken.addMember(target);
    }

    function excludeMember(address target) private {
        membershipToken.removeMember(target);
    }

    function requestStudyFunds(uint studyId, address recipient, uint amount, uint period, uint startDate, uint times, string serviceDetails) private {
        StudyInterface(studies[studyId]).makeRequest(recipient, amount, period, startDate, times, serviceDetails);
    }

    function executeFundsRequest(uint studyId, uint requestId, uint[] donationsIds, bool allowFreeAllocation) private {
        StudyInterface(studies[studyId]).proceedRequest(requestId, donationsIds, allowFreeAllocation);
    }

    function abortFundsRequest(uint studyId, uint requestId) private {
        StudyInterface(studies[studyId]).abortRequest(requestId);
    }

    function sendEther(address target, uint amount) private returns(bool){
        return target.send(amount);
    }

    function sendDeipToken(address target, uint amount) private returns(bool){
        return deipToken.transfer(target, amount);
    }
    
    /*

    function registerStudy(address registry, uint amount, uint studyId) private {
        registry.call.value(amount)(bytes4(sha3("registerStudy")), address(studies[studyId]));
    }

    function registerMembership(address registry, uint amount, string name) private {
        registry.call.value(amount)(bytes4(sha3("registerMembership")), stringToBytes32(name));
    }
    
    function stringToBytes32(string memory source) returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    */

    struct Proposal {
        uint proposalId;
        ProposalType proposalType;
        ProposalMetadata metadata;
        uint    votingDeadline;
        bool    executed;
        bool    proposalPassed;
        uint    yea;
        uint    nay;
        mapping(address => bool) voted;
        mapping(address => bool) supportsProposal;
    }

    struct ProposalMetadata {
        uint studyId;
        address target;
        string  name;
        uint    amount;
        uint    period;
        uint    startDate;
        uint    times;
        // for request execution
        uint requestId;
        uint[] donationsIds;
        bool allowFreeAllocation;
    }
    
    event ProposalCreated(uint proposalId);
    /* Function to create a new proposal */
    function createProposal(
        uint votingDurationInMinutes,
        ProposalType proposalType,
        //metadata
        uint studyId,
        address target,
        string  name,
        uint    amount,
        uint    period,
        uint    startDate,
        uint    times,
        // for request execution
        uint requestId,
        uint[] donationsIds,
        bool allowFreeAllocation
    )
        onlyMember
        public returns(uint)
    {
        Proposal memory proposal;
        proposal.proposalId = proposals.length + 1; 
        proposal.proposalType = proposalType;
        proposal.votingDeadline = now + votingDurationInMinutes * 1 minutes;
        proposal.executed = false;
        proposal.proposalPassed = false;

        ProposalMetadata memory metadata = ProposalMetadata({
                    studyId: studyId,
                    target: target, 
                    name: name,
                    amount: amount,
                    period: period, 
                    startDate: startDate,
                    times: times,
                    requestId: requestId, 
                    donationsIds: donationsIds, 
                    allowFreeAllocation: allowFreeAllocation 
            });

        proposal.metadata = metadata;

        proposals.push(proposal);
        ProposalCreated(proposal.proposalId);
        return proposal.proposalId;
    }


    event Voted(uint proposalId, address membershipAddress, address voter);

    function vote(uint index, bool supportsProposal) onlyMember public {
        if (index < 0 || proposals.length - 1 < index) revert();

        Proposal p = proposals[index];
        var balance = membershipToken.balanceOf(msg.sender);
        if (p.voted[msg.sender] == true || balance == 0) revert();

        p.voted[msg.sender]            = true;
        p.supportsProposal[msg.sender] = supportsProposal;
        if (supportsProposal) {
            p.yea += balance;
        } else {
            p.nay += balance;
        }

        Voted(p.proposalId, address(this), msg.sender);
    }

    function executeProposal(uint index) onlyMember public returns(bool) {

        if (index < 0 || proposals.length - 1 < index) revert();

        Proposal p = proposals[index];

        if (now < p.votingDeadline || p.executed) revert();
        
        // if 70% of memebrs supports proposal execute proposal
        if (p.yea * 100 / membershipToken.totalSupply() >= 70 ) {

            if (p.proposalType == ProposalType.InviteNewMember) {
                inviteNewMember(p.metadata.target);
            } else if (p.proposalType == ProposalType.ExcludeMember) {
                excludeMember(p.metadata.target);
            } else if (p.proposalType == ProposalType.StartNewStudy) {
                createStudy(p.metadata.name);
            } else if (p.proposalType == ProposalType.RequestStudyFunds) {
                requestStudyFunds(p.metadata.studyId, p.metadata.target, p.metadata.amount, p.metadata.period, p.metadata.startDate, p.metadata.times, p.metadata.name);
            } else if (p.proposalType == ProposalType.ExecuteFundsRequest) {
                executeFundsRequest(p.metadata.studyId, p.metadata.requestId, p.metadata.donationsIds, p.metadata.allowFreeAllocation);
            } else if (p.proposalType == ProposalType.AbortFundsRequest) {
                abortFundsRequest(p.metadata.studyId, p.metadata.requestId);
            } else if (p.proposalType == ProposalType.SendEther) {
                sendEther(p.metadata.target, p.metadata.amount);
            } else if (p.proposalType == ProposalType.SendDeipToken) {
                sendDeipToken(p.metadata.target, p.metadata.amount);
            } /* else if (p.proposalType == ProposalType.RegisterStudy) {
                registerStudy(p.metadata.target, p.metadata.amount, p.metadata.studyId);
            } else if (p.proposalType == ProposalType.RegisterMembership) {
                registerMembership(p.metadata.target, p.metadata.amount, p.metadata.name);
            } */
            p.executed = true;
        } else {
            p.executed = false;
        }

        return p.executed;
    }


    event StudyCreated(uint studyId, address studyAddress);
    function createStudy(string name) private returns(address) {
        uint studyId = studies.length + 1;
        StudyInterface study = StudyFactory.createStudy(studyId, name, address(deipToken));
        studies.push(study);
        StudyCreated(studyId, address(study));
        return study;
    }

    function getProposalData(uint index) onlyMember
        public constant returns(uint, ProposalType, uint, bool, bool, uint, uint) {
        if (index < 0 || proposals.length - 1 < index) revert();
        return (
            proposals[index].proposalId, 
            proposals[index].proposalType, 
            proposals[index].votingDeadline, 
            proposals[index].executed,
            proposals[index].proposalPassed,
            proposals[index].yea,
            proposals[index].nay
        );
    }

    function getProposalMetadata(uint index) onlyMember
        public constant returns(uint, address, string, uint, uint, uint, uint) {
        if (index < 0 || proposals.length - 1 < index) revert();
        return (
            proposals[index].metadata.studyId,
            proposals[index].metadata.target,
            proposals[index].metadata.name,
            proposals[index].metadata.amount,
            proposals[index].metadata.period,
            proposals[index].metadata.startDate,
            proposals[index].metadata.times
        );
    }

    function getProposalRequestMetadata(uint index) onlyMember
        public constant returns(uint, uint[], bool) {
        if (index < 0 || proposals.length - 1 < index) revert();
        return (
            proposals[index].metadata.requestId,
            proposals[index].metadata.donationsIds,
            proposals[index].metadata.allowFreeAllocation
        );
    }

    function getProposalVoterData(uint index, address voter) onlyMember
        public constant returns(bool, bool) {
        if (index < 0 || proposals.length - 1 < index) revert();
        return (
            proposals[index].voted[voter],
            proposals[index].supportsProposal[voter]
        );
    }

    modifier onlyMember {
        if (membershipToken.isMember(msg.sender)){
            _;
        }
    }

    function () {
        revert();
    }
}