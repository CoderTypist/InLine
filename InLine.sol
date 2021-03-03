pragma solidity 0.5.0;

// Error: USER CAN SUBSCRIBE FOR FREE!!! (Fixed by changing a >= to >)
// This means that they can update their status for free. We want them to pay. 

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
    
    // testing (remove when finished)
    function contractBalance()
        external
        view
        returns (uint)
    {
        return address(this).balance;
    }
    
    // Unscribed user subscribes, sets status, and adds initial funds
    function subscribe(Status _status)
        external
        payable
        validStatus(_status)
        returns (bool)
    {
        
        // Make sure that the user does not already exist
        require(subs[msg.sender].timeJoined == 0);
        
        if (true == processFunds()) { 
            
            User storage user = subs[msg.sender];
            user.timeJoined = now;
            user.status = _status;
            user.timeLastChange = now;
            emit Change(msg.sender, Status.NOTEXIST, _status);
            
            return true;
        }
        
        // Did not subscribe
        return false;
    }
    
    // Subscribed user adds additional funds
    function addFunds()
        external
        payable
        userExists
    {
        processFunds();
    }
    
    // Called by subscribe() and addFunds() for updating user.timeExpiration
    function processFunds() internal returns (bool) {
        
        uint monthsPossible = msg.value / weiPerMonth;
        uint numWeeks = monthsPossible*4;
        
        // if enough wei was provided to pay for the specified _months
        if (monthsPossible > 0) {
            
            User storage user = subs[msg.sender];
            
            // if the user has not previously subscribed - invoked by subscribe()
            if (0 == user.timeJoined) {
                
                // ONLY FOR TESTING - REMOVE LATER
                // ONLY FOR TESTING - REMOVE LATER
                // ONLY FOR TESTING - REMOVE LATER
                user.timeExpiration = now + (monthsPossible * 1 seconds);
                // user.timeExpiration = now + (numWeeks * 1 weeks);
            }
            
            // if the user has previously subscribed - invoked by addFunds()
            else {
                
                // if the users subscription has expired
                if (user.timeExpiration < now) {
                    
                    // ONLY FOR TESTING - REMOVE LATER
                    // ONLY FOR TESTING - REMOVE LATER
                    // ONLY FOR TESTING - REMOVE LATER
                    user.timeExpiration += (monthsPossible * 1 seconds);
                    
                    // user.timeExpiration = now + (numWeeks * 1 weeks);
                }
                
                // if the users subscription has not expired
                else {
                    
                    // ONLY FOR TESTING - REMOVE LATER
                    // ONLY FOR TESTING - REMOVE LATER
                    // ONLY FOR TESTING - REMOVE LATER
                    user.timeExpiration += (monthsPossible * 1 seconds);
                    
                    //user.timeExpiration += (numWeeks * 1 weeks);
                }
            }
            
            // send change back
            uint change = msg.value - (monthsPossible * weiPerMonth);
            msg.sender.transfer(change);
            
            return true;
        }
        
        // if not enough wei was provided, return the ether
        else {
            msg.sender.transfer(msg.value);
            return false;
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
    
    // REMOVE LATER, ONLY FOR TESTING
    // REMOVE LATER, ONLY FOR TESTING
    // REMOVE LATER, ONLY FOR TESTING
    function myBalance() public view returns(uint) {
        return msg.sender.balance;
    }
}
