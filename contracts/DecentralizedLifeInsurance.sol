// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NFTValidator.sol";

contract DecentralizedLifeInsurance {
    address public owner;
    mapping(address => bool) public validValidators;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public lastDepositTimestamp;
    IERC20 public stablecoin;
    NFTValidator public nftValidator;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor(address _stablecoin, address _nftValidator) {
        owner = msg.sender;
        stablecoin = IERC20(_stablecoin);
        nftValidator = NFTValidator(_nftValidator);
    }

    function registerValidators(address[] calldata validators) external onlyOwner {
        for (uint256 i = 0; i < validators.length; i++) {
            validValidators[validators[i]] = true;
            nftValidator.mintValidatorNFT(validators[i]);
        }
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than zero");
        require(stablecoin.transferFrom(msg.sender, address(this), amount), "Failed to transfer stablecoin");
        balanceOf[msg.sender] += amount;
        lastDepositTimestamp[msg.sender] = block.timestamp;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(validValidators[msg.sender], "Only valid validators can withdraw funds");
        require(balanceOf[msg.sender] >= amount, "Insufficient funds");
        require(block.timestamp - lastDepositTimestamp[msg.sender] >= 30 days, "Withdrawals only allowed after 30 days");
        balanceOf[msg.sender] -= amount;
        require(stablecoin.transfer(msg.sender, amount), "Failed to transfer stablecoin");
        emit Withdrawal(msg.sender, amount);
    }
}
