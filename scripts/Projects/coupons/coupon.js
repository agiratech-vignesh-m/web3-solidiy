const {ethers} = require("hardhat");

async function deployScript(){
    console.log("Deploying the custom Coupon smart contract ::");
    const baseC = await ethers.getContractFactory("contracts/Projects/Coupons/CouponContract.sol:Coupon");
    const deployC = await baseC.deploy("0xdD7eC140DD60282100e24Df8EfB5b23feC522748");
    await deployC.deployed();
    console.log("The deployed custom Coupon smart contract address =>  ", deployC.address);
}

deployScript();
