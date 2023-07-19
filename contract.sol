// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "contracts/DefaultOperatorFilterer.sol";

contract NFT is ERC721, Ownable, DefaultOperatorFilterer{
    using Strings for uint256;

    uint public constant MAX_TOKENS = 333;
    uint public price = 0.004 ether;
    uint256 public constant MAX_MINT_PER_TX = 5;

    bool public isSaleActive;
    uint256 public totalSupply;
    mapping(address => uint256) private mintedPerWallet;

    string public baseUri;
    string public baseExtension = ".json";

    constructor() ERC721("Bloodsuckers", "BS") {
        baseUri = "ipfs://xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/";
        // 1 Reserved Mint (for test)
        _safeMint(msg.sender, 1);
        totalSupply = 1;
    }

    // Public Functions
    function mint(uint256 _numTokens) external payable {
        require(isSaleActive, "The sale is paused.");
        require(_numTokens <= MAX_MINT_PER_TX, "You can only mint a maximum of 5 NFTS per transaction.");
        require(mintedPerWallet[msg.sender] + _numTokens <= MAX_MINT_PER_TX, "You can only mint 5 per wallet.");
        uint256 curTotalSupply = totalSupply;
        require(curTotalSupply + _numTokens <= MAX_TOKENS, "Exceeds total supply.");
        require(_numTokens * price <= msg.value, "Insufficient funds.");

        for(uint256 i = 1; i <= _numTokens; ++i) {
            _safeMint(msg.sender, curTotalSupply + i);
        }
        mintedPerWallet[msg.sender] += _numTokens;
        totalSupply += _numTokens;
    }

    // Owner-only functions
    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function withdrawAll() external payable onlyOwner {
        uint256 balance = address(this).balance;
        ( bool transferOne, ) = payable(0xEae965A5dF175d34Fc648Abb969bdb34EE879Bb4).call{value: balance}("");
        require(transferOne, "Transfer failed.");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
 
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

     function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
}
