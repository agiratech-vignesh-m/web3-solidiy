const {ethers, upgrades} = require("hardhat");

const PROXY = "0xcdB55422A22C4fa12360a455E667B038Ea01E6B9"

async function main(){

  const BoxV2 = await ethers.getContractFactory("contracts/Training/proxy/BoxV2.sol:BoxV2");
  
  console.log("Proxy Upgrading.....!")
  await upgrades.upgradeProxy(PROXY, BoxV2);

  console.log("Upgrade successfully");
}

main()
