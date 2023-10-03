const {ethers} = require("hardhat");

async function deployScript(){
    console.log("Deploying the custom Credentialing smart contract ::");
    const baseC = await ethers.getContractFactory("contracts/Projects/Coupons/Credentialing.sol:Credentialing");
    const deployC = await baseC.deploy();
    await deployC.deployed();
    console.log("The deployed custom Credentialing smart contract address =>  ", deployC.address);
}

deployScript();