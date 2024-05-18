//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Utils.sol";

/**
 * @title A contract to mint robots
 * Each address can only mint once either with eth or with the reward tokens
 * @dev To mint a unique robot !!pseudorandomness!! is used
 */
contract Factory is Utils {
    function mintRobot(
        string memory tokenURI
    ) public payable virtual returns (uint256 robotId) {
        if (hasMinted[msg.sender] != 0) revert AlreadyMinted();

        uint256 dna = _generateRandomDna();
        robotId = _buildRobot(dna, tokenURI);

        return robotId;
    }

    // Pseudorandomness is used to generate dna
    function _generateRandomDna() internal view virtual returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender)));
    }

    // Last digit of dna is 'attack' and next digit is 'defence'
    function _buildRobot(
        uint256 dna,
        string memory tokenURI
    ) internal virtual returns (uint256 robotId) {
        uint8 _attack = uint8(dna % 10) + 1;
        dna = dna / 10;
        uint8 _defence = uint8(dna % 10) + 1;
        robotId = nft.mint(msg.sender, _attack, _defence, 0, tokenURI);
        emit robotMintEvent(robotId, _attack, _defence);
    }
}
