const {ethers} = require("hardhat");

async function deployScript(){
    console.log("Deploying the custom DL smart contract ::");
    const baseC = await ethers.getContractFactory("contracts/Projects/DL/DL.sol:DreamLighter");
    const deployC = await baseC.deploy();
    await deployC.deployed();
    console.log("The deployed custom DL smart contract address =>  ", deployC.address);
}

deployScript();
