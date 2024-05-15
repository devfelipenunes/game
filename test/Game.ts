import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";

describe("Lock", function () {
  async function deploy() {
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const RobotsNFT = await hre.ethers.getContractFactory("RobotsNFT");
    const robotsNFT = await RobotsNFT.deploy();

    const RewardToken = await hre.ethers.getContractFactory("RewardToken");
    const rewardToken = await RewardToken.deploy();

    const RobotMarket = await hre.ethers.getContractFactory("RobotMarket");
    const robotMarket = await RobotMarket.deploy();

    const Factory = await hre.ethers.getContractFactory("Factory");
    const factory = await Factory.deploy();

    const Fighting = await hre.ethers.getContractFactory("Fighting");
    const fighting = await Fighting.deploy();

    await factory.initialize(rewardToken.getAddress(), robotsNFT.getAddress());

    await rewardToken.setMinter(factory.getAddress());
    await robotsNFT.setMinter(factory.getAddress());

    return {
      robotsNFT,
      owner,
      otherAccount,
      rewardToken,
      robotMarket,
      fighting,
      factory,
    };
  }

  // it("Should mint a robot with ETH", async function () {
  //   const { robotsNFT, owner, otherAccount, factory, rewardToken } =
  //     await loadFixture(deploy);
  //   const mintingFeeInEth = await factory.mintingFeeInEth();
  //   await factory.mintRobotWithEth({ value: mintingFeeInEth });
  //   const robotId = 0;
  //   const robot = await robotsNFT.robots(robotId);
  //   expect(robot.attack).to.be.within(1, 10);
  //   expect(robot.defence).to.be.within(1, 10);
  // });

  it("Should allow robots to battle and reward the winner", async function () {
    const { robotsNFT, owner, otherAccount, factory, fighting, rewardToken } =
      await loadFixture(deploy);

    const mintingFeeInEth = await factory.mintingFeeInEth();
    // const mintingFeeInEth1 = await factory.mintingFeeInEth();
    // Mint two robots
    await factory.connect(owner).mintRobotWithEth({ value: mintingFeeInEth });
    // await factory.mintRobotWithEth({ value: mintingFeeInEth });

    const robotId0 = 0;
    const robot0 = await robotsNFT.robots(robotId0);

    await factory
      .connect(otherAccount)
      .mintRobotWithEth({ value: mintingFeeInEth });
    // await factory.mintRobotWithEth({ value: mintingFeeInEth1 });
    const robotId1 = 1;
    const robot1 = await robotsNFT.robots(robotId1);

    // const robotId2 = 2;
    // const robot2 = await robotsNFT.robots(robotId2);

    // await robotsNFT.transferFrom(owner.address, otherAccount.address, robotId2);
    // const arena = await fighting.createArena(robotId1);
    console.log(robot0);
    console.log(robot1);
  });
});
