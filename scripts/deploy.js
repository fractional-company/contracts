async function main() {

    const [deployer] = await ethers.getSigners();
  
    console.log(
      "Deploying contracts with the account:",
      deployer.address
    );
    
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    const Settings = await ethers.getContractFactory("Settings");
    const settings = await Settings.deploy();

    console.log("Settings address:", settings.address);

    const Factory = await ethers.getContractFactory("ERC721VaultFactory");
    const factory = await Factory.deploy(settings.address);
  
    console.log("Factory address:", factory.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });