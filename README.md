# Doefin V1 Contracts

## Project Problem Statement

Doefin designed to address the challenge of establishing a trustless, decentralized financial derivative system based on
Bitcoin's blockchain difficulty. In traditional financial markets, options and derivatives often rely on centralized
entities or intermediaries for validation and settlement, which introduces trust issues, inefficiencies, and potential
points of failure. The problem becomes particularly acute in the context of cryptocurrency, where decentralization and
trustlessness are paramount. Users engaging in bets or options based on future Bitcoin difficulty levels require a
mechanism that ensures accuracy, security, and fairness in the outcome without the need for trusting a central
authority. This project seeks to create a system where two parties, Alice and Bob, can confidently enter into a long
call option on Bitcoin's difficulty, knowing that the outcome will be determined in a decentralized, transparent, and
trustless manner.

## Proposed Solution

Doefin leverages smart contracts and the inherent security of the Bitcoin blockchain. The key component of this solution
is a smart contract that maintains synchronization with the Bitcoin blockchain in a trustless way. This smart contract
accepts transactions containing Bitcoin block header information, which it then validates using Nakamoto consensus
rules. By doing so, the smart contract can independently verify the authenticity and correctness of the block data. When
Alice and Bob enter into a bet, the contract locks their collateral and sets the parameters of the bet, such as the
expiry date or block number and the strike difficulty target. Upon reaching the expiry, the smart contract checks the
validated block headers to determine the difficulty at that time and settles the bet accordingly. This approach ensures
that the settlement is based on genuine, tamper-proof data from the Bitcoin blockchain, thereby eliminating the need for
a trusted intermediary.

## Major Technical Components

The solution involves several technical components to ensure its robustness and reliability:

1. **Bitcoin Block Header Oracle**:

- **Initial Block Deployment**: The contract is initially deployed with a manually validated block. This is a critical
  step, as it establishes the starting point for all subsequent validations.
- **Block Validation**: The oracle receives Bitcoin block headers and validates them by checking the following
  parameters: - **Previous Block Hash**: Ensures continuity by verifying the hash of the previous block. -
  **Timestamp**: Validates that the block’s timestamp is greater than the median of the previous 11 blocks. - **nBits
  (Difficulty Value)**: Confirms that the difficulty value is accurate and consistent with Bitcoin’s consensus rules. -
  **Block Hash**: Computes the block hash and checks that it is numerically less than the target defined by the
  difficulty value.
- **Chain Length Validation**: Ensures that the new chain formed by including the block is longer than the previous
  chain, accommodating potential block reorganizations.
- **Oracle Notifications**: After successful validation, the oracle notifies dependent contracts (e.g., the
  OptionManager) about the latest confirmed block, including its timestamp, block number, and difficulty.

2. **OptionManager Contract**:

- **Bet Initialization**: Facilitates bet creation through separate maker/taker transactions, creating an order book to
  match participants.
- **Callback Registration**: Registers callbacks with the Oracle contract to trigger bet settlement upon reaching the
  expiry conditions.
- **Bet Settlement**: Determines the outcome based on the difficulty at expiry and transfers the locked funds to the
  winner. For simple binary options, this involves transferring the entire bet amount.

3. **Transaction Efficiency**:

- **Gas Limit Considerations**: Ensures that multiple block validations and bet settlements stay within the gas limits
  of the underlying blockchain. In cases where gas limits are tight, a claim mechanism may be implemented, allowing
  winners to manually claim their payouts.
- **EVM L2s or Sidechains**: Deploying on Layer 2 solutions or sidechains to reduce transaction costs, making it
  economically viable to validate blocks and settle bets frequently.

4. **Security Measures**:

- **Decentralized Validation**: Ensures that anyone can upload block headers, preventing dependency on a single entity.
- **Smart Contract Audits**: Engages respected auditors to review and validate the security of the smart contracts
  before deployment.

The diagram below shows the interaction between the major components of the solution

![Doefin Contracts drawio](https://github.com/Doefin/v1-core/assets/17001801/f3573c67-5fa4-423f-a5b2-6be32a16195c)

The diagram illustrates the interaction between various components in the options trading system. A Maker initiates the
process by creating an order through the Order Book, which has been deployed by the Order Book Factory. A Taker then
takes the order from the Order Book. The Order Book registers a callback with the Options Manager to handle order
settlements. The Options Manager, in turn, relies on the Block Header Oracle to validate block headers, which it
receives from the Bitcoin Block Header Indexer. The Bitcoin Block Header Indexer submits block headers to the Block
Header Oracle, which then submits validated block headers back to the Options Manager to ensure the accuracy and
integrity of the order settlements.

## Challenges and Solutions

Several challenges and potential bottlenecks have been identified in the design, along with approaches to mitigate them:

1. **Oracle Security**:

- **Hash Power Assumptions**: The oracle’s security relies on the assumption that miners with significant hash power are
  more incentivized to mine valid Bitcoin blocks rather than attempting to upload false data to the oracle. This is
  bolstered by requiring multiple block confirmations before settling bets, making it difficult for an attacker to
  successfully execute an attack.
- **Auditing**: Engaging third-party auditors to validate the security of the smart contracts and the integrity of the
  oracle system.

2. **Economic Viability**:

- **Transaction Costs**: Running the oracle and validating each Bitcoin block could be expensive on high-fee networks.
  To address this, the project plans to deploy on EVM-compatible Layer 2 solutions or sidechains where transaction costs
  are significantly lower, making the process cost-effective.

3. **User Experience**:

- **Settlement Data Provision**: Predexyo may run its own Bitcoin node to pre-write redemption transactions,
  streamlining the user experience for the winner. However, users always have the option to provide their own block
  header data to claim their winnings, ensuring that Predexyo cannot interfere with the outcome.

4. **Protocol Adaptability**:

- **Blockchain Changes**: The system must adapt to changes in the Bitcoin protocol, such as hard forks. This is managed
  by confirming blocks only after a sufficient number of subsequent blocks have been mined, ensuring that the confirmed
  blocks are on the longest chain.
- **Gas Limits and Performance**: Continuous testing and optimization are necessary to ensure that the system can handle
  the required operations within the available gas limits, and adjustments such as implementing a manual claim mechanism
  may be necessary to optimize performance.

By addressing these challenges through thoughtful design and implementation, Predexyo aims to create a robust, secure,
and user-friendly platform for decentralized financial derivatives based on Bitcoin difficulty.
