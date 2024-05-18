import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre, { ethers } from "hardhat";

describe("Lock", function () {
  async function deploy() {
    const [owner, addr1, addr2] = await hre.ethers.getSigners();

    const RewardToken = await hre.ethers.getContractFactory("RewardToken");
    const RobotsNFT = await hre.ethers.getContractFactory("RobotsNFT");
    const Factory = await hre.ethers.getContractFactory("Factory");
    const Fighting = await hre.ethers.getContractFactory("Fighting");
    const Growing = await hre.ethers.getContractFactory("Growing");
    const RobotMarket = await hre.ethers.getContractFactory("RobotMarket");

    // Deploy the contracts
    const rewardToken = await RewardToken.deploy();
    const robotsNFT = await RobotsNFT.deploy();
    const factory = await Factory.deploy();
    const fighting = await Fighting.deploy();
    const growing = await Growing.deploy();
    const robotMarket = await RobotMarket.deploy();

    // Initialize contracts that need initialization
    await factory.initialize(rewardToken.getAddress(), robotsNFT.getAddress());
    await fighting.initialize(rewardToken.getAddress(), robotsNFT.getAddress());
    await growing.initialize(rewardToken.getAddress(), robotsNFT.getAddress());
    await robotMarket.initialize(
      rewardToken.getAddress(),
      robotsNFT.getAddress()
    );

    // Set the roles and minters
    await rewardToken.setMinter(factory.getAddress());
    await rewardToken.setMinter(robotMarket.getAddress());
    await rewardToken.setMinter(growing.getAddress());
    await rewardToken.setMinter(fighting.getAddress());
    await robotsNFT.setMinter(factory.getAddress());
    await robotsNFT.setMinter(robotMarket.getAddress());
    await robotsNFT.setMinter(growing.getAddress());

    return {
      robotsNFT,
      owner,
      rewardToken,
      robotMarket,
      fighting,
      growing,
      factory,
      addr1,
      addr2,
    };
  }

  it("Should create an arena and enter a fight", async function () {
    const { robotsNFT, owner, addr2, addr1, factory, fighting, rewardToken } =
      await loadFixture(deploy);

    // Mint reward tokens to addr1 and addr2 for testing
    const rewardAmount = ethers.parseEther("10"); // Adjust the amount as needed
    await rewardToken.connect(owner).transfer(addr1.address, rewardAmount);
    await rewardToken.connect(owner).transfer(addr2.address, rewardAmount);

    // Mint robots for addr1 and addr2
    const mintingFeeInEth = await factory.mintingFeeInEth();
    const res = await factory.mintRobot("Robot");
    await res.wait();
    const robots = await robotsNFT.robots(1);

    console.log(`Minted robots to ${robots}`);
  });
});
