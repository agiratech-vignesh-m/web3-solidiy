const {ethers} = require("hardhat");

async function deployScript(){

    console.log("Deploying the custom Eventbrite Ticketing contract ::");

    const Register = await ethers.getContractFactory("contracts/Projects/Eventbrite/Without_Proxy/Tickets.sol:Ticketing");
    const register = await Register.deploy("0xB0C6295409222c28d212137FD824e92f9ed425aC", "0x31501056fc90FDc737F861B743F4124B63adE0C7");
    await register.deployed();

    console.log("The deployed custom Eventbrite Ticketing smart contract address =>  ", register.address);
}

deployScript();
