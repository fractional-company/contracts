const { ethers } = require("hardhat");

async function main() {

    const [deployer] = await ethers.getSigners();
  
    console.log(
      "Deploying contracts with the account:",
      deployer.address
    );
    
    console.log("Account balance:", (await deployer.getBalance()).toString());

    const Token = await ethers.getContractFactory("ERC721PresetMinterPauserAutoId");
    const token = await Token.deploy("test", "TEST", "https://test.test");
  
    const Settings = await ethers.getContractFactory("Settings");
    const settings = await Settings.deploy();

    await settings.addAllowedNFT(token.address);

    console.log("Settings address:", settings.address);

    const Factory = await ethers.getContractFactory("ERC721VaultFactory");
    const factory = await Factory.deploy(settings.address);
  
    console.log("Factory address:", factory.address);

    await token.mint(deployer.address);
    await token.setApprovalForAll(factory.address, true);

    await factory.mint("testFractions", "TESTF", token.address, 0, "100000000000000000000", "10000000000000000000", 50);

    const vaultAddress = await factory.vaults(0);

    console.log("Vault address:", vaultAddress);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });