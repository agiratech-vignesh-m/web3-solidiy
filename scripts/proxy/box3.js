const {ethers, upgrades} = require("hardhat");

const PROXY = "0xc72555ca03B7A5Bc5b7aA4f335361522245Ba8a1"

async function main(){

  const BoxV3 = await ethers.getContractFactory("contracts/Training/proxy/BoxV3.sol:BoxV3");
  
  console.log("Proxy Upgrading.....!")
  const upgradeV3 = await upgrades.upgradeProxy(PROXY, BoxV3);

  console.log("Upgrade successfully:", upgradeV3.address);
}

main()
