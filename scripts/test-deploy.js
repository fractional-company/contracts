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

    console.log(`> npx hardhat verify --network goerli ${token.address} "test" "TEST" "https://test.test"`);
  
    const Token2 = await ethers.getContractFactory("ERC721PresetMinterPauserAutoId");
    const token2 = await Token2.deploy("test2", "TEST2", "https://test2.test2");

    console.log(`> npx hardhat verify --network goerli ${token2.address} "test2" "TEST2" "https://test2.test2"`);

    const IndexFactory = await ethers.getContractFactory("IndexERC721Factory");
    const indexFactory = await IndexFactory.deploy();

    console.log(`> npx hardhat verify --network goerli ${indexFactory.address}`);

    const Settings = await ethers.getContractFactory("Settings");
    const settings = await Settings.deploy();

    console.log(`> npx hardhat verify --network goerli ${settings.address}`);

    const Factory = await ethers.getContractFactory("ERC721VaultFactory");
    const factory = await Factory.deploy(settings.address);
  
    console.log(`> npx hardhat verify --network goerli ${factory.address} ${settings.address}`);

    const mint = await token.mint(deployer.address);
    console.log(mint)
    const approve = await token.setApprovalForAll(factory.address, true);
    console.log(approve)

    const minted = await factory.mint("testFractions", "TESTF", token.address, 0, "100000000000000000000", "10000000000000000000", 50);
    console.log(minted)
    const vaultAddress = await factory.vaults(0);

    console.log(`> npx hardhat verify --network goerli ${vaultAddress} ${settings.address} ${deployer.address} ${token.address} 0 100000000000000000000 10000000000000000000 50 "testFractions" "TESTF"`)

    console.log("Vault address:", vaultAddress);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });