// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    mapping(address => mapping(address => uint)) public Balance;
    mapping(address => uint) public TokensStaked;
    mapping(address => address) public PriceFeedPair;
    address[] public stakers;
    address[] public allowedTokens;
    IERC20 public shitToken;

    constructor(address _shitTokenAddress) {
        shitToken = IERC20(_shitTokenAddress);
    }

    function setPriceFeed(address _token, address _priceFeed) public onlyOwner 
    {
        PriceFeedPair[_token] = _priceFeed;
    }

    function issueTokens() public onlyOwner {
        for (uint i = 0; i < stakers.length; i++){
            address recipient = stakers[i];
            uint TotalValue = getTotalValue(recipient);
            shitToken.transfer(recipient, TotalValue);
        }
    }

    function getTotalValue(address _user) public view returns (uint){
        uint256 totalValue = 0;
        require(TokensStaked[_user] > 0);
        for (uint j = 0; j < allowedTokens.length; j++){
            totalValue += getSingleValue(_user, allowedTokens[j]);
        }
        return totalValue;
    }

    function getSingleValue(address _user, address _token) public view returns (uint) {
        if (TokensStaked[_user] <= 0){
            return 0;
        }
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return (Balance[_token][_user] * price / (10**decimals));
    }

    function getTokenValue(address _token) public view returns (uint256, uint256) {
        address priceFeedAddress = PriceFeedPair[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (,int price,,,)= priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }


    function stakeTokens(uint _amount, address _token) public {
        require(_amount > 0);
        require(tokenIsAllowed(_token));
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateTokensStaked(msg.sender, _token);
        Balance[_token][msg.sender] +=  _amount;
        if (TokensStaked[msg.sender] == 1){
            stakers.push(msg.sender);
        }
    }
    
    function unstakeTokens(address _token) public {
        uint balance = Balance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0");
        IERC20(_token).transfer(msg.sender, balance);
        Balance[_token][msg.sender] = 0 ;
        TokensStaked[msg.sender] -=  1;
        if (TokensStaked[msg.sender] == 0) {
            for (uint k = 0; k < stakers.length; k++) {
                if (stakers[k] == msg.sender) {
                    stakers[k] = stakers[stakers.length - 1];
                    stakers.pop();
                }
            }
        }
    }

    function updateTokensStaked(address _user, address _token) internal {
        if (Balance[_token][_user] <= 0){
            TokensStaked[_user] += 1;
        }
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public returns (bool) {
        for(uint l=0; l < allowedTokens.length; l++){
            if(allowedTokens[l] == _token){
                return true;
            }
        }
        return false; 
    }
    
}