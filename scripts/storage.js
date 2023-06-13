const {ethers} = require("hardhat");

async function deployScript(){
    console.log("Deploying the smart contract ::");
    const baseC = await ethers.getContractFactory("contracts/Storage.sol:Storage");
    const deployC = await baseC.deploy(10);
    await deployC.deployed();
    console.log("The deployed contract address =>  ", deployC.address);
}

deployScript();