/*
SPDX-License-Identifier: GPL-3.0
    ___ _____   ____  ____  _______ 
   /   /__  /  / __ \/ __ \/  _/   |
  / /| | / /  / / / / /_/ // // /| |
 / ___ |/ /__/ /_/ / _, _// // ___ |
/_/  |_/____/\____/_/ |_/___/_/  |_|
            azoria.au

           METIS NINJAS
*/

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";


contract MetisNinjas is ERC2981, ERC721Enumerable, Ownable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;
    using Address for address;
    using Address for address payable;

    uint256 public MAX_TOTAL_MINT;
    string private _contractURI;
    string public baseTokenURI;
    uint256 private _currentTokenId = 0;

    address public treasury = 0x48eE6F05783D01Fe18904b1af2Bd29fb12Ce3139;
    address public artist = 0xe5d100bF6b44F54e0371EDCDE29018c8B54f4b46;

    constructor() 
    ERC721("Metis Ninjas", "NINJAS") {
        MAX_TOTAL_MINT = 5000;
        baseTokenURI = "ipfs://QmWqVg8MsEmBXChLaNMCqz5SKE86DWGj88Pg7DaLaSDKMq/";
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setDefaultRoyalty(artist, 100);
        _contractURI = "ipfs://QmTHujM7rXGrC6puZFEVx6LxLZZP78d7avpXYK2uyVuNFw";
        initialMint();
        }

    function initialMint () private {
        uint256 newTokenId = _getNextTokenId();
        _safeMint(msg.sender, newTokenId);
        _incrementTokenId();
    }

    function setBaseURI(string memory _setBaseURI) external onlyOwner {
        baseTokenURI = _setBaseURI;
    }

    function setContractURI(string memory uri) external onlyOwner {
        _contractURI = uri;
    }


    // PUBLIC
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControl, ERC2981, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")) : "";
    }

    function getInfo() external view returns (
        uint256,
        uint256,
        uint256
    ) {
        return (
        this.totalSupply(),
        msg.sender == address(0) ? 0 : this.balanceOf(msg.sender),
        MAX_TOTAL_MINT
        );
    }

    /**
     * Accepts required payment and mints a specified number of tokens to an address.
     */
    function purchase(uint256 count) public payable nonReentrant {

        uint256 price;

        if (count < 3) { // 3
            price = 2 ether; // 2
        }
        if (count >= 3 && count < 5) {
            price = 1.7 ether; // 1.7
        }
        if (count >= 5 && count < 10) {
            price = 1.5 ether; // 1.5
        }
        else {
            price = 1.2 ether;
        }

        // Make sure minting is allowed
        requireMintingConditions(count);

        // Sent value matches required ETH amount
        require(price * count <= msg.value, "ERC721_COLLECTION/INSUFFICIENT_ETH_AMOUNT");

        for (uint256 i = 0; i < count; i++) {
            uint256 newTokenId = _getNextTokenId();
            _safeMint(msg.sender, newTokenId);
            _incrementTokenId();
        }
    }

    // PRIVATE

    /**
     * This method checks if ONE of these conditions are met:
     *   - Public sale is active.
     *   - Pre-sale is active and receiver is allowlisted.
     *
     * Additionally ALL of these conditions must be met:
     *   - Gas fee must be equal or less than maximum allowed.
     *   - Newly requested number of tokens will not exceed maximum total supply.
     */
    function requireMintingConditions(uint256 count) internal view {

        // Total minted tokens must not exceed maximum supply
        require(totalSupply() + count <= MAX_TOTAL_MINT, "ERC721_COLLECTION/EXCEEDS_MAX_SUPPLY");
    }

    /**
     * Calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * Increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function withdraw() public onlyOwner  {
        uint256 balance = address(this).balance;
        uint256 treasuryAmt = balance.mul(75).div(100);
        uint256 artistAmt = balance.sub(treasuryAmt);
        require(treasuryAmt.add(artistAmt) == balance);
        payable(treasury).transfer(treasuryAmt);
        payable(artist).transfer(artistAmt);
    }
}
