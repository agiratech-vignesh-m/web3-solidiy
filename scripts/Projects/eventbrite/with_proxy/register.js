const {ethers, upgrades} = require("hardhat");
async function setup(){
    console.log("This setup deploys two contracts please check the deployed wallet address");
    const register = await ethers.getContractFactory("contracts/Projects/Eventbrite/With_Proxy/Registration.sol:Registration");
    const Register = await upgrades.deployProxy(register);
    await Register.deployed();
    console.log("The contract has been deployed and this is proxy contract address",Register.address);
}
setup().catch((err)=>{
    console.log("The contract has failed to deploy", err);
})
