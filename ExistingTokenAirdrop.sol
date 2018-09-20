pragma solidity ^0.4.20;

import "./EIP20Interface.sol"; //import interface

contract ExistingTokenAirdrop {
    address public tokenContract;
    address public owner;
    uint256 startTime;
    uint256 endTime;
    uint256 airdropRuntime;
    uint256 public maxSubscribers;
    uint256 public numberOfSubscribers;
    uint256 public tokenAmount;
    
    struct Subscribers {
        address _walletAddress;
        uint256 _amount;
        uint256 _id;
    }
    
    mapping (address => Subscribers) private subscriber_map;
    mapping (address => uint) private subscriber_ID;
    
//////////////////
    //EVENTS
//////////////////
    event ContractMsg(string message);
    event NewSubscriber(string msg, address subscriber);
    event TokenDropped(string msg, uint256 amount, address receiver);
     
/////////////////
    //SETUP
/////////////////

    // when applied to a function it can only be called by the contract creator
    modifier onlyOwner { 
        require(msg.sender == owner);
        _;
    }

    //called on contract creation (runtime is in seconds 604800 for a week)
    constructor(uint256 _airdropTokenAmount, uint256 _airdropRuntimeInSeconds, uint256 _maxAirdropSubscribers, address _tokenContractAddress) public {
        require(_airdropRuntimeInSeconds > 0);
        owner = msg.sender;
        maxSubscribers = _maxAirdropSubscribers; // set maximum aount of airdrop subscribers
        tokenContract = _tokenContractAddress; // sets the address of the existing ERC-20 token contract that this contract will interact with
        airdropRuntime = _airdropRuntimeInSeconds / 1 seconds;
        startTime = now; //set startTime , now is alias for block.timestamp (seconds since unix epoch)
        endTime = startTime + airdropRuntime; // set endTime
        uint256 airdropSupply = _airdropTokenAmount; // set amount to airdrop 
        tokenAmount = airdropSupply / maxSubscribers; // calculate amount of tokens per subscriber
        emit ContractMsg("Airdrop contract deployed successfully");//event 
    }
    
    //if ether sent direct to address
    function() public payable {
        ethRefund();
    }
    
    //automatically sends any accidently sent ether back to the user
    function ethRefund() payable public {
        require(msg.value > 0);
        msg.sender.transfer(msg.value);
        emit ContractMsg("ETH refunded, do not send eth to this contract!");
    }
    
    //get ETHER balance of contract ( should always be 0 )
    function contractEthBalance() public view returns(uint) {
        address contractAddress = this;
        return contractAddress.balance;
    }
    
    //precautionary measure, in the case ETH is somehow locked in the contract.
    function sweepEth() public onlyOwner {
        require(contractEthBalance() > 0);
        owner.transfer(contractEthBalance());
    }
    
    //retrieve leftover tokens post airdrop
    function sweepTokens() public onlyOwner {
        require(queryERC20Balance(this) > 0 && endTime < now);
        //approve transfer
        uint256 tokenBalance = queryERC20Balance(this);
        EIP20Interface(tokenContract).approve(this, tokenBalance);
        //make transfer
        EIP20Interface(tokenContract).transferFrom(this, msg.sender, tokenBalance);
    }
///////////////////////////
    //MAIN
//////////////////////////
    //register new subscriber
    function newSubscriber() public
    {
        require(endTime > now && queryERC20Balance(this) > 0);
        if(numberOfSubscribers > maxSubscribers){
            emit ContractMsg("Airdrop Subscription Hardcap Reached, No Tokens Left");
            revert();
        }
        else {
         //map sender address and corresponding data into Subscriber struct
        Subscribers storage _sub = subscriber_map[msg.sender];
        //stop multiple address subs
        require(_sub._walletAddress == 0x00);
        _sub._walletAddress = msg.sender;
        _sub._id = subscriber_ID[msg.sender];
        numberOfSubscribers++;
        tokenDrop(msg.sender);
        }
    }
    
    //auto token drop
    function tokenDrop(address _receiverAddress) private {
        require(endTime > now && queryERC20Balance(this) > 0);
        //require reciever to be subscribed
        require(subscriber_map[msg.sender]._walletAddress != 0x00);
        //approve transfer
        EIP20Interface(tokenContract).approve(this, tokenAmount);
        //make transfer
        EIP20Interface(tokenContract).transferFrom(this, _receiverAddress, tokenAmount);
        //make transfer
        emit TokenDropped("Token Dropped - ", tokenAmount, _receiverAddress);
        subscriber_map[msg.sender]._amount = tokenAmount;
    }
    
    //manual token drop
    function manualTokenDrop(address _receiverAddress) public onlyOwner 
    {
        require(endTime > now && queryERC20Balance(this) > 0);
        if(subscriber_map[_receiverAddress]._walletAddress == 0x00) {
            //new subscriber - map sender address and corresponding data into Subscriber struct
            Subscribers storage _sub = subscriber_map[_receiverAddress];
            _sub._walletAddress = _receiverAddress;
            _sub._id = subscriber_ID[_receiverAddress];
            numberOfSubscribers++;
        }
        //approve transfer
        EIP20Interface(tokenContract).approve(this, tokenAmount);
        //make transfer
        EIP20Interface(tokenContract).transferFrom(this, _receiverAddress, tokenAmount);
        //event
        emit TokenDropped("Token Dropped - ", tokenAmount, _receiverAddress);
        subscriber_map[_receiverAddress]._amount += tokenAmount;
    }
    
    //returns the token balance of specified address
    function queryERC20Balance(address _addressToQuery) view public returns (uint) {
        return EIP20Interface(tokenContract).balanceOf(_addressToQuery);
    }
    
    //returns the token balance of this contract
    function contractTokenBalance() public view returns (uint) {
       return queryERC20Balance(this);
    }
    
    //returns the token balance of function caller
    function myTokenBalance() public view returns (uint) {
       return queryERC20Balance(msg.sender);
    }
    
    //returns current block.timestamp(seconds since unix epoch)
    function getNowTime() public view returns (uint) {
        return now;
    }
    
    //returns end time of airdrop(seconds since unix epoch)
    function getEndTime() public view returns (uint) {
        return endTime;
    }
    
    //returns airdrop length in seconds
    function getAirdropRuntime() public view returns(uint) {
        return airdropRuntime;
    }
    
    //returns amount of time passed in seconds since airdrop start
    function getTimePassed() public view returns (uint) {
        require(startTime != 0);
        return (now - startTime)/(1 seconds);
    }
    
    //returns the amount of time left in seconds until airdrop finish
    function getTimeLeft() public view returns (uint) {
        require(endTime > now);
        return (endTime - now)/(1 seconds);
    }
}
