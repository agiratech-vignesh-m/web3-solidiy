require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

const {
  MUMBAI_NETWROK, 
  PRIVATE_KEY_1, 
  MUMBAI_API, 
  AME_TESTNET_NETWORK, 
  AME_TESTNET_PRIVATE_KEY, 
  FIREFLY_PRIVATE_KEY_1, 
  LEO_PRIVATE_KEY,
  BHARATH_FIREFLY_PRIVATE_KEY_1,
  FIREFLY_BLOCKCHAIN_PRIVATE_KEY_1,
  FIREFLY_BLOCKCHAIN_PRIVATE_KEY_TEST,
  PRIVATE_BLOCKCHAIN_NETWORK,
  PRIVATE_BLOCKCHAIN_NETWORK_2,
  FIREFLY_BLOCKCHAIN_PRIVATE_KEY_NEW,
  PRIVATE_BLOCKCHAIN_NETWORK_OWN,
  FIREFLY_OWN_KEY
      } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.9",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.18",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      }
    ],
  },
  networks: {
    mumbai: {
      url: MUMBAI_NETWROK,
      accounts: [
        PRIVATE_KEY_1,
        // FIREFLY_PRIVATE_KEY_1,
        // LEO_PRIVATE_KEY,
        // BHARATH_FIREFLY_PRIVATE_KEY_1,
        // FIREFLY_BLOCKCHAIN_PRIVATE_KEY_1
      ],
    },
    ame_testnet: {
      url: AME_TESTNET_NETWORK,
      accounts: [AME_TESTNET_PRIVATE_KEY],
    },
    dc_network: {
      url: PRIVATE_BLOCKCHAIN_NETWORK,
      // url: PRIVATE_BLOCKCHAIN_NETWORK_OWN,
      // url: PRIVATE_BLOCKCHAIN_NETWORK_2,
      accounts: [
        FIREFLY_BLOCKCHAIN_PRIVATE_KEY_1,
        // FIREFLY_OWN_KEY,
        // FIREFLY_BLOCKCHAIN_PRIVATE_KEY_TEST,
        // FIREFLY_BLOCKCHAIN_PRIVATE_KEY_NEW
      ],
    }
  },
  etherscan : {
    apiKey : {
      polygonMumbai:MUMBAI_API,
    },
  },
};
