// const {ethers, upgrades} = require("hardhat");
// const COUNT = 10;

async function main(){
  const Register = await ethers.getContractFactory("contracts/Projects/Eventbrite/With_Proxy/Registration.sol:Registration");
  console.log("Deploying Registration contract with proxy :");
  
  const register = await upgrades.deployProxy(Register, {
    initializer: "initialize"
  });
  

  await register.deployed();
  console.log("The deployed proxy smart contract address =>  ", register.address);
}

main()