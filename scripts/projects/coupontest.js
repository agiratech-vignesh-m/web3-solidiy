const {ethers} = require("hardhat");

async function deployScript(){
    console.log("Deploying the custom NFT smart contract ::");
    const baseC = await ethers.getContractFactory("contracts/Projects/Coupon.sol:CouponContract");
    const deployC = await baseC.deploy("0x1E11466353f4D937Ea1302a29cB119A7c6792Ce5");
    await deployC.deployed();
    console.log("The deployed custom NFT smart contract address =>  ", deployC.address);
}

deployScript();
