pragma solidity ^0.4.17;

contract StudyInterface {
    function terminated() public returns(uint);
    function depositFunds(address sponsor, uint amount, address[] beneficiaries, uint[] requests) public;
    function makeRequest(address beneficiary, uint amount, uint period, uint startDate, uint times, string serviceDetails) public returns (uint id);
    function proceedRequest(uint requestId, uint[] donationsIds, bool allowFreeAllocation) public;
    function abortRequest(uint requestId) public;
    function acceptTerms(uint requestId) public;
    function refundDonation(uint donationId) public;
    function redeemReward(uint liabilityId) public;
}