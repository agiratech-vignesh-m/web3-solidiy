const {ethers} = require("hardhat");

async function deployScript(){

    console.log("Deploying the custom Eventbrite Ticketing contract ::");

    const Ticket = await ethers.getContractFactory("contracts/Projects/Eventbrite/Without_Proxy/Tickets.sol:Ticketing");
    const ticket = await Ticket.deploy("0x7Fcc2c26c9874384d7803B53448f3a12E1eDC962", "0x0054C565d4dbe9ebe2C6241CC19E6d0150f5BB8f");
    await ticket.deployed();

    console.log("The deployed custom Eventbrite Ticketing smart contract address =>  ", ticket.address);
}

deployScript();
