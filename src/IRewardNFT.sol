// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// While not strictly necessary for an interface, including common ERC721 events
// and functions helps clarify the expected behavior of implementing contracts.
// For a full ERC721 interface, we would typically import IERC721.sol and IERC721Metadata.sol.

/// @title IRewardNFT
/// @notice Interface for a Reward NFT contract that mints NFTs for crowdfunding backers.
interface IRewardNFT {
    /// @dev Emitted when an NFT is minted as a reward.
    event RewardNFTMinted(
        uint256 indexed campaignId,
        address indexed to,
        uint256 indexed tokenId,
        uint256 tierAmount // The contribution amount this tier represents
    );

    /// @notice Mints a new reward NFT to a specific backer for a given campaign and tier.
    /// @param campaignId The ID of the crowdfunding campaign.
    /// @param to The address of the backer to mint the NFT to.
    /// @param tokenId The unique identifier for the NFT.
    /// @param tierAmount The contribution amount this reward tier represents.
    function mintReward(
        uint256 campaignId,
        address to,
        uint256 tokenId,
        uint256 tierAmount
    ) external;

    /// @notice Sets the base URI for all token URIs.
    /// @dev This function is typically restricted to the contract owner or admin.
    /// @param newBaseURI The new base URI.
    function setBaseURI(string calldata newBaseURI) external;

    /// @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // Minimal ERC721 functions that are critical for an NFT interface
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
