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
    address public owner;

    mapping(uint256 => address) public owners;
    mapping(address => uint256) public balances;
    mapping(uint256 => address) public approvals;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function mintReward(
        uint256 campaignId,
        address to,
        uint256, // tokenId
        uint256 tierAmount
    ) external override onlyOwner {
        uint256 tokenId = nextTokenId++;
        owners[tokenId] = to;
        balances[to]++;
        emit RewardNFTMinted(campaignId, to, tokenId, tierAmount);
    }

    function setBaseURI(string calldata newBaseURI) external override onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        if(bytes(owners[tokenId]).length == 0) return ""; // Non-existent token
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
    }

    function balanceOf(address _owner) external view override returns (uint256 balance) {
        return balances[_owner];
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        return owners[tokenId];
    }

    function approve(address to, uint256 tokenId) external override {
        require(msg.sender == owners[tokenId], "Not owner");
        approvals[tokenId] = to;
    }

    function getApproved(uint256 tokenId) external view override returns (address operator) {
        return approvals[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) external override {
        require(from == owners[tokenId], "From address is not owner");
        require(msg.sender == from || msg.sender == approvals[tokenId], "Not authorized");
        
        owners[tokenId] = to;
        balances[from]--;
        balances[to]++;
        delete approvals[tokenId];
    }

    // --- Unimplemented Functions ---
    function setApprovalForAll(address, bool) external override {}
    function isApprovedForAll(address, address) external view override returns (bool) { return false; }
    function safeTransferFrom(address, address, uint256) external override {}
    function safeTransferFrom(address, address, uint256, bytes calldata) external override {}
    
    // --- Helper ---
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

contract RewardNFTTest is Test {
    MockRewardNFT public mockNft;

    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    uint256 public constant CAMPAIGN_ID = 1;

    function setUp() public {
        vm.prank(owner);
        mockNft = new MockRewardNFT();
    }

    // --- Minting Tests ---
    function test_MintReward_Success() public {
        vm.prank(owner);
        mockNft.mintReward(CAMPAIGN_ID, user1, 0, 1 ether);
        assertEq(mockNft.ownerOf(0), user1);
        assertEq(mockNft.balanceOf(user1), 1);
    }

    function test_MintReward_Fail_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can call this function");
        mockNft.mintReward(CAMPAIGN_ID, user1, 0, 1 ether);
    }

    // --- URI Tests ---
    function test_SetBaseURI_Success() public {
        vm.prank(owner);
        string memory newBaseURI = "https://myapi.com/nfts/";
        mockNft.setBaseURI(newBaseURI);
        assertEq(mockNft.baseURI(), newBaseURI);
    }

    function test_SetBaseURI_Fail_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can call this function");
        mockNft.setBaseURI("https://myapi.com/nfts/");
    }

    function test_TokenURI() public {
        vm.prank(owner);
        mockNft.mintReward(CAMPAIGN_ID, user1, 0, 1 ether);
        
        // Test without base URI
        assertEq(mockNft.tokenURI(0), "");

        // Test with base URI
        string memory base = "https://example.com/";
        mockNft.setBaseURI(base);
        assertEq(mockNft.tokenURI(0), "https://example.com/0");
    }

    // --- Transfer and Approval Tests ---
    function test_Approve() public {
        vm.prank(owner);
        mockNft.mintReward(CAMPAIGN_ID, user1, 0, 1 ether);

        vm.prank(user1);
        mockNft.approve(user2, 0);
        
        assertEq(mockNft.getApproved(0), user2);
    }

    function test_TransferFrom_Owner() public {
        vm.prank(owner);
        mockNft.mintReward(CAMPAIGN_ID, user1, 0, 1 ether);

        vm.prank(user1);
        mockNft.transferFrom(user1, user2, 0);

        assertEq(mockNft.ownerOf(0), user2);
        assertEq(mockNft.balanceOf(user1), 0);
        assertEq(mockNft.balanceOf(user2), 1);
    }

    function test_TransferFrom_Approved() public {
        vm.prank(owner);
        mockNft.mintReward(CAMPAIGN_ID, user1, 0, 1 ether);

        vm.prank(user1);
        mockNft.approve(user2, 0);

        vm.prank(user2);
        mockNft.transferFrom(user1, user2, 0);

        assertEq(mockNft.ownerOf(0), user2);
        assertEq(mockNft.getApproved(0), address(0)); // Approval should be cleared
    }

    function test_TransferFrom_Fail_NotAuthorized() public {
        vm.prank(owner);
        mockNft.mintReward(CAMPAIGN_ID, user1, 0, 1 ether);

        vm.prank(user2);
        vm.expectRevert("Not authorized");
        mockNft.transferFrom(user1, user2, 0);
    }
}