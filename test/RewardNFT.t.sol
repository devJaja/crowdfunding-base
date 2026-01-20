// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/IRewardNFT.sol";

// A mock implementation of the IRewardNFT interface for testing purposes.
// Due to environment constraints preventing the import of OpenZeppelin's ERC721,
// this is a simplified mock and does not represent a fully compliant NFT contract.
contract MockRewardNFT is IRewardNFT {
    string public baseURI;
    uint256 public nextTokenId;
    mapping(uint256 => address) public owners;
    mapping(address => uint256) public balances;

    function mintReward(
        uint256 campaignId,
        address to,
        uint256 tokenId,
        uint256 tierAmount
    ) external {
        owners[tokenId] = to;
        balances[to]++;
        emit RewardNFTMinted(campaignId, to, tokenId, tierAmount);
    }

    function setBaseURI(string calldata newBaseURI) external {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
    }
    
    // --- Simplified ERC721 Functions ---

    function balanceOf(address owner) external view returns (uint256 balance) {
        return balances[owner];
    }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        return owners[tokenId];
    }

    // --- Unimplemented Functions (for interface compliance) ---

    function approve(address, uint256) external {}
    function getApproved(uint256) external view returns (address) { return address(0); }
    function setApprovalForAll(address, bool) external {}
    function isApprovedForAll(address, address) external view returns (bool) { return false; }
    function transferFrom(address, address, uint256) external {}
    function safeTransferFrom(address, address, uint256) external {}
    function safeTransferFrom(address, address, uint256, bytes calldata) external {}

    // --- Helper ---
    function _toString(uint256 value) internal pure returns (string memory) {
        // ... (implementation from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol)
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

contract RewardNFTTest is Test {
    MockRewardNFT public mockNft;

    address public user1 = makeAddr("user1");
    uint256 public constant CAMPAIGN_ID = 1;

    function setUp() public {
        mockNft = new MockRewardNFT();
    }

    function test_MintReward() public {
        uint256 tokenId = 1;
        uint256 tierAmount = 1 ether;

        vm.expectEmit(true, true, true, true);
        emit IRewardNFT.RewardNFTMinted(CAMPAIGN_ID, user1, tokenId, tierAmount);
        
        mockNft.mintReward(CAMPAIGN_ID, user1, tokenId, tierAmount);

        assertEq(mockNft.ownerOf(tokenId), user1, "Owner of token should be user1");
        assertEq(mockNft.balanceOf(user1), 1, "Balance of user1 should be 1");
    }

    function test_SetBaseURI() public {
        string memory newBaseURI = "https://myapi.com/nfts/";
        mockNft.setBaseURI(newBaseURI);
        assertEq(mockNft.baseURI(), newBaseURI, "Base URI should be set correctly");
    }

    function test_TokenURI() public {
        uint256 tokenId = 1;
        string memory base = "https://example.com/";
        mockNft.setBaseURI(base);
        
        string memory expectedURI = "https://example.com/1";
        assertEq(mockNft.tokenURI(tokenId), expectedURI, "Token URI should be correct");
    }
}
