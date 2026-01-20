# Decentralized Crowdfunding Platform

A blockchain-based crowdfunding decentralized application (dApp) that enables transparent, trustless campaign creation and funding without intermediaries.

## Overview

This dApp revolutionizes crowdfunding by leveraging blockchain technology to provide transparency, lower fees, and global accessibility. Campaign creators can launch fundraising initiatives while backers maintain full visibility into fund allocation and usage. This project is built using the [Foundry](https://book.getfoundry.sh/) framework.

## Features

### Core Functionality
- **Campaign Creation**: Launch fundraising campaigns with a specific goal and deadline.
- **Contributions**: Users can contribute ETH to active campaigns.
- **Smart Contract Escrow**: Funds are held securely in the smart contract until the campaign deadline is reached.
- **Transparent Tracking**: Real-time, on-chain visibility of all contributions and campaign status.
- **Automated Refunds**: Contributors can claim a refund if the campaign fails to meet its goal.
- **Withdrawals**: Campaign creators can withdraw the funds if the campaign is successful.

## Smart Contract Details

The core logic is contained in the `Crowdfunding.sol` smart contract.

### State Variables
- `campaignCounter`: A counter to assign a unique ID to each new campaign.
- `campaigns`: A mapping from a campaign ID to its `Campaign` struct.
- `contributions`: A nested mapping to track the amount each user has contributed to a campaign.
- `refundClaimed`: A nested mapping to track if a user has claimed their refund for a failed campaign.

### Structs
- `Campaign`: Represents a single crowdfunding campaign with the following properties:
    - `creator`: The address of the campaign creator.
    - `goal`: The funding goal in wei.
    - `deadline`: The campaign deadline as a Unix timestamp.
    - `metadataHash`: An IPFS/Arweave hash containing campaign metadata.
    - `totalRaised`: The total amount of ETH raised.
    - `status`: The current status of the campaign (`Active`, `Successful`, `Failed`, `Claimed`).
    - `withdrawn`: A boolean to track if the funds have been withdrawn by the creator.

### Events
- `CampaignCreated`: Emitted when a new campaign is created.
- `ContributionMade`: Emitted when a user contributes to a campaign.
- `CampaignFinalized`: Emitted when a campaign is finalized as successful or failed.
- `FundsWithdrawn`: Emitted when a campaign creator withdraws the funds.
- `RefundClaimed`: Emitted when a contributor claims a refund from a failed campaign.

### Main Functions
- `createCampaign(uint256 goal, uint256 deadline, string calldata metadataHash)`: Creates a new campaign.
- `contribute(uint256 campaignId)`: Allows users to contribute ETH to a campaign.
- `finalizeCampaign(uint256 campaignId)`: Finalizes a campaign after the deadline has passed.
- `withdrawFunds(uint256 campaignId)`: Allows the creator to withdraw funds from a successful campaign.
- `claimRefund(uint256 campaignId)`: Allows contributors to claim a refund from a failed campaign.

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/crowdfunding-base.git
cd crowdfunding-base
```

2. Install dependencies:
```bash
forge install
```

### Build

Compile the smart contracts:
```bash
forge build
```

### Test

Run the test suite:
```bash
forge test
```

### Deploy

To deploy the contract, you can use the `Deploy.s.sol` script. First, set your environment variables in a `.env` file:

```
SEPOLIA_RPC_URL=<your_rpc_url>
PRIVATE_KEY=<your_private_key>
ETHERSCAN_API_KEY=<your_etherscan_api_key>
```

Then, run the deployment script:
```bash
forge script script/Deploy.s.sol:Deploy --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

## Usage

### For Campaign Creators

1. **Create a Campaign**: Call the `createCampaign` function with a funding goal (in wei), a deadline (Unix timestamp), and a metadata hash (e.g., an IPFS CID).
2. **Finalize the Campaign**: After the deadline, call `finalizeCampaign` to determine if the campaign was successful or failed.
3. **Withdraw Funds**: If the campaign was successful, call `withdrawFunds` to transfer the raised funds to your wallet.

### For Backers

1. **Contribute**: Call the `contribute` function with the `campaignId` and send ETH along with the transaction.
2. **Claim Refund**: If the campaign has failed (after finalization), call `claimRefund` to get your contributed ETH back.

## Testing

This project uses Foundry for testing. You can run the full test suite with:
```bash
forge test
```

For more verbose output, use the `-vvvv` flag:
```bash
forge test -vvvv
```

You can also run gas snapshots to analyze the gas consumption of your functions:
```bash
forge snapshot
```

## License

This project is licensed under the MIT License.