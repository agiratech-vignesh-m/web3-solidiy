const {ethers} = require("hardhat");

async function deployScript(){
    console.log("Deploying the custom Coupon smart contract ::");
    const baseC = await ethers.getContractFactory("contracts/Projects/CouponsAndCred/CouponContract.sol:Coupon");
    const deployC = await baseC.deploy("0xdE5Cee9Ad1A89a08532a1A74cD1e50f0a84bFBeF");
    await deployC.deployed();
    console.log("The deployed custom Coupon smart contract address =>  ", deployC.address);
}

deployScript();
