// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utils.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";
// import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


contract Box is ERC1155, Utils {
    uint256 public deployedAt;
    uint256 public currentBoxMinted;

    enum TYPE {
        normal,
        lendario,
        epico
    }

    enum BOX_RARITY {
        common,
        epic,
        legendary
    }

    enum BOX_STATUS {
        not_used,
        used
    }

    enum RARITY {
        common,
        epic,
        legendary
    }

    mapping(bytes32 => uint) public requestIdToShinobiId;
    mapping(bytes32 => uint) public requestIdToBoxId;
    bytes32 internal keyHash;
    uint256 internal fee;

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

    // AggregatorV3Interface internal priceFeed;

    constructor(
        address vrfCoordinator,
        address link,
        bytes32 _keyHash,
        uint256 _fee,
        string memory uri
    ) ERC1155("") {
        keyHash = _keyHash;
        fee = _fee;

        BoxPrice[BOX_RARITY.common] = 50;
        BoxPrice[BOX_RARITY.epic] = 100;
        BoxPrice[BOX_RARITY.legendary] = 150;

        deployedAt = block.timestamp;

        BoxRarityIndex[0] = BOX_RARITY.common;
        BoxRarityIndex[1] = BOX_RARITY.epic;
        BoxRarityIndex[2] = BOX_RARITY.legendary;
    }

    function getBoxPrice(uint256 _price) public view returns (uint256) {
        // (, int256 price, , , ) = priceFeed.latestRoundData();

        // uint256 newPrice = uint256(price * 10**10);
        uint256 newPrice = uint256(1 * 10**10);
        return ((_price * 10**18) / newPrice);
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

    // function openBox(uint _boxId, bytes32 requestId) public {
    //     BOX memory box = boxes[_boxId];
    //     // bytes32 requestId = requestRandomness(keyHash, fee);
    //     BoxRarityOfRequestId[requestId] = box.box_rarity;
    //     RequestIdToOwner[requestId] = msg.sender;
    //     requestIdToShinobiId[requestId] = _boxId;
    //     requestIdToBoxId[requestId] = _boxId;
    //     emit openBoxRequested(requestId);
    // }

    function openBox(bytes32 requestId, uint256 randomness) internal override {
        address owner = RequestIdToOwner[requestId];
        uint _boxId = requestIdToBoxId[requestId];
        BOX storage box = boxes[_boxId];

        uint256 chancePercentage = randomness % 100;
        RARITY rarity;

        if (box.box_rarity == BOX_RARITY.common) {
            if (chancePercentage > 41) {
                rarity = RARITY.common;
            } else if (chancePercentage > 21) {
                rarity = RARITY.epic;
            } else {
                rarity = RARITY.legendary;
            }
        } else if (box.box_rarity == BOX_RARITY.epic) {
            if (chancePercentage > 64) {
                rarity = RARITY.common;
            } else if (chancePercentage > 39) {
                rarity = RARITY.epic;
            } else {
                rarity = RARITY.legendary;
            }
        } else if (box.box_rarity == BOX_RARITY.legendary) {
            if (chancePercentage > 83) {
                rarity = RARITY.common;
            } else if (chancePercentage > 43) {
                rarity = RARITY.epic;
            } else {
                rarity = RARITY.legendary;
            }
        }

        nft.mint(msg.sender, 1, 3, 4, "URI", 2, 1, rarity);
        RobotsNFT.robots.push(RobotsNFT.ROBOT({
            id: 1,
            attack: 1,
            defence: 1,
            tokenURI: "",
            readyTime: block.timestamp,
            power: TYPE.normal,
            rarity: rarity
        }));
    }
}
