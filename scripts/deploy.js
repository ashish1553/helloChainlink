const main = async () => {
	try {

		// Deploying Mock Aggregator
		const MockPriceFeed = await ethers.getContractFactory("MockV3Aggregator");
		const deployedMockPriceFeed = await MockPriceFeed.deploy(8, 2094729000000);
		await deployedMockPriceFeed.deployed();
		console.log("MockV3Aggregator deployed to: ", deployedMockPriceFeed.address);


		// Deploying BullBear
		const nftContractFactory = await ethers.getContractFactory(
			"BullBear"
		);
		let updateInterval = 7200;
		const nftContract = await nftContractFactory.deploy(updateInterval, deployedMockPriceFeed.address);
		await nftContract.deployed();
		console.log("Bull&Bear Contract deployed to: ", nftContract.address);

		process.exit(0);
	} catch (error) {
		console.log(error);
		process.exit(1);
	}
};

main();