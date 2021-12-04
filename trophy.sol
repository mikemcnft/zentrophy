// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @author Mike_McNFT - https://twitter.com/3stacksnft, with attribution to the Zenacademy Smart Contract
/// @purpose this smart contract serves as a trophy for use in IRL and Virtal events that happen regularly

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Trophy is ERC1155Supply, Ownable, Pausable {
    using ECDSA for bytes32;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    uint256 public constant TOKEN_ID_TROPHY = 1;
    uint256 public constant TOKEN_PRICE_TROPHY = 0.000333 ether;
    uint256 public constant TOKEN_ID_PRIORTROPHY = 888;
    uint256 public constant TOKEN_PRICE_PRIORTROPHY = .000333 ether;
    uint256 public constant MAX_TOKENS_TROPHY = 1;
    uint256 public constant TOKEN_ID_ZBOUNTY = 33;
    uint256 public constant TOKEN_PRICE_ZBOUNTY = 333 ether;
    uint256 public constant TOKEN_ID_JBOUNTY = 66;
    uint256 public constant TOKEN_PRICE_JBOUNTY = 333 ether;

    bool public saleIsActiveTrophy = false;
    bool public saleIsActivePriorTrophy = false;
    bool public saleIsActiveZBounty = false;
    bool public saleIsActiveJBounty = false;

    // Used to validate authorized mint addresses
    address private signerAddress = 0xAa20816a724c8BCd2B8BeBb60b1A7a1F90e3ec0B;

    // Used to ensure each new token id can only be minted once by the owner
    mapping (uint256 => bool) public collectionMinted;
    mapping (uint256 => string) public tokenURI;
    mapping (address => bool) public hasAddressMintedTrophy;

    /**
     * Establishing 4 tokens, one used for the trophy to be passed from winner to winner, a prior trophy for prior winners, and two bounty tokens,
     */

    constructor(
        string memory uriBase,
        string memory uriTrophy,
        string memory uriPriorTrophy,
        string memory uriZBounty,
        string memory uriJBounty,
        string memory _name,
        string memory _symbol
    ) ERC1155(uriBase) {
        name = _name;
        symbol = _symbol;
        tokenURI[TOKEN_ID_TROPHY] = uriTrophy;
        tokenURI[TOKEN_ID_PRIORTROPHY] = uriPriorTrophy;
        tokenURI[TOKEN_ID_ZBOUNTY] = uriZBounty;
        tokenURI[TOKEN_ID_JBOUNTY] = uriJBounty;
    }

    /**
     * Returns the custom URI for each token id. Overrides the default ERC-1155 single URI.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        // If no URI exists for the specific id requested, fallback to the default ERC-1155 URI.
        if (bytes(tokenURI[tokenId]).length == 0) {
            return super.uri(tokenId);
        }
        return tokenURI[tokenId];
    }

    /**
     * Sets a URI for a specific token id.
     */
    function setURI(string memory newTokenURI, uint256 tokenId) public onlyOwner {
        tokenURI[tokenId] = newTokenURI;
    }

    /**
     * Set the global default ERC-1155 base URI to be used for any tokens without unique URIs
     */
    function setGlobalURI(string memory newTokenURI) public onlyOwner {
        _setURI(newTokenURI);
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        require(_signerAddress != address(0));
        signerAddress = _signerAddress;
    }

    /**
     * Lock Trophy token so that it can never be minted again
     */
    function lockTrophy() public onlyOwner {
        collectionMinted[TOKEN_ID_TROPHY] = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

 /**
     * @notice Override ERC1155 such that trophy cannot be transferred except by owner.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(id != 1, "cannot_transfer_Trophy");
        return super.safeTransferFrom(from, to, id, amount, data);
    }


    function verifyAddressSigner(bytes32 messageHash, bytes memory signature) private view returns (bool) {
        return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function hashMessage(address sender) private pure returns (bytes32) {
        return keccak256(abi.encode(sender));
    }

    /**
     * @notice Allow minting of any future tokens as desired as part of the same collection,
     * which can then be transferred to another contract for distribution purposes
     */
    function adminMint(address account, uint256 id, uint256 amount) public onlyOwner
    {
        require(!collectionMinted[id], "CANNOT_MINT_EXISTING_TOKEN_ID");
        require(id != TOKEN_ID_TROPHY && id != TOKEN_ID_PRIORTROPHY, "CANNOT_MINT_EXISTING_TOKEN_ID");
        collectionMinted[id] = true;
        _mint(account, id, amount, "");
    }

    /**
     * @notice Allow owner to send `mintNumber` Prior Trophy tokens without cost to multiple addresses
     */
    function giftPriorTrophy(address account, uint256 numberOfTokens) external onlyOwner {
        require(!collectionMinted[TOKEN_ID_PRIORTROPHY], "PRIORTROPHY_LOCKED");
        _mint(account, TOKEN_ID_PRIORTROPHY, numberOfTokens, "");
        
    }

    /**
     * @notice Allow owner to send `mintNumber` Trophy tokens without cost to multiple addresses
     */
    function giftTrophy(address account, uint256 numberOfTokens) external onlyOwner {
        require(!collectionMinted[TOKEN_ID_TROPHY], "TROPHY_LOCKED");
        _mint(account, TOKEN_ID_TROPHY, numberOfTokens, "");
        
    }

    /**
     * @notice Allow owner to send `mintNumber` Z Bounty tokens without cost to multiple addresses
     */
    function giftZBounty(address account, uint256 numberOfTokens) external onlyOwner {
        require(!collectionMinted[TOKEN_ID_ZBOUNTY], "ZBOUNTY_LOCKED");
        _mint(account, TOKEN_ID_ZBOUNTY, numberOfTokens, "");
        
    }

    /**
     * @notice Allow owner to send `mintNumber` J Bounty tokens without cost to multiple addresses
     */
    function giftJBounty(address account, uint256 numberOfTokens) external onlyOwner {
        require(!collectionMinted[TOKEN_ID_JBOUNTY], "JBOUNTY_LOCKED");
        _mint(account, TOKEN_ID_JBOUNTY, numberOfTokens, "");
        
    }


    /**
     * @notice When the contract is paused, all token transfers are prevented in case of emergency.
     */
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    /**
     * @notice This function transfers Trophy from prior owner to the new owner and mints a Prior Trophy token for the prior owner
     */
    function shipTrophy(address from, address to, uint256 id, uint256 amount, bytes memory data) external onlyOwner{
        _safeTransferFrom(from, to, id, amount, data);
        _mint (from, TOKEN_ID_PRIORTROPHY, 1, "");
    
    }
        
    
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "BALANCE_IS_ZERO");
        payable(msg.sender).transfer(address(this).balance);
    }
}