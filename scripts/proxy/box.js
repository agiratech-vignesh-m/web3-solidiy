// const {ethers, upgrades} = require("hardhat");
// const COUNT = 10;

async function main(){
    const Box = await ethers.getContractFactory("contracts/Training/proxy/Box.sol:Box");
    console.log("Deploying Box :");
    
    const box = await upgrades.deployProxy(Box, {
      initializer: "initialize"
    });
    

    await box.deployed();
    console.log("The deployed proxy smart contract address =>  ", box.address);
}

main()
