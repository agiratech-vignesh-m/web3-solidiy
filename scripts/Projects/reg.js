const {ethers} = require("hardhat");

async function deployScript(){
    console.log("Deploying the custom Registration smart contract ::");
    const baseC = await ethers.getContractFactory("contracts/Projects/Registration.sol:Registration");
    const deployC = await baseC.deploy();
    await deployC.deployed();
    console.log("The deployed custom Registration smart contract address =>  ", deployC.address);
}

deployScript();