pragma solidity 0.5.0;

contract InLine {
    
    // TODO: Make sure the contract works as expected so far
    //       - subscribe and add funds works
    //            - user.timeExpiration is properly updated
    // TODO: Allow the contract owner to adjust weiPerMonth
    //       - public function to check weiPerMonth
    //       - in addFunds, user can specify expected max weiPerMonth
    //         in case weiPerMonth suddenly
    // TODO: Limit how far ahead a person can pay for subscription
    
    // monthly subscription cost (roughly $5)
    // At the time of writing the contract, $5 is roughly 3,400,000,000,000,000 wei
    // 1 finney is 1,000,000,000,000,000 wei
    // 3,400,000,000,000,000 wei can be expressed as 3.4 finney
    
    // ONLY SET TO 100 FOR TESTING
    // ONLY SET TO 100 FOR TESTING
    // ONLY SET TO 100 FOR TESTING
    uint weiPerMonth = 100;
    address owner;
    
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
    
    mapping(address => User) subs;
    
    modifier userExists {
        require(subs[msg.sender].timeJoined != 0);
        _;
    }
    
    modifier userPaid {
        require(subs[msg.sender].timeExpiration >= now);
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
        require(subs[_userAddr].timeJoined != 0);
        _;
    }
    
    /*
     * Why is it necessary to specify _months when months can be calculated from the value?
     * Let's say that the price per month is 100 wei and that a person wants to sign up for 4 months.
     * The user creates a transaction signing them up for 4 months and sends 400 wei.
     * Let's say than the owner of the contract then creates a transaction adjusing the price per month to 50 wei.
     * If the owner's transaction is included in the block first, the price per month
     * will change before the user's transaction is processed.
     * Since the user sent 400 wei, they would be forced into an 8 month subscription that they might not have wanted.
     * By specifying how many months they wanted, the user will be refunded any extra wei. 
     * 
     * Why is it necessary to specify _maxWeiPerMonth?
     * Let's say that the price per month is 100 wei and that a person wants to sign up for 4 months
     * Given that the price per month can change, a person could send extra wei to account for a sudden change in price
     * Any extra wei will be returned to the sender
     */
    modifier verifyPayment(uint _months, uint _maxWeiPerMonth) {
        
        // Make sure the user is willing to pay the current monthly fee
        // This is to avoid the contract owner unexpectedly changing the monthly fee
        require(_maxWeiPerMonth <= weiPerMonth);
        
        // Make sure that enough ether was sent
        require((msg.value/weiPerMonth)>=_months);
        _;
    }
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    // Unscribed user subscribes, sets status, and adds initial funds
    function subscribe(Status _status, uint _months, uint _maxWeiPerMonth)
        external
        payable
        validStatus(_status)
        verifyPayment(_months, _maxWeiPerMonth)
    {
        // Make sure that the user does not already exist
        require(subs[msg.sender].timeJoined == 0);
        
        // Creates an account for the user
        processFunds(_months);
        
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
        // Make sure the user is willing to pay the current monthly fee
        // This is to avoid the contract owner unexpectedly changing the monthly fee
        require(_maxWeiPerMonth <= weiPerMonth);
        
        processFunds(_months);
    }
    
    // Called by subscribe() and addFunds() for updating user.timeExpiration
    function processFunds(uint _months) internal {
        
        uint numWeeks = _months*4;
        User storage user = subs[msg.sender];
        
        // if the user has not previously subscribed - invoked by subscribe()
        if (0 == user.timeJoined) {
            
            // ONLY FOR TESTING - REMOVE LATER
            // ONLY FOR TESTING - REMOVE LATER
            // ONLY FOR TESTING - REMOVE LATER
            user.timeExpiration = now + (numWeeks * 1 seconds);
            
            // user.timeExpiration = now + (numWeeks * 1 weeks);
        }
        
        // if the user has previously subscribed - invoked by addFunds()
        else {
            
            // if the users subscription has expired
            if (user.timeExpiration < now) {
                
                // ONLY FOR TESTING - REMOVE LATER
                // ONLY FOR TESTING - REMOVE LATER
                // ONLY FOR TESTING - REMOVE LATER
                user.timeExpiration += (numWeeks * 1 seconds);
                
                // user.timeExpiration = now + (numWeeks * 1 weeks);
            }
            
            // if the users subscription has not expired
            else {
                
                // ONLY FOR TESTING - REMOVE LATER
                // ONLY FOR TESTING - REMOVE LATER
                // ONLY FOR TESTING - REMOVE LATER
                user.timeExpiration += (numWeeks * 1 seconds);
                
                //user.timeExpiration += (numWeeks * 1 weeks);
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
    
    // ADD IN userPaid LATER (after userExists), IT WAS REMOVED FOR TESTING
    // ADD IN userPaid LATER (after userExists), IT WAS REMOVED FOR TESTING
    // ADD IN userPaid LATER (after userExists), IT WAS REMOVED FOR TESTING
    function myUser()
        external
        view
        userExists
        returns(Status, uint, uint, uint)
    {
        User storage user = subs[msg.sender];
        return (user.status, user.timeJoined, user.timeExpiration, user.timeLastChange);
    }
    
    // ADD IN userPaid LATER (after userExists), IT WAS REMOVED FOR TESTING
    // ADD IN userPaid LATER (after userExists), IT WAS REMOVED FOR TESTING
    // ADD IN userPaid LATER (after userExists), IT WAS REMOVED FOR TESTING
    function getUser(address _userAddr)
        external
        view
        userExists
        otherExists(_userAddr)
        returns(Status, uint, uint, uint)
    {
        User storage user = subs[_userAddr];
        return (user.status, user.timeJoined, user.timeExpiration, user.timeLastChange);
    }
    
    function setWeiPerMonth(uint _weiPerMonth) external isOwner {
        weiPerMonth = _weiPerMonth;
    }
    
    // FOR TESTING, REMOVE LATER
    // #####################################################################################
    
    // testing (remove when finished)
    function contractBalance()
        external
        view
        returns (uint)
    {
        return address(this).balance;
    }
    
    function myBalance() public view returns(uint) {
        return msg.sender.balance;
    }
    
    function getOwner() public view returns(address) {
        return owner;
    }
    
    function getWeiPerMonth() public view returns(uint) {
        return weiPerMonth;
    }
    
    // #####################################################################################
}
