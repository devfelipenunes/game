import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
      },
      {
        version: "0.8.4",
      },
      {
        version: "0.8.0",
      },
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    matictestnet: {
      url: process.env.RPC_URL,
      chainId: parseInt(`${process.env.CHAIN_ID}`),
      accounts: {
        mnemonic: process.env.SECRET,
      },
    },
  },
  etherscan: {
    apiKey: process.env.API_KEY,
  },
};

export default config;
