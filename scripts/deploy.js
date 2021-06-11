const { ethers } = require("hardhat");

async function main() {

    const [deployer] = await ethers.getSigners();
  
    console.log(
      "Deploying contracts with the account:",
      deployer.address
    );
    
    console.log("Account balance:", (await deployer.getBalance()).toString());

    const IndexFactory = await ethers.getContractFactory("IndexERC721Factory");
    const indexFactory = await IndexFactory.deploy();

    console.log(`> npx hardhat verify --network mainnet ${indexFactory.address}`);

    const Settings = await ethers.getContractFactory("Settings");
    const settings = await Settings.deploy();

    console.log(`> npx hardhat verify --network mainnet ${settings.address}`);

    const Factory = await ethers.getContractFactory("ERC721VaultFactory");
    const factory = await Factory.deploy(settings.address);
  
    console.log(`> npx hardhat verify --network mainnet ${factory.address} ${settings.address}`);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });