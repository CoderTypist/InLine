pragma solidity 0.5.0;

contract InLine {
    
    // Approximately 5700 blocks per day
    // Approximately 30 days per month
    // 5700 * 30 = 171,000
    uint constant blocksPerMonth = 171000;
    
    enum Status {
        
        SINGLE, 
        COMPLICATED,
        DATING, 
        MARRIED
    }
    
    struct User {
        
        uint blockJoined;
        uint blockExpiration;
        Status status;
        uint lastStatusChange;
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
    
    modifier userPaid() {
        require(subs[msg.sender].blockExpiration <= block.number);
        _;
    }
    
    function subscribe() public payable {
        
        // Must not already have a subscription
        require(subs[msg.sender].blockJoined == 0);
        
        // subs[msg.sender] = User(2,3,Status.SINGLE,4);
    }
    
    function balance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function myStatus() external view userExists userPaid returns (Status) {
        return subs[msg.sender].status;
    }
    
    function statusChange(Status _status) internal userExists userPaid {
        
        // Status should change
        require(subs[msg.sender].status != _status);
        
        User storage user = subs[msg.sender];
        Status before = user.status;
        user.status = _status;
        
        emit Change(msg.sender, before, _status);
    }
    
    function nowSingle() external {
        statusChange(Status.SINGLE);
    }
    
    function nowComplicated() external { 
        statusChange(Status.COMPLICATED);
    }
    
    function nowDating() external {
        statusChange(Status.DATING);
    }
    
    function nowMarried() external {
        statusChange(Status.MARRIED);
    }
}
