// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Chainlink Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// This import includes functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

// Dev imports
import "hardhat/console.sol";

contract BullBear is ERC721, ERC721Enumerable, ERC721URIStorage, KeeperCompatibleInterface, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    AggregatorV3Interface public pricefeed;

    /**
     * Use an interval in seconds and a timestamp to slow execution of Upkeep
     */
    uint256 public interval;
    uint256 public lastTimeStamp;

    int256 public currentPrice;

    // IPFS URIs for the dynamic nft graphics/metadata.
    // NOTE: These connect to my IPFS Companion node.
    // You should upload the contents of the /ipfs folder to your own node for development.
    string[] bullUrisIpfs = [
        "https://ipfs.io/ipfs/QmS1v9jRYvgikKQD6RrssSKiBTBH3szDK6wzRWF4QBvunR?filename=gamer_bull.json",
        "https://ipfs.io/ipfs/QmRsTqwTXXkV8rFAT4XsNPDkdZs5WxUx9E5KwFaVfYWjMv?filename=party_bull.json",
        "https://ipfs.io/ipfs/Qmc3ueexsATjqwpSVJNxmdf2hStWuhSByHtHK5fyJ3R2xb?filename=simple_bull.json"
    ];
    string[] bearUrisIpfs = [
        "https://ipfs.io/ipfs/QmQMqVUHjCAxeFNE9eUxf89H1b7LpdzhvQZ8TXnj4FPuX1?filename=beanie_bear.json",
        "https://ipfs.io/ipfs/QmP2v34MVdoxLSFj1LbGW261fvLcoAsnJWHaBK238hWnHJ?filename=coolio_bear.json",
        "https://ipfs.io/ipfs/QmZVfjuDiUfvxPM7qAvq8Umk3eHyVh7YTbFon973srwFMD?filename=simple_bear.json"
    ];

    event TokensUpdated(string marketTrend);

    // For testing with the mock on Rinkeby, pass in 10(seconds) for `updateInterval` and the address of my
    // deployed  MockPriceFeed.sol contract (0xD753A1c190091368EaC67bbF3Ee5bAEd265aC420).
    constructor(uint256 updateInterval, address _pricefeed) ERC721("Bull&Bear", "BBTK") {
        // Set the keeper update interval
        interval = updateInterval;
        lastTimeStamp = block.timestamp; //  seconds since unix epoch

        // set the price feed address to
        // BTC/USD Price Feed Contract Address on Goerli BTC/USD: https://goerli.etherscan.io/address/0xA39434A63A52E749F02807ae27335515BA4b07F7
        // or the MockPriceFeed Contract
        pricefeed = AggregatorV3Interface(_pricefeed); // To pass in the mock

        // set the price for the chosen currency pair.
        currentPrice = getLatestPrice();
    }

    function safeMint(address to) public {
        // Increment it so next time it's correct when we call .current()
        _tokenIdCounter.increment();

        // Current counter value will be the minted token's token ID.
        uint256 tokenId = _tokenIdCounter.current();

        // Mint the token
        _safeMint(to, tokenId);

        // Default to a bull NFT
        string memory defaultUri = bullUrisIpfs[0];
        _setTokenURI(tokenId, defaultUri);

        console.log("DONE!!! minted token ", tokenId, " and assigned token url: ", defaultUri);
    }

    function checkUpkeep( bytes calldata /* checkData */ ) external view override returns ( bool upkeepNeeded, bytes memory /*performData */ ){
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep( bytes calldata /* performData */ ) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
            int256 latestPrice = getLatestPrice();

            if (latestPrice == currentPrice) {
                // console.log("NO CHANGE -> returning!");
                return;
            }

            if (latestPrice < currentPrice) {
                // bear
                // console.log("ITS BEAR TIME");
                updateAllTokenUris("bear");
            } else {
                // bull
                // console.log("ITS BULL TIME");
                updateAllTokenUris("bull");
            }

            // update currentPrice
            currentPrice = latestPrice;
        } else {
            // console.log( " INTERVAL NOT UP!" );
            return;
        }
    }

    // Helpers
    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price,
            ,
            ,

        ) = /*uint startedAt*/
            /*uint timeStamp*/
            /*uint80 answeredInRound*/
            pricefeed.latestRoundData();

        return price; //  example price returned 3034715771688
    }

    function updateAllTokenUris(string memory trend) internal {
        if (compareStrings("bear", trend)) {
            // console.log(" UPDATING TOKEN URIS WITH ", "bear", trend);
            for (uint256 i = 1; i < _tokenIdCounter.current(); i++) {
                _setTokenURI(i, bearUrisIpfs[0]);
            }
        } else {
            // console.log(" UPDATING TOKEN URIS WITH ", "bull", trend);

            for (uint256 i = 1; i < _tokenIdCounter.current(); i++) {
                _setTokenURI(i, bullUrisIpfs[0]);
            }
        }
        emit TokensUpdated(trend);
    }

    function setPriceFeed(address newFeed) public onlyOwner {
        pricefeed = AggregatorV3Interface(newFeed);
    }

    function setInterval(uint256 newInterval) public onlyOwner {
        interval = newInterval;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer( address from, address to, uint256 tokenId ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
