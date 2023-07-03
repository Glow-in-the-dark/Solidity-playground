// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol"; //somehow remapping doesn't work =(
import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract MoodNft is ERC721 {
    uint private s_tokenCounter;
    string private s_sadSvgImageUri;
    string private s_happySvgImageUri;

    enum Mood {
        HAPPY,
        SAD
    }

    mapping(uint256 => Mood) private s_tokenIdToMood;

    constructor(
        string memory sadSvgImageUri, // note it's image URI, not tokenURI, which is the JSON metadata
        string memory happySvgImageUri
    ) ERC721("Mood Nft","MN"){
        s_tokenCounter = 0;
        s_sadSvgImageUri =  sadSvgImageUri;
        s_happySvgImageUri = happySvgImageUri;
    }

    function mintNft() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToMood[s_tokenCounter] = Mood.HAPPY; // set default to HAPPY
        s_tokenCounter++;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory imageURI;
        if(s_tokenIdToMood[tokenId] == Mood.HAPPY) {
            imageURI = s_happySvgImageUri;
        } else {
            imageURI = s_sadSvgImageUri;
        }

        // string memory tokenMetadata = string.concat('{"name: "',name(),'"}'); // example output => {"name": "Mood NFT"}
        string memory tokenMetadata = string.concat('{"name: "',name(),'", "description": "NFT that reflects owners mood.", "attributes":[{"trait_type":"moodiness", "value":100}],"image": "', imageURI,'"}');
    }


}