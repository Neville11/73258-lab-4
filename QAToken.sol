// SPDX-License-Identifier: GPL-3.0
// Author: Neville Chima
pragma solidity >=0.7.0 <0.9.0;

contract TokenERC20 {

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    string public constant name = "QA Coin";
    string public constant symbol = "QAC";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;

    constructor(uint256 total) {
      totalSupply_ = total;
      balances[address(this)] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
      return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        _transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function _transfer(address sender, address receiver, uint numTokens) internal {
        require(numTokens <= balances[sender]);
        
        balances[sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(sender, receiver, numTokens);
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] -= numTokens;
        allowed[owner][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}


contract QAToken is TokenERC20 {
    struct Answer {
        address provider;
        bytes32 text_hash;
        mapping (address => bool) upvoters;
    }

    mapping(address => uint256) amount_issued;
    mapping (bytes32 => Answer) answers;
    bytes32[] public answer_list;


    constructor(
       uint256 initialSupply 
    ) TokenERC20(initialSupply) public {}

        function PreDisburse(uint numStudents) public {
        require(numStudents > 0, 
            "Need to disburse coins to at least one student");
        
        require(balanceOf(msg.sender) == 0, 
            "User has non-zero initial balance");
        
        uint initAmt = totalSupply_ / numStudents; 
        _transfer(address(this), msg.sender, initAmt);
    } 

    function AddBalance(uint amount) public {
        transfer(address(this), amount);
        amount_issued[msg.sender] += amount;
    } 

    function ProvideAnswer(string memory text) public returns (bytes32) {
        require(msg.sender != address(0x0));
        bytes32  id = keccak256(abi.encodePacked(text, msg.sender));
        Answer storage newAns = answers[id];
        newAns.provider = msg.sender;
        newAns.text_hash = id;

        answer_list.push(id);

        return id;
    } 


    function UpvoteAnswer(bytes32 id, uint upvoteValue) public{
        require(msg.sender != address(0x0));
        require (answers[id].provider != address(0x0), 
                "Answer with given ID does not exist");
        require(answers[id].upvoters[msg.sender] != true,
                 "User has already upvoted answer");
        require(answers[id].provider != msg.sender,
                "User cannot upvote answer they already provided");
        
        answers[id].upvoters[msg.sender] = true;
        transfer(answers[id].provider, upvoteValue);

    }

    function RefundBalance() public {
        require(msg.sender != address(0x0));
        require(amount_issued[msg.sender] > 0,
                "Users question balance is empty");
        
        _transfer(address(this), msg.sender, amount_issued[msg.sender]);
        amount_issued[msg.sender] = 0;
    } 

    function ViewAnswers() public view returns (bytes32[] memory) {
        return answer_list;
    }

    function ViewAnswerProvider(bytes32 id) public view returns (address) {
        require(answers[id].provider != address(0x0),
            "Answer with given ID does not exist");
        return answers[id].provider;
    } 
}
