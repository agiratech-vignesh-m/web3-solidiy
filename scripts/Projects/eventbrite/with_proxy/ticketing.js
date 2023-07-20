const {ethers, upgrades} = require("hardhat");
async function setup(){
    console.log("This setup deploys two contracts please check the deployed wallet address");
    const ticketing = await ethers.getContractFactory("contracts/Projects/Eventbrite/With_Proxy/Ticketing.sol:Ticketing");
    const Ticketing = await upgrades.deployProxy(ticketing,
    ['0xae06008De9c38383Ee5B0271D837693991e0610b',
    '0x11B2042CeC93951177Ef2F5B1D01728ff4cC1833']);
    // const deployC = await upgrades.deployProxy(baseC,{kind:'uups'});
    await Ticketing.deployed();
    console.log("The Ticketing contract has been deployed and this is proxy contract address",Ticketing.address);
}
setup().catch((err)=>{
    console.log("The contract has failed to deploy", err);
})