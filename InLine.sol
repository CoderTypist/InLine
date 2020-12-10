// This is just pseudo code
// This is just pseudo code
// This is just pseudo code

contract InLine {

    enum Status {
        SINGLE,
        COMPLICATED,
        DATING,
        MARRIED
    }

    struct Person {

        uint joined_block;
        uint expiration_block;
        Status status;
        uint last_change;
    }    

    mapping(address => Person) subs;

    event Change(

        address user;
        Status status_before;
        Status status_after;

    );

    event Proof(

        address user;
        address receiver;
        Status status;
    );

    modifier user_exists() {

        assert(subs[_user] != 0);
        _;
    }

    modifier user_paid() {

        assert(subs[_user.expiration_block] < block.number);
        _;
    }

    // Subscribe
    function subscribe(address _user, Status _status) public payable {
        
        // person must not have already joined
        assert(subs[_primary] == 0);

        subs[_primary] = Person(99999999999999, _status, block.number);
    }

    function add_funds(address _user) public payable user_exists {

        // person must have already joined 
        assert(subs[_user] != 0);
    }

    function prove_to(address _user, address _recipient) public view user_exists user_paid {

        emit Proof(_user, _recipient, subs[_user].status)
    }

    function declare(address _user) public view {

        prove_to(_user, 0);
    }

    // Change relationship status
    function situation_change(address _user, Status _status) internal user_exists user_paid {
        
        Status previous = subs[_user].status;
        subs[_user].status = _status;
        emit Change(_user, previous, _status)
    }

    function now_single(address _user) public view user_exists {

        situation_change(_user, Status.SINGLE);
    }

    function now_complicated(address _user) public view {

        situation_change(_user, Status.COMPLICATED);
    }

    function now_dating(address _user) public view {

        situation_change(_user, Status.DATING);
    }

    function now_married(address _primary) public view {

        situation_change(_user, Status.MARRIED);
    }
    
}
