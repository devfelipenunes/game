//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Growing.sol";

/**
 * @title A market contract
 * @notice Robots can only be bought with the reward token
 */
contract RobotMarket is Growing {
    function putOnMarket(uint256 robotId, uint256 price) external virtual {
        address owner = nft.ownerOf(robotId);
        if (owner != msg.sender) revert NotOwnerOf(robotId);
        if (price == 0) revert CannotSellForZero();

        nft.safeTransferFrom(owner, address(this), robotId);
        market[robotId] = price;
        oldOwner[robotId] = owner;
        emit putOnMarketEvent(owner, robotId, price);
    }

    function withdrawFromMarket(uint256 robotId) external virtual {
        if (market[robotId] == 0) revert RobotIsNotOnMarket(robotId);

        address owner = oldOwner[robotId];
        if (owner != msg.sender) revert NotOwnerOf(robotId);

        delete oldOwner[robotId];
        delete market[robotId];
        nft.safeTransferFrom(address(this), owner, robotId);
        emit withdrawFromMarketEvent(owner, robotId);
    }

    function buyRobot(uint256 robotId) external virtual {
        if (market[robotId] == 0) revert RobotIsNotOnMarket(robotId);

        uint256 price = market[robotId];
        token.transferFrom(msg.sender, address(this), price);
        // Send (price - tax) tokens to the seller
        token.transfer(
            oldOwner[robotId],
            (price * (1000 - 10 * marketTax)) / 1000
        );

        delete oldOwner[robotId];
        delete market[robotId];
        nft.safeTransferFrom(address(this), msg.sender, robotId);
        emit buyRobotEvent(msg.sender, robotId, price);
    }

    function putOnAuction(
        uint256 robotId,
        uint256 startingPrice,
        uint32 auctionTime
    ) external virtual {
        address owner = nft.ownerOf(robotId);
        if (owner != msg.sender) revert NotOwnerOf(robotId);

        if (startingPrice == 0) revert CannotSellForZero();
        require(auctionTime > 0, "Auction time should be > 0 !");

        nft.safeTransferFrom(owner, address(this), robotId);
        oldOwner[robotId] = owner;
        auctions[robotId] = Auction(
            uint32(block.timestamp) + auctionTime,
            address(0),
            startingPrice
        );
        emit putOnAuctionEvent(msg.sender, robotId, startingPrice, auctionTime);
    }

    function withdrawFromAuction(uint256 robotId) external virtual {
        Auction memory tempAuction = auctions[robotId]; // saving gas
        if (tempAuction.highestBid == 0) revert RobotIsNotOnAuction(robotId);

        address owner = oldOwner[robotId];
        if (owner != msg.sender) revert NotOwnerOf(robotId);
        require(
            tempAuction.highestBidder == address(0),
            "Someone placed a bid!"
        );

        delete oldOwner[robotId];
        delete auctions[robotId];
        nft.safeTransferFrom(address(this), owner, robotId);
        emit withdrawFromAuctionEvent(msg.sender, robotId);
    }

    function bidOnAuction(uint256 robotId, uint256 bid) external virtual {
        Auction memory tempAuction = auctions[robotId];
        if (tempAuction.highestBid == 0) revert RobotIsNotOnAuction(robotId);
        require(
            tempAuction.endTime > block.timestamp,
            "The auction has ended!"
        );

        // The first bid can be equal to 'startingPrice'
        if (tempAuction.highestBidder == address(0)) {
            if (bid < tempAuction.highestBid)
                revert BidIsSmall(tempAuction.highestBid);
        } else if (bid <= tempAuction.highestBid)
            revert BidIsSmall(tempAuction.highestBid);

        token.transferFrom(msg.sender, address(this), bid);

        // If not the first bid then send previous 'highestBid' to previous 'highestBidder'
        if (tempAuction.highestBidder != address(0)) {
            token.transfer(tempAuction.highestBidder, tempAuction.highestBid);
        }

        auctions[robotId].highestBid = bid;
        auctions[robotId].highestBidder = msg.sender;
        emit bidOnAuctionEvent(msg.sender, robotId, bid);
    }

    // Anyone can end an auction
    function endAuction(uint256 robotId) external virtual {
        Auction memory tempAuction = auctions[robotId];
        if (tempAuction.highestBid == 0) revert RobotIsNotOnAuction(robotId);
        require(
            tempAuction.endTime < block.timestamp,
            "The auction hasn't ended yet!"
        );

        address owner = oldOwner[robotId];
        delete oldOwner[robotId];
        delete auctions[robotId];

        // Checks for any bids
        if (tempAuction.highestBidder != address(0)) {
            token.transfer(
                owner,
                (tempAuction.highestBid * (1000 - 10 * auctionTax)) / 1000
            );
            nft.safeTransferFrom(
                address(this),
                tempAuction.highestBidder,
                robotId
            );
        } else {
            nft.safeTransferFrom(address(this), owner, robotId);
        }

        emit endAuctionEvent(msg.sender, robotId);
    }
}
