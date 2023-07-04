// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol"; //somehow remapping doesn't work =(
import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract BasicNft is ERC721 {
    uint256 private s_tokenCounter; //openzepplin have their own, but we can do one ourselves.
    mapping( uint256 => string ) private s_tokenIdToUri;

    constructor () ERC721 ("Dogie","DOG") {
        s_tokenCounter = 0; //everytime we mint, we update this counter.
    }
        
    function mintNft(string memory tokenUri) public {
        s_tokenIdToUri[s_tokenCounter] = tokenUri;
        _safeMint(msg.sender,s_tokenCounter);
        s_tokenCounter++;

    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return s_tokenIdToUri[tokenId];
        // return "ipfs://QmRWC6AVDxTbhE39beB8z1QUGqC69BzoFfnJTACYmEfBbp"
        // // NOT https://ipfs.io/QmRWC6AVDxTbhE39beB8z1QUGqC69BzoFfnJTACYmEfBbp cuz. if ipfs.io goes down, it is not accessible
        // // however most browsers do not have ipfs build it, so probably why people uses https://ipfs.io/QmRWC6AVDxTbhE39beB8z1QUGqC69BzoFfnJTACYmEfBbp
    }

    
    

}