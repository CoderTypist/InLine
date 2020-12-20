pragma solidity 0.5.0;

contract InLine {
    
    // 5700 blocks per day * 30 days per month = 171,000
    uint constant blocksPerMonth = 171000;
    
    // monthly subscription cost (roughly $5)
    // uint constant weiPerMonth = 3400000000000000;
    uint constant weiPerMonth = 100;
    
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
        uint blockJoined;
        uint blockExpiration;
        uint blockLastChange;
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
        require(subs[msg.sender].blockJoined != 0);
        _;
    }
    
    modifier userPaid {
        require(subs[msg.sender].blockExpiration >= block.number);
        _;
    }
    
    modifier validStatus(Status _status) {
        require(_status == Status.SINGLE || _status == Status.COMPLICATED || _status == Status.DATING || _status == Status.MARRIED);
        _;
    }
    
    modifier otherExists(address _userAddr) {
        require(subs[_userAddr].blockJoined != 0);
        _;
    }
    
    // testing (remove when finished)
    function contractBalance() external view returns (uint) {
        return address(this).balance;
    }
    
    // Unscribed user subscribes, sets status, and adds initial funds
    function subscribe(uint _months, Status _status) external payable validStatus(_status) returns (bool) {
        
        // Make sure that the user does not already exist
        require(subs[msg.sender].blockJoined == 0);
        
        if (true == processFunds(_months, msg.value)) { 
            
            User storage user = subs[msg.sender];
            user.blockJoined = block.number;
            user.status = _status;
            user.blockLastChange = block.number;
            emit Change(msg.sender, Status.NOTEXIST, _status);
            
            return true;
        }
        
        // Did not subscribe
        return false;
    }
    
    // Subscribed user adds additional funds
    function addFunds(uint _months) external payable userExists {
        processFunds(_months, msg.value);
    }
    
    // Called by subscribe() and addFunds() for updating user.blockExpiration
    function processFunds(uint _months, uint _wei) internal returns (bool) {
        
        require(_months > 0);
        
        uint monthsPossible = _wei / weiPerMonth;
        
        // if enough wei was provided to pay for the specified _months
        if (monthsPossible >= _months) {
            
            User storage user = subs[msg.sender];
            
            // if the user has not previously subscribed
            if (0 == user.blockJoined) {
                user.blockExpiration = block.number + (_months * blocksPerMonth);
            }
            
            // if the user has previously subscribed
            else {
                
                // if the users subscription has expired
                if (user.blockExpiration < block.number) {
                    user.blockExpiration = block.number + (_months * blocksPerMonth);
                }
                
                // if the users subscription has not expired
                else {
                    user.blockExpiration += _months * blocksPerMonth;
                }
            }
            
            // send change back
            uint change = _wei - (_months * weiPerMonth);
            msg.sender.transfer(change);
            
            return true;
        }
        
        // if not enough wei was provided, return the ether
        else {
            msg.sender.transfer(_wei);
            return false;
        }
    }
    
    function statusChange(Status _status) internal {
        
        // Status should change
        require(subs[msg.sender].status != _status);
        
        User storage user = subs[msg.sender];
        Status before = user.status;
        user.status = _status;
        user.blockLastChange = block.number;
        
        emit Change(msg.sender, before, _status);
    }
    
    function statusProof(address _recipient) external userExists userPaid {
        emit Proof(msg.sender, _recipient, subs[msg.sender].status);
    }
    
    function myUser() external view userExists userPaid returns(Status, uint, uint, uint) {
        User storage user = subs[msg.sender];
        return (user.status, user.blockJoined, user.blockExpiration, user.blockLastChange);
    }
    
    function otherUser(address _userAddr) external view userExists userPaid otherExists(_userAddr) returns(Status, uint, uint, uint) {
        User storage user = subs[_userAddr];
        return (user.status, user.blockJoined, user.blockExpiration, user.blockLastChange);
    }
}
