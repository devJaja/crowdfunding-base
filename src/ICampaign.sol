// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ICampaign
/// @notice Interface for an individual crowdfunding campaign contract.
/// This interface defines the external functions expected for a single campaign.
interface ICampaign {
    /// @dev Enum for campaign status, mirrored from Crowdfunding.sol for consistency.
    enum CampaignStatus {
        Active,
        Successful,
        Failed,
        Claimed
    }

    /// @dev Emitted when a contribution is made to this campaign.
    event ContributionMade(
        address indexed contributor,
        uint256 amount,
        uint256 timestamp
    );

    /// @dev Emitted when this campaign is finalized.
    event CampaignFinalized(
        CampaignStatus status,
        uint256 totalRaised,
        uint256 timestamp
    );

    /// @dev Emitted when funds are withdrawn by the creator.
    event FundsWithdrawn(
        address indexed creator,
        uint256 amount,
        uint256 timestamp
    );

    /// @dev Emitted when a refund is claimed by a contributor.
    event RefundClaimed(
        address indexed contributor,
        uint256 amount,
        uint256 timestamp
    );

    /// @notice Returns the detailed information about this campaign.
    /// @return creator The address of the campaign creator.
    /// @return goal The funding goal in wei.
    /// @return deadline The campaign deadline as Unix timestamp.
    /// @return metadataHash IPFS/Arweave hash containing campaign metadata.
    /// @return totalRaised The total amount of ETH raised.
    /// @return status The current status of the campaign.
    /// @return withdrawn True if funds have been withdrawn by the creator.
    function getDetails()
        external
        view
        returns (
            address creator,
            uint256 goal,
            uint256 deadline,
            string memory metadataHash,
            uint256 totalRaised,
            CampaignStatus status,
            bool withdrawn
        );

    /// @notice Contribute ETH to this campaign.
    function contribute() external payable;

    /// @notice Finalizes this campaign after its deadline has passed.
    function finalize() external;

    /// @notice Allows the campaign creator to withdraw funds if the campaign is successful.
    function withdrawFunds() external;

    /// @notice Allows contributors to claim refunds if the campaign has failed.
    function claimRefund() external;

    /// @notice Get contribution amount for a specific contributor to this campaign.
    /// @param contributor The address of the contributor.
    /// @return amount The contribution amount in wei.
    function getContribution(address contributor) external view returns (uint256 amount);

    /// @notice Check if a contributor has claimed their refund for this campaign.
    /// @param contributor The address of the contributor.
    /// @return claimed Whether the refund has been claimed.
    function hasClaimedRefund(address contributor) external view returns (bool claimed);
}
