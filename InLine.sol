pragma solidity 0.5.0;

contract InLine {
    
    // 5700 blocks per day * 30 days per month = 171,000
    uint constant blocksPerMonth = 171000;
    
    // monthly subscription cost 
    uint constant weiPerMonth = 3400000000000000;
    
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
    
    modifier userPaid() {
        require(subs[msg.sender].blockExpiration <= block.number);
        _;
    }
    
    modifier validStatus(Status _status) {
        require(_status == Status.SINGLE || _status == Status.COMPLICATED || _status == Status.DATING || _status == Status.MARRIED);
        _;
    }
    
    // testing (remove when finished)
    function balance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Unscribed user subscribes, sets status, and adds initial funds
    function subscribe(uint _months, Status _status) external payable validStatus(_status) {
        
        if (true == processFunds(_months, msg.value)) { 
            
            User storage user = subs[msg.sender];
            user.blockJoined = block.number;
            user.status = _status;
            user.blockLastChange = block.number;
        }
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
            uint change = msg.value - (_months * weiPerMonth);
            msg.sender.transfer(change);
            
            return true;
        }
        
        // if not enough wei was provided, return the ether
        else {
            msg.sender.transfer(msg.value);
            return false;
        }
    }

    function myStatus() external view userExists userPaid returns (Status) {
        
        return subs[msg.sender].status;
    }

    function getStatus(address _userAddr) external view userExists userPaid returns (Status) {
        
        // Other address must have subscribed at some point
        require(subs[_userAddr].blockJoined != 0);
        return subs[_userAddr].status;
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
}
