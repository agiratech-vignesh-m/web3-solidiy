const {ethers} = require("hardhat");

async function deployScript(){
    console.log("Deploying the smart contract ::");
    const baseC = await ethers.getContractFactory("contracts/EventTicket.sol:EventTicket");
    const deployC = await baseC.deploy(5);
    await deployC.deployed();
    console.log("The deployed contract address =>  ", deployC.address);
}

deployScript();

