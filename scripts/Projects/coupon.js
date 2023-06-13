const {ethers} = require("hardhat");

async function deployScript(){
    console.log("Deploying the custom Coupon smart contract ::");
    const baseC = await ethers.getContractFactory("contracts/Projects/CouponContract.sol:Coupon");
    const deployC = await baseC.deploy("0xcBc1b58c9F0C8bb23E3C1d4b5B5BD87ED060DA1a");
    await deployC.deployed();
    console.log("The deployed custom Coupon smart contract address =>  ", deployC.address);
}

deployScript();
