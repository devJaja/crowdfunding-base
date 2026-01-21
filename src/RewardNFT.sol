// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// This contract relies on OpenZeppelin's ERC721 and Ownable implementations.
// Due to environment constraints, these imports may not be available,
// but they are essential for a fully functional and secure contract.
// You would typically install them using: forge install OpenZeppelin/openzeppelin-contracts
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./IRewardNFT.sol";

/// @title RewardNFT
/// @notice A contract for minting reward NFTs to crowdfunding backers.
/// @dev Implements the IRewardNFT interface and uses OpenZeppelin's ERC721 standard.
contract RewardNFT is ERC721, Ownable, IRewardNFT {
    string private _baseURI;
    uint256 private _nextTokenId;

    /// @notice Initializes the NFT contract with a name and symbol.
    /// @param name The name of the NFT collection.
    /// @param symbol The symbol of the NFT collection.
    /// @param initialOwner The address that will initially own this contract.
    constructor(string memory name, string memory symbol, address initialOwner)
        ERC721(name, symbol)
        Ownable(initialOwner)
    {}

    /// @notice Mints a new reward NFT to a specific backer.
    /// @dev Only the contract owner (e.g., the Crowdfunding platform) can call this function.
    /// @param campaignId The ID of the crowdfunding campaign.
    /// @param to The address of the backer to mint the NFT to.
    /// @param tierAmount The contribution amount this reward tier represents.
    function mintReward(
        uint256 campaignId,
        address to,
        uint256, // tokenId - is unused as we will autoincrement
        uint256 tierAmount
    ) external override onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        emit RewardNFTMinted(campaignId, to, tokenId, tierAmount);
    }
    
    /// @notice Sets the base URI for all token URIs.
    /// @dev Only the contract owner can call this function.
    /// @param newBaseURI The new base URI for token metadata.
    function setBaseURI(string calldata newBaseURI) external override onlyOwner {
        _baseURI = newBaseURI;
    }
    
    /// @notice Overrides the internal _baseURI function from ERC721 to return our custom base URI.
    function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    /// @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    /// @dev This implementation relies on the _baseURI and the default ERC721 tokenURI logic.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, IRewardNFT)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // The following functions are part of the IRewardNFT interface and are
    // automatically implemented by inheriting from OpenZeppelin's ERC721 contract:
    // - balanceOf(address)
    // - ownerOf(uint256)
    // - approve(address, uint256)
    // - getApproved(uint256)
    // - setApprovalForAll(address, bool)
    // - isApprovedForAll(address, address)
    // - transferFrom(address, address, uint256)
    // - safeTransferFrom(address, address, uint256)
    // - safeTransferFrom(address, address, uint256, bytes calldata)
}
