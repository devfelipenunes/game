//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Utils.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Box is ERC1155, VRFConsumerBase, Utils {
    uint256 public deployedAt;
    uint256 public currentBoxMinted;

    enum BOX_RARITY {
        common,
        epic,
        legendary
    }

    enum BOX_STATUS {
        not_used,
        used
    }

    event BoxMinted(
        address indexed owner,
        uint256 box_id,
        uint256 time,
        uint256 price,
        BOX_RARITY rarity
    );
    event openBoxRequested(bytes32 requestId);

    struct BOX {
        uint256 id;
        address owner;
        uint256 mintedTime;
        bool ban;
        BOX_STATUS box_status;
        BOX_RARITY box_rarity;
    }

    BOX[] public boxes;

    mapping(uint256 => BOX_RARITY) public BoxRarity;
    mapping(uint256 => BOX_RARITY) public BoxRarityIndex;
    mapping(bytes32 => BOX_RARITY) public BoxRarityOfRequestId;
    mapping(BOX_RARITY => uint256) public BoxPrice;
    mapping(uint256 => BOX_STATUS) public BoxStatus;
    mapping(bytes32 => address) public RequestIdToOwner;

    AggregatorV3Interface internal priceFeed;

    constructor() ERC1155("") {
        BoxPrice[BOX_RARITY.common] = 50;
        BoxPrice[BOX_RARITY.epic] = 100;
        BoxPrice[BOX_RARITY.legendary] = 150;

        deployedAt = block.timestamp;

        BoxRarityIndex[0] = BOX_RARITY.common;
        BoxRarityIndex[1] = BOX_RARITY.epic;
        BoxRarityIndex[2] = BOX_RARITY.legendary;
    }

    function getBoxPrice(uint256 _price) public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.lastetRoundData();

        uint256 newPrice = uint256(price * 10 ** 10);
        return ((_price * 10 ** 18) / newPrice);
    }

    function mintBox(uint256 _boxRarityIndex) public payable {
        BOX_RARITY boxrarity = BoxRarityIndex[_boxRarityIndex];

        uint256 box_price = BoxPrice[boxrarity] - 15;
        uint256 boxPriceEth = getBoxPrice(box_price);
        boxes.push(
            BOX({
                id: currentBoxMinted,
                ban: false,
                owner: msg.sender,
                box_status: BOX_STATUS.not_used,
                box_rarity: boxrarity,
                mintedTime: block.timestamp
            })
        );
        _mint(msg.sender, currentBoxMinted, 1, "");
        currentBoxMinted += 1;
        emit BoxMinted(
            msg.sender,
            currentBoxMinted - 1,
            block.timestamp,
            msg.value,
            boxrarity
        );
    }

    function openBox(uint _boxId) public {
        BOX memory box = boxes[_boxId];
        bytes32 requestId = requestRandomness(keyHash, fee);
        BoxRarityOfRequestId[requestId] = box.box_rarity;
        RequestIdToOwner[requestId] = msg.sender;
        requestIdToShinobiId[requestId] = _boxId;
        requestIdToBoxId[requestId] = _boxId;
        emit openBoxRequested(requestId);
    }

    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) internal override {
        address owner = RequestIdToOwner[requestId];
        uint _boxId = box.mintBox(requestId);
        BOX storage box = boxes[_boxId];
        
        uint256 chancePercentage = randomness % 100;
        RARITY rarity;

        if (box.box_rarity == BOX_RARITY.common) {
            if (chancePercentage > 41) {
                shinobiRarity = RARITY.academy_Student;
            } else if (chancePercentage > 21 && chancePercentage <= 41) {
                shinobiRarity = SHINOBI_RARITY.genin;
            } else if (chancePercentage > 11 && chancePercentage <= 21) {
                shinobiRarity = SHINOBI_RARITY.chunin;
            } else if (chancePercentage > 4 && chancePercentage <= 11) {
                shinobiRarity = SHINOBI_RARITY.tokubetsu_jonin;
            } else if (chancePercentage > 1 && chancePercentage <= 4) {
                shinobiRarity = SHINOBI_RARITY.jonin;
            } else if (chancePercentage == 1) {
                shinobiRarity = SHINOBI_RARITY.kage;
            }
        } else if (box.box_rarity == BOX_RARITY.epic) {
            if (chancePercentage > 64) {
                shinobiRarity = SHINOBI_RARITY.academy_Student;
            } else if (chancePercentage > 39 && chancePercentage <= 64) {
                shinobiRarity = SHINOBI_RARITY.genin;
            } else if (chancePercentage > 19 && chancePercentage <= 39) {
                shinobiRarity = SHINOBI_RARITY.chunin;
            } else if (chancePercentage > 4 && chancePercentage <= 19) {
                shinobiRarity = SHINOBI_RARITY.tokubetsu_jonin;
            } else if (chancePercentage > 1 && chancePercentage <= 4) {
                shinobiRarity = SHINOBI_RARITY.jonin;
            } else if (chancePercentage == 1) {
                shinobiRarity = SHINOBI_RARITY.kage;
            }
        } else if (box.box_rarity == BOX_RARITY.legendary) {
            if (chancePercentage > 83) {
                shinobiRarity = SHINOBI_RARITY.genin;
            } else if (chancePercentage > 43 && chancePercentage <= 83) {
                shinobiRarity = SHINOBI_RARITY.chunin;
            } else if (chancePercentage > 13 && chancePercentage <= 43) {
                shinobiRarity = SHINOBI_RARITY.tokubetsu_jonin;
            } else if (chancePercentage > 5 && chancePercentage <= 13) {
                shinobiRarity = SHINOBI_RARITY.jonin;
            } else if (chancePercentage == 1 && chancePercentage <= 5) {
                shinobiRarity = SHINOBI_RARITY.kage;
            }
        }


        nft.mint(msg.sender,  robotId,
            attack,
            defence,
            tokenURI,
            readyTime,
            power,
            rarity
            );
        
        robots.push(
            ROBOT({
                id: boxId,
                attack: 1,
                defence: 1,
                tokenURI: "",
                readyTime: block.timestamp,
                power: ROBOT_TYPE.lendario,
                rarity: RARITY.common
            });
        );
    }
}
