# ExecutiveExpense Multi-Signature Contract

A smart contract built on the Stacks blockchain using Clarity for managing high-value corporate expenses that require multiple C-suite executive approvals.

## Overview

The ExecutiveExpense contract implements a multi-signature wallet specifically designed for corporate governance. It ensures that significant financial transactions require consensus from multiple authorized executives before execution, providing transparency and security for corporate expense management.

## Features

- **Multi-signature Security**: Configurable threshold requiring multiple executive approvals
- **Role-based Access**: Only authorized signers can create and approve transactions
- **Transaction Transparency**: All transactions are recorded on-chain with full audit trail
- **Flexible Configuration**: Adjustable signature thresholds and signer management
- **Prevention of Double-spending**: Robust checks against duplicate signatures and re-execution
- **STX Integration**: Native Stacks token handling for corporate payments

## Contract Architecture

### Constants
- `CONTRACT_OWNER`: The deploying address with administrative privileges
- Error codes for various failure scenarios (unauthorized access, invalid parameters, etc.)

### Data Storage
- **authorized-signers**: Map of principals authorized to sign transactions
- **transactions**: Map storing transaction details (recipient, amount, memo, execution status)
- **transaction-signatures**: Tracks which signers have approved each transaction
- **signature-threshold**: Required number of signatures for execution (default: 3)

## Core Functions

### Administrative Functions

#### `add-signer(new-signer: principal)`
Adds a new authorized signer to the contract.
- **Access**: Contract owner only
- **Returns**: `(ok true)` on success

#### `remove-signer(signer: principal)`
Removes an authorized signer from the contract.
- **Access**: Contract owner only
- **Restriction**: Cannot remove the contract owner
- **Returns**: `(ok true)` on success

#### `update-threshold(new-threshold: uint)`
Updates the required number of signatures for transaction execution.
- **Access**: Contract owner only
- **Validation**: Threshold must be greater than 0
- **Returns**: `(ok true)` on success

### Transaction Management

#### `create-transaction(recipient: principal, amount: uint, memo: string-ascii)`
Creates a new expense transaction requiring approval.
- **Access**: Authorized signers only
- **Auto-signature**: Creator automatically signs the transaction
- **Returns**: Transaction ID (`uint`) on success

#### `sign-transaction(tx-id: uint)`
Adds approval signature to an existing transaction.
- **Access**: Authorized signers only
- **Validation**: Prevents double-signing and signing executed transactions
- **Returns**: `(ok true)` on success

#### `execute-transaction(tx-id: uint)`
Executes a transaction that has met the signature threshold.
- **Access**: Authorized signers only
- **Requirements**: Must have sufficient signatures and not be previously executed
- **Action**: Transfers STX from contract to specified recipient
- **Returns**: `(ok true)` on success

### Utility Functions

#### `deposit(amount: uint)`
Deposits STX tokens into the contract for future transactions.
- **Access**: Public
- **Returns**: `(ok true)` on success

#### `get-balance()`
Returns the current STX balance of the contract.
- **Access**: Read-only, public

## Read-Only Functions

- `get-signature-threshold()`: Returns current signature threshold
- `is-authorized-signer(signer)`: Checks if a principal is authorized
- `get-transaction(tx-id)`: Retrieves transaction details
- `has-signed(tx-id, signer)`: Checks if a signer has approved a transaction
- `get-current-nonce()`: Returns the next transaction ID

## Usage Workflow

### 1. Initial Setup
```clarity
;; Deploy contract (deployer becomes owner)
;; Add authorized C-suite executives
(contract-call? .executive-expense add-signer 'SP1ABC...CEO)
(contract-call? .executive-expense add-signer 'SP2DEF...CFO)
(contract-call? .executive-expense add-signer 'SP3GHI...CTO)
```

### 2. Fund the Contract
```clarity
;; Deposit STX for expenses
(contract-call? .executive-expense deposit u1000000) ;; 1 STX
```

### 3. Create Expense Request
```clarity
;; CEO creates expense request
(contract-call? .executive-expense create-transaction 
  'SP4JKL...VENDOR 
  u500000 
  "Office renovation payment")
```

### 4. Approval Process
```clarity
;; CFO approves
(contract-call? .executive-expense sign-transaction u0)

;; CTO approves
(contract-call? .executive-expense sign-transaction u0)
```

### 5. Execute Transaction
```clarity
;; Any authorized signer can execute once threshold is met
(contract-call? .executive-expense execute-transaction u0)
```

## Error Codes

| Code | Description |
|------|-------------|
| u100 | ERR_UNAUTHORIZED - Caller not authorized |
| u101 | ERR_INVALID_THRESHOLD - Invalid signature threshold |
| u102 | ERR_INVALID_SIGNER - Invalid signer address |
| u103 | ERR_ALREADY_SIGNED - Signer already approved transaction |
| u104 | ERR_INSUFFICIENT_SIGNATURES - Not enough approvals |
| u105 | ERR_TRANSACTION_NOT_FOUND - Transaction doesn't exist |
| u106 | ERR_TRANSACTION_EXECUTED - Transaction already executed |
| u107 | ERR_INVALID_AMOUNT - Invalid transaction amount |

## Security Considerations

1. **Owner Privileges**: The contract owner has significant control over signer management
2. **Signature Threshold**: Set appropriate thresholds based on organizational needs
3. **Signer Management**: Regularly review and update authorized signers
4. **Transaction Monitoring**: Monitor all transactions for unauthorized or suspicious activity
5. **Contract Upgrades**: Consider upgrade mechanisms for future improvements

## Deployment Requirements

- Stacks blockchain testnet/mainnet access
- Clarity CLI or compatible development environment
- Sufficient STX for contract deployment and initial funding