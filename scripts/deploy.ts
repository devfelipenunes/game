const { ethers } = require("hardhat");

async function deployContracts() {
  const [owner, addr1, addr2] = await ethers.getSigners();

  // Deploy RewardToken
  console.log("Deploying RewardToken...");
  const RewardToken = await ethers.getContractFactory("RewardToken");
  const rewardToken = await RewardToken.deploy();
  await rewardToken.waitForDeployment();
  console.log("RewardToken deployed to:", rewardToken.target);

  // Deploy RobotsNFT
  console.log("Deploying RobotsNFT...");
  const RobotsNFT = await ethers.getContractFactory("RobotsNFT");
  const robotsNFT = await RobotsNFT.deploy();
  await robotsNFT.waitForDeployment();
  console.log("RobotsNFT deployed to:", robotsNFT.target);

  // Deploy Factory
  console.log("Deploying Factory...");
  const Factory = await ethers.getContractFactory("Factory");
  const factory = await Factory.deploy();
  await factory.waitForDeployment();
  console.log("Factory deployed to:", factory.target);

  // Deploy Fighting
  console.log("Deploying Fighting...");
  const Fighting = await ethers.getContractFactory("Fighting");
  const fighting = await Fighting.deploy();
  await fighting.waitForDeployment();
  console.log("Fighting deployed to:", fighting.target);

  // Deploy Growing
  console.log("Deploying Growing...");
  const Growing = await ethers.getContractFactory("Growing");
  const growing = await Growing.deploy();
  await growing.waitForDeployment();
  console.log("Growing deployed to:", growing.target);

  // Deploy RobotMarket
  console.log("Deploying RobotMarket...");
  const RobotMarket = await ethers.getContractFactory("RobotMarket");
  const robotMarket = await RobotMarket.deploy();
  await robotMarket.waitForDeployment();
  console.log("RobotMarket deployed to :", robotMarket.target);

  // Initialize contracts
  console.log("Initializing contracts...");
  await factory.initialize(rewardToken.target, robotsNFT.target);
  await fighting.initialize(rewardToken.target, robotsNFT.target);
  await growing.initialize(rewardToken.target, robotsNFT.target);
  await robotMarket.initialize(rewardToken.target, robotsNFT.target);

  // Set roles and minters
  console.log("Configuring permissions and minters...");
  await rewardToken.setMinter(factory.target);
  await rewardToken.setMinter(robotMarket.target);
  await rewardToken.setMinter(growing.target);
  await rewardToken.setMinter(fighting.target);
  await robotsNFT.setMinter(factory.target);
  await robotsNFT.setMinter(robotMarket.target);
  await robotsNFT.setMinter(growing.target);

  console.log("Deployment complete!");

  await run("verify:verify", {
    address: rewardToken.target,
    constructorArguments: [],
  });

  await run("verify:verify", {
    address: robotsNFT.target,
    constructorArguments: [],
  });

  await run("verify:verify", {
    address: factory.target,
    constructorArguments: [],
  });

  await run("verify:verify", {
    address: fighting.target,
    constructorArguments: [],
  });

  await run("verify:verify", {
    address: growing.target,
    constructorArguments: [],
  });

  await run("verify:verify", {
    address: robotMarket.target,
    constructorArguments: [],
  });
  console.log("Deployment and verification complete!");
}

// Execute the function to deploy contracts
deployContracts().catch((error) => {
  console.error("Error deploying contracts:", error);
  process.exit(1);
});
