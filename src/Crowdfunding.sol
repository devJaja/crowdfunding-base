// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Crowdfunding
 * @author Senior Blockchain Engineer
 * @notice A secure, non-custodial crowdfunding platform for ETH-based campaigns
 * @dev Implements trust-minimized fundraising with automatic refunds and withdrawals
 */
contract Crowdfunding {
    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/

    enum CampaignStatus {
      Active,
        Successful,
        Failed,
        Claimed
    }

    struct Campaign {
        address creator;
        uint256 goal;
        uint256 deadline;
        string metadataHash;
        uint256 totalRaised;
        CampaignStatus status;
        bool withdrawn;
    }

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    /// @notice Counter for campaign IDs
    uint256 public campaignCounter;

    /// @notice Mapping from campaign ID to campaign data
    mapping(uint256 => Campaign) public campaigns;

    /// @notice Mapping from campaign ID to contributor address to contribution amount
    mapping(uint256 => mapping(address => uint256)) public contributions;

    /// @notice Mapping to track if contributor has claimed refund for a campaign
    mapping(uint256 => mapping(address => bool)) public refundClaimed;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        uint256 goal,
        uint256 deadline,
        string metadataHash,
        uint256 timestamp
    );

    event ContributionMade(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount,
        uint256 timestamp
    );

    event CampaignFinalized(
        uint256 indexed campaignId,
        CampaignStatus status,
        uint256 totalRaised,
        uint256 timestamp
    );

    event FundsWithdrawn(
        uint256 indexed campaignId,
        address indexed creator,
        uint256 amount,
        uint256 timestamp
    );

    event RefundClaimed(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount,
        uint256 timestamp
    );

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidGoal();
    error InvalidDeadline();
    error CampaignNotFound();
    error CampaignNotActive();
    error CampaignNotFinalized();
    error CampaignNotFailed();
    error CampaignNotSuccessful();
    error DeadlineNotReached();
    error DeadlinePassed();
    error NoContribution();
    error AlreadyWithdrawn();
    error AlreadyRefunded();
    error NotCampaignCreator();
    error TransferFailed();
    error ZeroContribution();

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _status = _NOT_ENTERED;
    }

    /*//////////////////////////////////////////////////////////////
                            CAMPAIGN CREATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new crowdfunding campaign
     * @param goal The funding goal in wei (must be > 0)
     * @param deadline The campaign deadline as Unix timestamp (must be in future)
     * @param metadataHash IPFS/Arweave hash containing campaign metadata
     * @return campaignId The unique identifier for the created campaign
     */
    function createCampaign(
        uint256 goal,
        uint256 deadline,
        string calldata metadataHash
    ) external returns (uint256 campaignId) {
        if (goal == 0) revert InvalidGoal();
        if (deadline <= block.timestamp) revert InvalidDeadline();

        campaignId = ++campaignCounter;

        campaigns[campaignId] = Campaign({
            creator: msg.sender,
            goal: goal,
            deadline: deadline,
            metadataHash: metadataHash,
            totalRaised: 0,
            status: CampaignStatus.Active,
            withdrawn: false
        });

        emit CampaignCreated(
            campaignId,
            msg.sender,
            goal,
            deadline,
            metadataHash,
            block.timestamp
        );
    }

    /*//////////////////////////////////////////////////////////////
                             CONTRIBUTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Contribute ETH to an active campaign
     * @param campaignId The ID of the campaign to contribute to
     */
    function contribute(uint256 campaignId) external payable nonReentrant {
        if (msg.value == 0) revert ZeroContribution();

        Campaign storage campaign = campaigns[campaignId];
        if (campaign.creator == address(0)) revert CampaignNotFound();
        if (campaign.status != CampaignStatus.Active) revert CampaignNotActive();
        if (block.timestamp >= campaign.deadline) revert DeadlinePassed();

        // Update contribution tracking
        contributions[campaignId][msg.sender] += msg.value;
        campaign.totalRaised += msg.value;

        emit ContributionMade(campaignId, msg.sender, msg.value, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                           CAMPAIGN FINALIZATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Finalizes a campaign after its deadline has passed
     * @param campaignId The ID of the campaign to finalize
     * @dev Anyone can call this function - it's idempotent and safe
     */
    function finalizeCampaign(uint256 campaignId) external {
        Campaign storage campaign = campaigns[campaignId];
        if (campaign.creator == address(0)) revert CampaignNotFound();
        if (campaign.status != CampaignStatus.Active) revert CampaignNotActive();
        if (block.timestamp < campaign.deadline) revert DeadlineNotReached();

        // Determine campaign outcome based on funding goal
        if (campaign.totalRaised >= campaign.goal) {
            campaign.status = CampaignStatus.Successful;
        } else {
            campaign.status = CampaignStatus.Failed;
        }

        emit CampaignFinalized(
            campaignId,
            campaign.status,
            campaign.totalRaised,
            block.timestamp
        );
    }

    /*//////////////////////////////////////////////////////////////
                              WITHDRAWALS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows campaign creator to withdraw funds from successful campaign
     * @param campaignId The ID of the successful campaign
     */
    function withdrawFunds(uint256 campaignId) external nonReentrant {
        Campaign storage campaign = campaigns[campaignId];
        if (campaign.creator == address(0)) revert CampaignNotFound();
        if (msg.sender != campaign.creator) revert NotCampaignCreator();
        if (campaign.status != CampaignStatus.Successful) revert CampaignNotSuccessful();
        if (campaign.withdrawn) revert AlreadyWithdrawn();

        // Mark as withdrawn before transfer (checks-effects-interactions)
        campaign.withdrawn = true;
        campaign.status = CampaignStatus.Claimed;
        uint256 amount = campaign.totalRaised;

        // Transfer funds to creator
        (bool success, ) = payable(campaign.creator).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit FundsWithdrawn(campaignId, campaign.creator, amount, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                                REFUNDS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows contributors to claim refunds from failed campaigns
     * @param campaignId The ID of the failed campaign
     */
    function claimRefund(uint256 campaignId) external nonReentrant {
        Campaign storage campaign = campaigns[campaignId];
        if (campaign.creator == address(0)) revert CampaignNotFound();
        if (campaign.status != CampaignStatus.Failed) revert CampaignNotFailed();

        uint256 contributionAmount = contributions[campaignId][msg.sender];
        if (contributionAmount == 0) revert NoContribution();
        if (refundClaimed[campaignId][msg.sender]) revert AlreadyRefunded();

        // Mark refund as claimed before transfer (checks-effects-interactions)
        refundClaimed[campaignId][msg.sender] = true;

        // Transfer refund to contributor
        (bool success, ) = payable(msg.sender).call{value: contributionAmount}("");
        if (!success) revert TransferFailed();

        emit RefundClaimed(campaignId, msg.sender, contributionAmount, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get campaign details
     * @param campaignId The ID of the campaign
     * @return campaign The campaign struct
     */
    function getCampaign(uint256 campaignId) external view returns (Campaign memory campaign) {
        campaign = campaigns[campaignId];
        if (campaign.creator == address(0)) revert CampaignNotFound();
    }

    /**
     * @notice Get contribution amount for a specific contributor and campaign
     * @param campaignId The ID of the campaign
     * @param contributor The address of the contributor
     * @return amount The contribution amount in wei
     */
    function getContribution(uint256 campaignId, address contributor)
        external
        view
        returns (uint256 amount)
    {
        return contributions[campaignId][contributor];
    }

    /**
     * @notice Check if a contributor has claimed their refund
     * @param campaignId The ID of the campaign
     * @param contributor The address of the contributor
     * @return claimed Whether the refund has been claimed
     */
    function hasClaimedRefund(uint256 campaignId, address contributor)
        external
        view
        returns (bool claimed)
    {
        return refundClaimed[campaignId][contributor];
    }

    /**
     * @notice Get the current block timestamp (useful for testing)
     * @return timestamp The current block timestamp
     */
    function getCurrentTimestamp() external view returns (uint256 timestamp) {
        return block.timestamp;
    }
}