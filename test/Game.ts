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

    // Obter os saldos iniciais do proprietário do contrato e dos jogadores
    const ownerBalanceBefore = await rewardToken.balanceOf(owner.address);
    const addr1BalanceBefore = await rewardToken.balanceOf(addr1.address);
    const addr2BalanceBefore = await rewardToken.balanceOf(addr2.address);

    // Mint reward tokens to addr1 and addr2 for testing
    const rewardAmount = ethers.parseEther("10"); // Adjust the amount as needed
    await rewardToken.connect(owner).transfer(addr1.address, rewardAmount);
    await rewardToken.connect(owner).transfer(addr2.address, rewardAmount);

    // Mint robots for addr1 and addr2
    const mintingFeeInEth = await factory.mintingFeeInEth();
    const res = await factory
      .connect(addr1)
      .mintRobotWithEth({ value: mintingFeeInEth });
    await factory.connect(addr2).mintRobotWithEth({ value: mintingFeeInEth });

    console.log(`Minted robots to ${res}`);

    const robotId1 = 0; // First robot minted to addr1
    const robotId2 = 1; // Second robot minted to addr2

    // Verify ownership of the robots
    const ownerOfRobot1 = await robotsNFT.ownerOf(robotId1);
    const ownerOfRobot2 = await robotsNFT.ownerOf(robotId2);
    console.log(`Owner of Robot 1: ${ownerOfRobot1}`); // Should be addr1.address
    console.log(`Owner of Robot 2: ${ownerOfRobot2}`); // Should be addr2.address

    // Ensure the correct ownership
    expect(ownerOfRobot1).to.equal(addr1.address);
    expect(ownerOfRobot2).to.equal(addr2.address);

    // Approve and create arena with addr2's robot
    await robotsNFT.connect(addr2).approve(fighting.getAddress(), robotId2);
    await rewardToken
      .connect(addr2)
      .approve(fighting.getAddress(), ethers.parseEther("1")); // Use the correct amount
    await fighting.connect(addr2).createArena(robotId2);

    // Approve and enter arena with addr1's robot
    await robotsNFT.connect(addr1).approve(fighting.getAddress(), robotId1);
    await rewardToken
      .connect(addr1)
      .approve(fighting.getAddress(), ethers.parseEther("1")); // Use the correct amount
    await fighting.connect(addr1).enterArena(0, robotId1);

    // Obter os saldos finais do proprietário do contrato e dos jogadores após as transações
    const ownerBalanceAfter = await rewardToken.balanceOf(owner.address);
    const addr1BalanceAfter = await rewardToken.balanceOf(addr1.address);
    const addr2BalanceAfter = await rewardToken.balanceOf(addr2.address);

    // Calcular quanto foi adicionado ao saldo do proprietário do contrato e dos jogadores
    const ownerBalanceDiff = ownerBalanceAfter - ownerBalanceBefore;
    const addr1BalanceDiff = addr1BalanceAfter - addr1BalanceBefore;
    const addr2BalanceDiff = addr2BalanceAfter - addr2BalanceBefore;

    console.log(
      `Owner Balance Change: ${ethers.formatEther(ownerBalanceDiff)} REWARD`
    );
    console.log(
      `Address 1 Balance Change: ${ethers.formatEther(addr1BalanceDiff)} REWARD`
    );
    console.log(
      `Address 2 Balance Change: ${ethers.formatEther(addr2BalanceDiff)} REWARD`
    );
  });
});
