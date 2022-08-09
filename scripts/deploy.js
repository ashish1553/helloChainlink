const main = async () => {
  try {
    // Deploying Rebel Contract.
    const nftContractFactory = await ethers.getContractFactory(
      "BullBear"
    );
    let updateInterval = 10;
    let pricefeedAddress = '0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676';
    const nftContract = await nftContractFactory.deploy(updateInterval, pricefeedAddress);
    await nftContract.deployed();
    console.log("Bull&Bear Contract deployed to: ", nftContract.address);

    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

main();