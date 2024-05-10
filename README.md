# Provably Random Raffle Contracts

## About

This repository contains the source code for a provably random smart contract lottery implemented on the Ethereum blockchain. It leverages blockchain technology to ensure transparency, fairness, and security in the lottery process.

## What we want it to do?

1. **User Participation**
   - Users can enter the lottery by purchasing a ticket.
   - The ticket fees collected are pooled and awarded to the winner of the draw.

2. **Automated Draw**
   - The lottery features an automatic draw mechanism that executes after a set period.
   - This drawing process is conducted programmatically without manual intervention.

3. **Integration with Chainlink**
   - **Chainlink VRF (Verifiable Random Function):** Ensures that the winner selection is based on secure and verifiable randomness.
   - **Chainlink Automation:** Triggers the draw based on a predefined time interval, making the lottery fully autonomous.

## Key Features

- **Decentralized and Transparent:** All transactions and the lottery mechanism are on-chain, allowing anyone to verify the integrity and fairness of the process.
- **Secure Randomness:** The use of Chainlink VRF provides cryptographic proof of the randomness used in the winner selection, which can be independently verified by anyone.
- **Automated Execution:** Chainlink Automation handles the timing of the draw, ensuring that it occurs at regular intervals without the need for external input or monitoring.

## Getting Started

To interact with or deploy this project using Foundry, follow these steps:

### Prerequisites

- Install [Foundry](https://book.getfoundry.sh/getting-started/installation.html) following the official documentation.
- Set up an Ethereum wallet like [MetaMask](https://metamask.io/).
- Obtain some testnet ETH and LINK tokens for deployment and testing.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-repository-url.git
   cd your-repository-directory

### Install dependencies:

```bash
forge update
```
### Deployment
To deploy the smart contracts to a testnet:

1. Set up the foundry.toml configuration file with your RPC URL and private key or use environment variables:

```toml
[default]
rpc_url = "https://eth-ropsten.alchemyapi.io/v2/your-api-key"
private_key = "your-wallet-private-key"
```
2. Deploy the contracts:

```bash
forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY YourContract
```

### Testing

Run the automated test suite to ensure the contracts function as expected:
```bash
forge test
```
## Contribution

Contributions are welcome! Please feel free to submit pull requests or open issues to suggest improvements or add new features.

## License

This project is released under the MIT License.