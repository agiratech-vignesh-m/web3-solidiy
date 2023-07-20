const {ethers} = require("hardhat");

async function deployScript(){

    console.log("Deploying the custom Eventbrite Token contract ::");

    const Register = await ethers.getContractFactory("contracts/Projects/Eventbrite/Without_Proxy/Ticmet.sol:Ticmet");
    const register = await Register.deploy("100000000");
    await register.deployed();

    console.log("The deployed custom Eventbrite Token smart contract address =>  ", register.address);
}

deployScript();
