pragma solidity ^0.4.17;

contract StudyInterface {
    function terminated() returns(uint);
    function depositFunds(address sponsor, uint amount, address[] beneficiaries, uint[] requests);
    function makeRequest(address beneficiary, uint amount, uint period, uint startDate, uint times, string serviceDetails) returns (uint id);
    function proceedRequest(uint requestId, uint[] donationsIds, bool allowFreeAllocation);
    function abortRequest(uint requestId);
    function acceptTerms(uint requestId);
    function refundDonation(uint donationId);
    function redeemReward(uint liabilityId);
}