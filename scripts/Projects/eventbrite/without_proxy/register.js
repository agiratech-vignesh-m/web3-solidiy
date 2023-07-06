const {ethers} = require("hardhat");

async function deployScript(){

    console.log("Deploying the custom Eventbrite Registration contract ::");

    const Register = await ethers.getContractFactory("contracts/Projects/Eventbrite/Without_Proxy/Registration.sol:Registration");
    const register = await Register.deploy();
    await register.deployed();

    console.log("The deployed custom Eventbrite Registration smart contract address =>  ", register.address);
}

deployScript();
