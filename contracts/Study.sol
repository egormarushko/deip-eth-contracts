pragma solidity ^0.4.11;

import './Registry.sol';
import './ERC20.sol';

contract Study {

    event FundsDeposited(address sponsor, uint amount, address[] beneficiaries, uint[] requests);
    event NewFundsRequested(address beneficiary, uint requestId);
    event RequestedAborted(uint requestId);
    event RequestFundsAllocated(uint requestId, uint liabilityId, uint amount, address beneficiary);

    // termination date
    uint public terminated;
    
    ERC20 token;

    Registry registry;

    uint freeAllocationBalance;
    uint totalRequsted;

    StudyFundsDonation[] donations;
    uint[] freeAllocationDonations;

    StudyFundsRequest[] requests;

    Liability[] liabilities;

    string public name;
    uint public studyId;
    address public membershipAddress;
    //Payment[] payments;

    uint constant FundsExpirationPeriod = 100 days;
    
    function Study(uint _studyId, string _name, address _membershipAddress, address _token) {
        studyId = _studyId;
        name = _name;
        membershipAddress = _membershipAddress;
        token = ERC20(_token);
    }

    struct StudyFundsRequest {
        uint requestId;
        address creator;
        address beneficiary;
        uint created;
        uint expirationDate;
        bool termsAccepted;
        bool aborted;
        bool executed;
        uint executionDate;
        //data
        uint amount;
        uint period;
        uint startDate;
        uint times;
    }

    struct Liability {
        uint liabilityId;
        uint requestId;
        address beneficiary; // service provider
        uint amount; //requested amount
        uint balance; //current balance
        uint paidAmount; //paid amount
        uint period; // period, 0 if one time payment
        uint startDate; //when first payment goes
        uint paidPeriods; //last paid period
        uint times; //number payment periods, 0 if one time payment
        bool accomplished; // is layability accomplished and payment made
    }

    function makeRequest(address beneficiary, uint amount, uint period, uint startDate, uint times) onlyMembership returns (uint id){
        id = requests.length++;
        StudyFundsRequest r = requests[id];
        r.requestId = id;
        r.creator = msg.sender;
        r.beneficiary = beneficiary;
        r.created = now;
        r.expirationDate = now + 100 days;
        r.amount = amount;
        r.period = period;
        r.startDate = startDate;
        r.times = times;
        totalRequsted += amount;
    }

    function proceedRequest(uint requestId, uint[] donationsIds, bool allowFreeAllocation) onlyMembership {
        if (!requests[requestId].termsAccepted) revert();
        if (requests[requestId].expirationDate < now) revert();
        if (requests[requestId].aborted) revert();
        allocateFundsForRequest(requestId, donationsIds, allowFreeAllocation);
    }

    function allocateFundsForRequest(uint requestId, uint[] donationsIds, bool allowFreeAllocation) private returns (uint allocatedAmount) {
        uint balance = token.balanceOf(address(this));
        StudyFundsRequest request = requests[requestId];
        uint requestedAmount = request.amount;
        allocatedAmount = 0;
        if (balance < requestedAmount) revert();
        if (donationsIds.length == 0) {
            if (!allowFreeAllocation) revert();
            //Need to consider directly sent token to study address
            if (freeAllocationBalance >= requestedAmount) {
                allocatedAmount = allocateFromDonations(freeAllocationDonations, requestedAmount);
                freeAllocationBalance -= allocatedAmount;
            }
        } else {
            //filter donationsIds to valid donations
            filterValidDonations(donationsIds, requestId, request.beneficiary);
            allocatedAmount = allocateFromDonations(validDonations, requestedAmount);
            if (allocatedAmount < requestedAmount){
                uint additionalAllocation = requestedAmount - allocatedAmount;
                allocatedAmount += allocateFromDonations(freeAllocationDonations, additionalAllocation);
            }
        }
        if (allocatedAmount != requestedAmount) revert();
        request.executed = true;
        request.executionDate = now;
        uint liabilityId = liabilities.length;
        liabilities.push(Liability(
             liabilityId,
             requestId,
             request.beneficiary, // service provider
             request.amount, //requested amount
             request.amount, //current balance
             0, //paid amount
             request.period, // period, 0 if one time payment
             request.startDate, //when first payment goes
             0, //last paid period
             request.times, //number payment periods, 0 if one time payment
             false // is layability accomplished and payment made
        ));
        RequestFundsAllocated(requestId, liabilityId, requestedAmount, request.beneficiary);
    }

    // @dev allocate spcific amount from specific donations
    function allocateFromDonations(uint[] ids, uint requestedAmount) private returns (uint) {
        uint allocatedAmount = 0;
        for(uint i=0; i<ids.length; i++)
        {
            var current = donations[ids[i]];
            if (allocatedAmount + current.balance > requestedAmount) {
                current.balance -= requestedAmount - allocatedAmount;
                allocatedAmount = requestedAmount;
            } else {
                allocatedAmount += current.balance;
                current.balance = 0; // potential risk - if we don't delete empty donations, we may make iteration too expensive
            }
        }
    }

    uint[] validDonations;

    function filterValidDonations(uint[] donationIds, uint requestId, address beneficiary)
    {
        validDonations.length = 0;
        for (uint i=0; i< donationIds.length; i++)
        {
            if (validateDontaionForRequest(donationIds[i], requestId, beneficiary)) {
                validDonations.push(donationIds[i]);
            }
        }
    }

    function validateDontaionForRequest(uint donationId, uint requestId, address beneficiary) constant returns(bool)
    {   
        return donations[donationId].containsBeneficiary[beneficiary] || donations[donationId].containsRequestId[requestId];
    }

    function abortRequest(uint requestId) onlyMembership {
        if (requests[requestId].executed) revert();
        requests[requestId].aborted = true;
        totalRequsted -= requests[requestId].amount;
    }

    function acceptTerms(uint requestId) {
        if (requests[requestId].beneficiary != msg.sender) revert();
        if (requests[requestId].termsAccepted) revert();
        requests[requestId].termsAccepted = true;
    }

    function depositFunds(address sponsor, uint amount, address[] beneficiaries, uint[] requests) {
        if (!token.transferFrom(sponsor, address(this), amount)) revert();
        uint donationId = donations.length;
        donations.length++;
        StudyFundsDonation d = donations[donationId];
        d.donationId = donationId;
        d.sponsor = sponsor;
        d.beneficiaries = beneficiaries;
        d.requests = requests;
        d.balance = amount;
        d.expirationDate = now + FundsExpirationPeriod;
        
        //we can either iterate when saving donation, or when appliying. When appliying donations will works as well, 
        //but if the list of donations is too big, it might take a lot of time
        for (uint i=0; i < beneficiaries.length; i++)
        {
            d.containsBeneficiary[beneficiaries[i]] = true;
        }
        for (uint j=0; j < requests.length; j++)
        {
            d.containsRequestId[requests[j]] = true;
        }
        FundsDeposited(sponsor, amount, beneficiaries, requests);
    }

    /*
     * @dev Redunds donation from specific study 
     * @param _amount: amount of tokens to withdraw
     * @param donationId: id of donation
     * @notice This make refund to msg.sender address only if donation is not applicable anymore)
     * @throws if study doesn't exists or it's not enough of funds on sender address
     */
    function refundDonation(uint donationId)
    {
        if (isFreeAllocationDonation(donationId)) revert();
    }

    function isFreeAllocationDonation(uint donationId) constant returns(bool)
    {
        return donations[donationId].beneficiaries.length == 0 && donations[donationId].requests.length == 0;
    }

    /*
     * @dev Receives (earnt money) payment for specific study
     * @param _study: address of donated study
     */
    function redeemReward(uint liabilityId) {
        var liability = liabilities[liabilityId];
        if (liability.accomplished) revert();
        if (liability.startDate < now) revert();
        uint amount = 0;
        if (liability.period > 0 && liability.times > 0)
        {
            uint passedTime = now - liability.startDate;
            uint passedPeriods = passedTime / liability.period;
            if (passedPeriods > liability.times) {
                passedPeriods = liability.times;
            }
            uint periodsToPay = passedPeriods - liability.paidPeriods;
            uint amountToPay = liability.amount * periodsToPay / liability.times;
            if (amountToPay > liability.balance) revert();
            liability.balance -= amountToPay;
            liability.paidAmount += amountToPay;
            liability.paidPeriods += periodsToPay;
            if (liability.paidPeriods == liability.times) {
                liability.accomplished = true;
            }
            amount = amountToPay;
        } else {
            amount = liability.balance;
            liability.paidAmount += amount;
            liability.balance = 0;       
            liability.accomplished = true; 
        }
        if (!token.transfer(liability.beneficiary, amount)) revert();
    }

    struct StudyFundsDonation{
        uint donationId;
        address sponsor;
        address[] beneficiaries;
        uint[] requests;
        uint balance;
        uint expirationDate;
        mapping(address => bool) containsBeneficiary;
        mapping(uint => bool) containsRequestId;
    }

    /*
    struct Payment {
        uint paymentId;
        uint liabilityId;
        uint amount;
        address payee;
        uint date;
    } */

    modifier onlyMembership{ if (msg.sender != address(membershipAddress)) revert(); _; }
}

