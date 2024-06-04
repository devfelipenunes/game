// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidityPool {
    address public owner;
    IERC20 public stablecoin;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor(address _stablecoin) {
        owner = msg.sender;
        stablecoin = IERC20(_stablecoin);
    }

    function investInDeFi(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(stablecoin.transferFrom(msg.sender, address(this), amount), "Failed to transfer stablecoin");
        // Implement DeFi investment logic here
    }

    function withdrawFromDeFi(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        // Implement DeFi withdrawal logic here
        require(stablecoin.transfer(msg.sender, amount), "Failed to transfer stablecoin");
    }
}
