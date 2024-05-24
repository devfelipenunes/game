import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre, { ethers } from "hardhat";

describe("Robts", function () {
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

  function findEventArgs(logs: any, eventName: any) {
    let _event = null;
    for (const event of logs) {
      if (event.fragment && event.fragment.name == eventName) {
        _event = event.args;
      }
    }
    return _event;
  }

  it("Should create an arena and enter a fight", async function () {
    const { robotsNFT, owner, addr2, addr1, factory, fighting, rewardToken } =
      await loadFixture(deploy);

    const rewardAmount = ethers.parseEther("10");

    await rewardToken.connect(owner).transfer(addr1.getAddress(), rewardAmount);

    await factory.mintRobot("Ell Brabo");
    const robots1 = await robotsNFT.robots(1);

    const ownerRobot1 = await robotsNFT.ownerOf(1);
    await factory.connect(addr1).mintRobot("Ell Brabinho");
    const robots2 = await robotsNFT.robots(2);
    const ownerRobot2 = await robotsNFT.ownerOf(2);

    console.log(`
    LutadorID ${robots1[0]}
    Nome: ${robots1[3]}
    Atack: ${robots1[1]}
    Defesa: ${robots1[2]}
    Criador: ${ownerRobot1}
    `);
    console.log(`
    LutadorId ${robots2[0]}
    Nome: ${robots2[3]}
    Atack: ${robots2[1]}
    Defesa: ${robots2[2]}
    Criador: ${ownerRobot2}
    `);

    console.log(`
    Vai começar a luta entre ${robots2[3]} x ${robots1[3]}
    `);

    //
    await robotsNFT.approve(fighting.getAddress(), 1);
    await rewardToken.approve(fighting.getAddress(), ethers.parseEther("1"));
    const arena = await fighting.createArena(1);
    const arenaReceipt = await arena.wait();
    const resultArena = findEventArgs(arenaReceipt, "createArenaEvent");
    console.log(`
    Arena: ${resultArena[2]} criada com sucesso!!
    `);

    await robotsNFT.connect(addr1).approve(fighting.getAddress(), 2);
    await rewardToken
      .connect(addr1)
      .approve(fighting.getAddress(), ethers.parseEther("1"));
    const arena2 = await fighting.connect(addr1).createArena(2);
    const arenaReceipt2 = await arena2.wait();
    const resultArena2 = findEventArgs(arenaReceipt2, "createArenaEvent");

    console.log(`
    Arena: ${resultArena2[2]} criada com sucesso!!
    `);

    const arenas = await fighting.fetchArenas();

    console.log(arenas);

    await rewardToken
      .connect(addr1)
      .approve(fighting.getAddress(), ethers.parseEther("1"));

    const fight = await fighting.connect(addr1).enterArena(0, 2);
    console.log(`O ${robots2[3]} entrou na arena`);
    const fightReceipt = await fight.wait();
    const resultFight = await findEventArgs(fightReceipt, "fightingEvent");
    const winner = await robotsNFT.robots(resultFight[1]);
    console.log(`
      O Vencedor foi ${winner[3]}!
      `);
    console.log(await rewardToken.balanceOf(owner));
  });
});
