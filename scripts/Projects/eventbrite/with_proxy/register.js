// const {ethers, upgrades} = require("hardhat");
// const COUNT = 10;

async function main(){
    const Register = await ethers.getContractFactory("contracts/Projects/Eventbrite/With_Proxy/Registration.sol:Registration");
    console.log("Deploying Eventbrite Registration :");
    
    const register = await upgrades.deployProxy(Register, {
      initializer: "initialize"
    });
    

    await register.deployed();
    console.log("The deployed proxy smart contract address for Registration is =>  ", register.address);
}

main()