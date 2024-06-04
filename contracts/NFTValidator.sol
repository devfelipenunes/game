// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTValidator is ERC721{
    uint256 public tokenCounter;

    constructor() ERC721("ValidatorNFT", "VNFT") {
        tokenCounter = 0;
    }

    function mintValidatorNFT(address to) external {
        _safeMint(to, tokenCounter);
        tokenCounter++;
    }
}
