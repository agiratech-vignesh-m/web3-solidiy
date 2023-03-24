require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

const {MUMBAI_NETWROK, PRIVATE_KEY_1, MUMBAI_API} = process.env;

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
    ],
  },
  networks: {
    mumbai: {
      url: MUMBAI_NETWROK,
      accounts: [PRIVATE_KEY_1],
    }
  },
  etherscan : {
    apiKey : {
      polygonMumbai:MUMBAI_API,
    },
  },
};
