pragma solidity 0.5.0;

import "./Unit.sol";

contract InLine {
    
    address owner;
    uint weiPerMonth;
    mapping(address => User) subs;
    
    // Once a user subscribes, their status can never be NOTEXIST.
    // Without NOTEXIST, myStatus() and getStatus() would return 0 for
    // a non-existent user and a SINGLE user.
    // { 0: NOTEXIST, 1: SINGLE, 2: COMPLICATED, 3: DATING, 4: MARRIED }
    enum Status {
        
        NOTEXIST,
        SINGLE, 
        COMPLICATED,
        DATING, 
        MARRIED
    }
    
    struct User {
        
        Status status;
        uint timeJoined;
        uint timeExpiration;
        uint timeLastChange;
    }
    
    // Sent whenever a User changes their relationship status
    event Change (
        
        address userAddr,
        Status statusBefore,
        Status statusAfter
    );
    
    // Proof of address ownership
    event Proof (
        
        address senderAddr,
        address receiverAddr,
        Status status
    );
    
    modifier userExists {
        require(subs[msg.sender].timeJoined != 0, "User does not exist");
        _;
    }
    
    modifier userPaid {
        require(subs[msg.sender].timeExpiration >= now, "User has not paid");
        _;
    }
    
    modifier validStatus(Status _status) {
        require(_status == Status.SINGLE
            || _status == Status.COMPLICATED 
            || _status == Status.DATING 
            || _status == Status.MARRIED);
        _;
    }
    
    modifier otherExists(address _userAddr) {
        require(subs[_userAddr].timeJoined != 0, "Other user does not exist");
        _;
    }
    
    modifier verifyPayment(uint _months, uint _maxWeiPerMonth) {
        
        // Make sure the user is willing to pay the current monthly fee
        // This is to avoid the contract owner unexpectedly changing the monthly fee
        require(_maxWeiPerMonth <= weiPerMonth, "weiPerMonth is greater than desired max monthly value");
        
        // Make sure that enough ether was sent
        require((msg.value/weiPerMonth) >= _months, "Insufficient wei received");
        
        // timeExpiration cannot be more than 1 year in the future
        // weiPerMonth can change, so users should not be able to buy too much in advance
        require( (subs[msg.sender].timeExpiration+Unit.toAprxMonths(_months)) < now + Unit.toAprxYears(1), 
            "Subscription cannot go further than a year into the future");
        _;
    }
    
    modifier isOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        weiPerMonth = 1 finney;
    }
    
    // Unscribed user subscribes, sets status, and adds initial funds
    function subscribe(Status _status, uint _months, uint _maxWeiPerMonth)
        external
        payable
        validStatus(_status)
        verifyPayment(_months, _maxWeiPerMonth)
    {
        // Make sure that the user does not already exist
        require(subs[msg.sender].timeJoined == 0, "Existing user cannot subscribe");
        
        // Creates an account for the user
        processFunds(_months);
        
        // Only finish creating a users account if the funds were successfully processed
        User storage user = subs[msg.sender];
        user.timeJoined = now;
        user.status = _status;
        user.timeLastChange = now;
        emit Change(msg.sender, Status.NOTEXIST, _status);
    }
    
    // Subscribed user adds additional funds
    function addFunds(uint _months, uint _maxWeiPerMonth)
        external
        payable
        userExists
        verifyPayment(_months, _maxWeiPerMonth)
    {
        processFunds(_months);
    }
    
    // Called by subscribe() and addFunds() for updating user.timeExpiration
    function processFunds(uint _months) internal {
        
        User storage user = subs[msg.sender];
        
        // if the user has not previously subscribed - invoked by subscribe()
        if (0 == user.timeJoined) {
            
            user.timeExpiration = now + Unit.toAprxMonths(_months);
        }
        
        // if the user has previously subscribed - invoked by addFunds()
        else {
            
            // if the users subscription has expired
            if (user.timeExpiration < now) {
                
                user.timeExpiration = now + Unit.toAprxMonths(_months);
            }
            
            // if the users subscription has not expired
            else {

                user.timeExpiration += Unit.toAprxMonths(_months);
            }
        }
    }

    function statusChange(Status _status) internal {
        
        // Status should change
        require(subs[msg.sender].status != _status);
        
        User storage user = subs[msg.sender];
        Status before = user.status;
        user.status = _status;
        user.timeLastChange = now;
        
        emit Change(msg.sender, before, _status);
    }
    
    function statusProof(address _recipient) 
        external
        userExists
        userPaid
    {
        emit Proof(msg.sender, _recipient, subs[msg.sender].status);
    }
    
    function myUser()
        external
        view
        userExists
        userPaid
        returns(Status, uint, uint, uint)
    {
        User storage user = subs[msg.sender];
        return (user.status, user.timeJoined, user.timeExpiration, user.timeLastChange);
    }
    
    function getUser(address _userAddr)
        external
        view
        userExists
        userPaid
        otherExists(_userAddr)
        returns(Status, uint, uint, uint)
    {
        User storage user = subs[_userAddr];
        return (user.status, user.timeJoined, user.timeExpiration, user.timeLastChange);
    }
    
    function setWeiPerMonth(uint _weiPerMonth) external isOwner {
        weiPerMonth = _weiPerMonth;
    }
}
