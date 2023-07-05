// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol"; //somehow remapping doesn't work =(
import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Base64} from "../lib/openzeppelin-contracts/contracts/utils/Base64.sol";

contract MoodNft is ERC721 {
    //error
    error MoodNft__CantFlipMoodIfNotOwner();

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

    function flipMood(uint256 tokenId) public {
        // we only want the NFT owner to be able to change the mood
        if(!_isApprovedOrOwner(msg.sender,tokenId)){
            revert MoodNft__CantFlipMoodIfNotOwner();
        }
        if (s_tokenIdToMood[tokenId] == Mood.HAPPY){
            s_tokenIdToMood[tokenId] = Mood.SAD;
        } else {
            s_tokenIdToMood[tokenId] = Mood.HAPPY;
        }
    }

    function _baseURI() internal pure override returns(string memory){
        return "data:application/json;base64,";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory imageURI;
        if(s_tokenIdToMood[tokenId] == Mood.HAPPY) {
            imageURI = s_happySvgImageUri;
        } else {
            imageURI = s_sadSvgImageUri;
        }

        // // string memory tokenMetadata = string.concat('{"name: "',name(),'"}'); // example output => {"name": "Mood NFT"}
        // string memory tokenMetadata = string.concat('{"name: "',name(),'", "description": "NFT that reflects owners mood.", "attributes":[{"trait_type":"moodiness", "value":100}],"image": "', imageURI,'"}');
        
        return
            string(  //convert it back into string
                abi.encodePacked(   // to concantenate both parts below together 
                    _baseURI(), // This part is the "data:application/json;base64,""
                    Base64.encode(
                        // rather than using the above in "String", it's better for us to do it in bytes
                        // It is only after we convert it into bytes, then we can make it into Base64, using Base64.encode()
                        bytes( //turn it into bytes
                            abi.encodePacked(
                                '{"name: "',
                                name(),
                                '", "description": "NFT that reflects owners mood.", "attributes":[{"trait_type":"moodiness", "value":100}],"image": "', 
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
        
    }


}