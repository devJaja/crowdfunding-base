// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Crowdfunding.sol";

contract CrowdfundingTest is Test {
    Crowdfunding public crowdfunding;

    address public creator = makeAddr("creator");
    address public contributor1 = makeAddr("contributor1");
    address public contributor2 = makeAddr("contributor2");

    uint256 public constant FUNDING_GOAL = 10 ether;
    uint256 public constant CAMPAIGN_DURATION = 30 days;
    string public constant METADATA_HASH = "QmTestHash123";

    function setUp() public {
        crowdfunding = new Crowdfunding();
        vm.deal(contributor1, 100 ether);
        vm.deal(contributor2, 100 ether);
    }

    function test_CreateCampaign_Success() public {
        uint256 deadline = block.timestamp + CAMPAIGN_DURATION;

        vm.prank(creator);
        uint256 campaignId = crowdfunding.createCampaign(FUNDING_GOAL, deadline, METADATA_HASH);

        assertEq(campaignId, 1);
        assertEq(crowdfunding.campaignCounter(), 1);

        Crowdfunding.Campaign memory campaign = crowdfunding.getCampaign(campaignId);
        assertEq(campaign.creator, creator);
        assertEq(campaign.goal, FUNDING_GOAL);
        assertEq(campaign.deadline, deadline);
        assertEq(campaign.metadataHash, METADATA_HASH);
        assertEq(campaign.totalRaised, 0);
        assertEq(uint256(campaign.status), uint256(Crowdfunding.CampaignStatus.Active));
        assertFalse(campaign.withdrawn);
    }

    function test_CreateCampaign_RevertInvalidGoal() public {
        uint256 deadline = block.timestamp + CAMPAIGN_DURATION;

        vm.prank(creator);
        vm.expectRevert(Crowdfunding.InvalidGoal.selector);
        crowdfunding.createCampaign(0, deadline, METADATA_HASH);
    }

    function test_CreateCampaign_RevertInvalidDeadline() public {
        vm.prank(creator);
        vm.expectRevert(Crowdfunding.InvalidDeadline.selector);
        crowdfunding.createCampaign(FUNDING_GOAL, block.timestamp, METADATA_HASH);
    }

    function test_Contribute_Success() public {
        uint256 campaignId = _createTestCampaign();
        uint256 contributionAmount = 5 ether;

        vm.prank(contributor1);
        crowdfunding.contribute{value: contributionAmount}(campaignId);

        Crowdfunding.Campaign memory campaign = crowdfunding.getCampaign(campaignId);
        assertEq(campaign.totalRaised, contributionAmount);
        assertEq(crowdfunding.getContribution(campaignId, contributor1), contributionAmount);
    }

    function test_Contribute_MultipleContributions() public {
        uint256 campaignId = _createTestCampaign();

        vm.prank(contributor1);
        crowdfunding.contribute{value: 3 ether}(campaignId);

        vm.prank(contributor2);
        crowdfunding.contribute{value: 4 ether}(campaignId);

        vm.prank(contributor1);
        crowdfunding.contribute{value: 2 ether}(campaignId);

        Crowdfunding.Campaign memory campaign = crowdfunding.getCampaign(campaignId);
        assertEq(campaign.totalRaised, 9 ether);
        assertEq(crowdfunding.getContribution(campaignId, contributor1), 5 ether);
        assertEq(crowdfunding.getContribution(campaignId, contributor2), 4 ether);
    }

    function test_Contribute_RevertZeroContribution() public {
        uint256 campaignId = _createTestCampaign();

        vm.prank(contributor1);
        vm.expectRevert(Crowdfunding.ZeroContribution.selector);
        crowdfunding.contribute{value: 0}(campaignId);
    }

    function test_Contribute_RevertDeadlinePassed() public {
        uint256 campaignId = _createTestCampaign();

        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);

        vm.prank(contributor1);
        vm.expectRevert(Crowdfunding.DeadlinePassed.selector);
        crowdfunding.contribute{value: 1 ether}(campaignId);
    }

    function test_FinalizeCampaign_Successful() public {
        uint256 campaignId = _createTestCampaign();

        vm.prank(contributor1);
        crowdfunding.contribute{value: FUNDING_GOAL}(campaignId);

        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);
        crowdfunding.finalizeCampaign(campaignId);

        Crowdfunding.Campaign memory campaign = crowdfunding.getCampaign(campaignId);
        assertEq(uint256(campaign.status), uint256(Crowdfunding.CampaignStatus.Successful));
    }

    function test_FinalizeCampaign_Failed() public {
        uint256 campaignId = _createTestCampaign();

        vm.prank(contributor1);
        crowdfunding.contribute{value: FUNDING_GOAL - 1 ether}(campaignId);

        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);
        crowdfunding.finalizeCampaign(campaignId);

        Crowdfunding.Campaign memory campaign = crowdfunding.getCampaign(campaignId);
        assertEq(uint256(campaign.status), uint256(Crowdfunding.CampaignStatus.Failed));
    }

    function test_FinalizeCampaign_RevertDeadlineNotReached() public {
        uint256 campaignId = _createTestCampaign();

        vm.expectRevert(Crowdfunding.DeadlineNotReached.selector);
        crowdfunding.finalizeCampaign(campaignId);
    }

    function test_WithdrawFunds_Success() public {
        uint256 campaignId = _createTestCampaign();

        vm.prank(contributor1);
        crowdfunding.contribute{value: FUNDING_GOAL}(campaignId);

        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);
        crowdfunding.finalizeCampaign(campaignId);

        uint256 creatorBalanceBefore = creator.balance;

        vm.prank(creator);
        crowdfunding.withdrawFunds(campaignId);

        assertEq(creator.balance, creatorBalanceBefore + FUNDING_GOAL);

        Crowdfunding.Campaign memory campaign = crowdfunding.getCampaign(campaignId);
        assertTrue(campaign.withdrawn);
        assertEq(uint256(campaign.status), uint256(Crowdfunding.CampaignStatus.Claimed));
    }

    function test_WithdrawFunds_RevertNotCreator() public {
        uint256 campaignId = _createTestCampaign();

        vm.prank(contributor1);
        crowdfunding.contribute{value: FUNDING_GOAL}(campaignId);

        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);
        crowdfunding.finalizeCampaign(campaignId);

        vm.prank(contributor1);
        vm.expectRevert(Crowdfunding.NotCampaignCreator.selector);
        crowdfunding.withdrawFunds(campaignId);
    }

    function test_WithdrawFunds_RevertAlreadyWithdrawn() public {
        uint256 campaignId = _createTestCampaign();

        vm.prank(contributor1);
        crowdfunding.contribute{value: FUNDING_GOAL}(campaignId);

        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);
        crowdfunding.finalizeCampaign(campaignId);

        vm.prank(creator);
        crowdfunding.withdrawFunds(campaignId);

        vm.prank(creator);
        vm.expectRevert(Crowdfunding.AlreadyWithdrawn.selector);
        crowdfunding.withdrawFunds(campaignId);
    }

    function test_ClaimRefund_Success() public {
        uint256 campaignId = _createTestCampaign();
        uint256 contributionAmount = 5 ether;

        vm.prank(contributor1);
        crowdfunding.contribute{value: contributionAmount}(campaignId);

        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);
        crowdfunding.finalizeCampaign(campaignId);

        uint256 contributorBalanceBefore = contributor1.balance;

        vm.prank(contributor1);
        crowdfunding.claimRefund(campaignId);

        assertEq(contributor1.balance, contributorBalanceBefore + contributionAmount);
        assertTrue(crowdfunding.hasClaimedRefund(campaignId, contributor1));
    }

    function test_ClaimRefund_RevertNoContribution() public {
        uint256 campaignId = _createTestCampaign();

        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);
        crowdfunding.finalizeCampaign(campaignId);

        vm.prank(contributor1);
        vm.expectRevert(Crowdfunding.NoContribution.selector);
        crowdfunding.claimRefund(campaignId);
    }

    function test_ClaimRefund_RevertAlreadyRefunded() public {
        uint256 campaignId = _createTestCampaign();

        vm.prank(contributor1);
        crowdfunding.contribute{value: 5 ether}(campaignId);

        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);
        crowdfunding.finalizeCampaign(campaignId);

        vm.prank(contributor1);
        crowdfunding.claimRefund(campaignId);

        vm.prank(contributor1);
        vm.expectRevert(Crowdfunding.AlreadyRefunded.selector);
        crowdfunding.claimRefund(campaignId);
    }

    function test_OverfundingScenario() public {
        uint256 campaignId = _createTestCampaign();

        vm.prank(contributor1);
        crowdfunding.contribute{value: FUNDING_GOAL + 5 ether}(campaignId);

        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);
        crowdfunding.finalizeCampaign(campaignId);

        Crowdfunding.Campaign memory campaign = crowdfunding.getCampaign(campaignId);
        assertEq(uint256(campaign.status), uint256(Crowdfunding.CampaignStatus.Successful));
        assertEq(campaign.totalRaised, FUNDING_GOAL + 5 ether);

        uint256 creatorBalanceBefore = creator.balance;
        vm.prank(creator);
        crowdfunding.withdrawFunds(campaignId);

        assertEq(creator.balance, creatorBalanceBefore + FUNDING_GOAL + 5 ether);
    }

    function _createTestCampaign() internal returns (uint256 campaignId) {
        uint256 deadline = block.timestamp + CAMPAIGN_DURATION;

        vm.prank(creator);
        campaignId = crowdfunding.createCampaign(FUNDING_GOAL, deadline, METADATA_HASH);
    }
}