# VCD-01 Live Deployment Guide

## PeaceContributionEngine Deployment to Sepolia Testnet

This guide provides step-by-step instructions for deploying the VCD-01 PeaceContributionEngine smart contract to Ethereum Sepolia testnet.

---

## Prerequisites

### 1. Software Requirements

- **Node.js**: v18.x or higher
- **npm**: v9.x or higher
- **Hardhat**: Installed via project dependencies
- **MetaMask** or hardware wallet (Ledger/Trezor recommended for production)

### 2. Sepolia Testnet ETH

You need approximately **0.01-0.05 Sepolia ETH** for deployment gas costs.

**Get Sepolia ETH from faucets:**
- Alchemy Sepolia Faucet: https://sepoliafaucet.com/
- Infura Sepolia Faucet: https://www.infura.io/faucet/sepolia
- QuickNode Faucet: https://faucet.quicknode.com/ethereum/sepolia

### 3. RPC Endpoint

Use a reliable Sepolia RPC endpoint:
- **Alchemy**: https://eth-sepolia.g.alchemy.com/v2/YOUR-API-KEY
- **Infura**: https://sepolia.infura.io/v3/YOUR-PROJECT-ID
- **Public**: https://rpc.sepolia.org (may be rate-limited)

### 4. Wallet Setup

**IMPORTANT SECURITY NOTES:**
- ⚠️ NEVER use mainnet private keys on testnet
- ⚠️ Use a dedicated testnet wallet
- ⚠️ For production mainnet deployment, use hardware wallet or multi-sig

---

## Step 1: Environment Configuration

### 1.1 Create `.env` file

```bash
cd /home/runner/work/Peacebonds/Peacebonds
cp .env.example .env
```

### 1.2 Configure `.env`

Edit `.env` with your settings:

```env
# Sepolia Testnet Configuration
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR-API-KEY
PRIVATE_KEY=your_private_key_here_without_0x_prefix

# IPFS Configuration (for later use)
IPFS_API_URL=http://127.0.0.1:5001

# Contract Addresses (will be filled after deployment)
PEACEBOND_CONTRACT_ADDRESS=
PEACE_CONTRIBUTION_ENGINE_ADDRESS=
```

**How to get your private key:**
- MetaMask: Account Details → Export Private Key
- Remove the `0x` prefix when adding to `.env`
- ⚠️ Keep this file secure and never commit it to git

---

## Step 2: Compile Contracts

### 2.1 Install dependencies

```bash
npm install
```

### 2.2 Compile smart contracts

```bash
npm run compile
```

**Expected output:**
```
Compiled 10 Solidity files successfully
```

**Verify compilation:**
```bash
ls -la artifacts/contracts/PeaceContributionEngine.sol/
```

You should see `PeaceContributionEngine.json` artifact.

---

## Step 3: Pre-Deployment Checks

### 3.1 Check wallet balance

```bash
# Using cast (foundry) - optional
cast balance YOUR_WALLET_ADDRESS --rpc-url $SEPOLIA_RPC_URL

# Or check manually on Sepolia Etherscan
# https://sepolia.etherscan.io/address/YOUR_WALLET_ADDRESS
```

### 3.2 Estimate gas costs

Approximate costs on Sepolia (as of 2026):
- **Deployment**: ~0.003-0.005 ETH (3-5M gas units)
- **Role grants**: ~0.0001 ETH each
- **Total needed**: 0.01 ETH minimum (recommended: 0.05 ETH)

### 3.3 Verify contract code

Review the contract one final time:
```bash
cat contracts/PeaceContributionEngine.sol | head -50
```

---

## Step 4: Deploy Contract

### 4.1 Run deployment script

```bash
npx hardhat run scripts/deploy-peace-contribution-engine.ts --network sepolia
```

**Alternative using ts-node:**
```bash
npx ts-node scripts/deploy-peace-contribution-engine.ts
```

### 4.2 Deployment process

The script will:
1. ✓ Load contract artifact
2. ✓ Connect to Sepolia RPC
3. ✓ Check wallet balance
4. ✓ Deploy contract (30-60 seconds)
5. ✓ Wait for confirmation
6. ✓ Display contract address

**Expected output:**
```
========================================
VCD-01 PeaceContributionEngine Deployment
========================================

Deploying from address: 0xYourAddress...
Wallet balance: 0.05 ETH

Deploying PeaceContributionEngine contract...
This may take 30-60 seconds...

Transaction sent. Waiting for confirmation...

========================================
✓ Deployment Successful!
========================================

Contract Address: 0x1234567890abcdef1234567890abcdef12345678
Network: Sepolia Testnet
Deployer: 0xYourAddress...
Transaction: 0xabcd...
```

### 4.3 Save contract address

**Immediately save the contract address:**

1. Copy the contract address from output
2. Update `.env` file:
   ```env
   PEACE_CONTRIBUTION_ENGINE_ADDRESS=0x1234567890abcdef1234567890abcdef12345678
   ```
3. **Backup this address** - save to multiple locations

---

## Step 5: Verify Contract on Etherscan

### 5.1 Verify source code

```bash
npx hardhat verify --network sepolia 0xYOUR_CONTRACT_ADDRESS
```

**If using constructor arguments (not needed for this contract):**
```bash
npx hardhat verify --network sepolia 0xYOUR_CONTRACT_ADDRESS \
  --constructor-args arguments.js
```

### 5.2 Manual verification (if automated fails)

1. Go to Sepolia Etherscan: https://sepolia.etherscan.io/address/0xYOUR_CONTRACT_ADDRESS
2. Click "Contract" → "Verify and Publish"
3. Select:
   - Compiler Type: Solidity (Single file)
   - Compiler Version: v0.8.24
   - License: MIT
4. Paste flattened contract code
5. Submit

### 5.3 Verify on blockchain explorer

Visit your contract on Sepolia Etherscan:
```
https://sepolia.etherscan.io/address/0xYOUR_CONTRACT_ADDRESS
```

You should see:
- ✓ Contract source code verified
- ✓ Read Contract functions available
- ✓ Write Contract functions available

---

## Step 6: Post-Deployment Configuration

### 6.1 Grant OPERATOR Role

OPERATOR role allows minting Proof of Impact NFTs and distributing funds.

**Get role hash:**
```javascript
OPERATOR_ROLE = 0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929
```

**Grant role using Etherscan:**
1. Go to contract → Write Contract
2. Connect wallet (must be deployer/admin)
3. Find `grantRole` function
4. Parameters:
   - role: `0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929`
   - account: `0xVE_OPERATOR_ADDRESS`
5. Click "Write" and confirm transaction

**Grant to multiple VE Operators** (3-5 recommended)

### 6.2 Grant VALIDATOR Role

VALIDATOR role for network validators.

**Get role hash:**
```javascript
VALIDATOR_ROLE = 0x42ba8aadac7c619e43f7c86f9e663f8f82329d4efb679d6b2b2cd52b64ff9e8d
```

Follow same process as OPERATOR role.

### 6.3 Set up Multi-Sig Wallets

**LOGOS Council (5/9 multi-sig):**
1. Go to https://app.safe.global/
2. Create new Safe on Sepolia
3. Add 9 signer addresses
4. Set threshold: 5 of 9
5. Deploy Safe

**VE Operators (3/5 multi-sig):**
1. Create another Safe
2. Add 5 VE operator addresses
3. Set threshold: 3 of 5
4. Deploy Safe

### 6.4 Transfer Admin Role to Multi-Sig (Optional but recommended)

```javascript
// Transfer DEFAULT_ADMIN_ROLE to LOGOS Council Safe
// ONLY do this after confirming Safe is working
grantRole(DEFAULT_ADMIN_ROLE, LOGOS_COUNCIL_SAFE_ADDRESS)

// Then renounce your personal admin role
renounceRole(DEFAULT_ADMIN_ROLE, YOUR_ADDRESS)
```

---

## Step 7: Test Deployment

### 7.1 Test contribution

**Send test contribution:**
```bash
# Using cast (foundry)
cast send 0xYOUR_CONTRACT_ADDRESS \
  "contribute()" \
  --value 0.01ether \
  --private-key $PRIVATE_KEY \
  --rpc-url $SEPOLIA_RPC_URL
```

**Or via Etherscan:**
1. Go to Write Contract
2. Connect wallet
3. Find `contribute` function
4. Enter value: 0.01 (ETH)
5. Click "Write"

### 7.2 Verify contribution

**Check contribution was recorded:**
```bash
# Get contribution ID (should be 0 for first contribution)
cast call 0xYOUR_CONTRACT_ADDRESS \
  "contributions(uint256)(address,uint256,uint256,uint256,string,bool)" \
  0 \
  --rpc-url $SEPOLIA_RPC_URL
```

**Or via Etherscan Read Contract:**
1. Find `contributions` function
2. Input: 0
3. Should return your address, amount, timestamp, etc.

### 7.3 Check allocations

**Verify category allocations:**
```bash
# Check IDRO allocation
cast call 0xYOUR_CONTRACT_ADDRESS \
  "allocationCategories(string)(string,uint256,uint256,uint256,bool)" \
  "IDRO" \
  --rpc-url $SEPOLIA_RPC_URL
```

**Expected:**
- percentage: 400 (40%)
- totalAllocated: should show 40% of your contribution tax

### 7.4 Test Impact NFT minting

**Mint a test Proof of Impact NFT** (requires OPERATOR role):
```javascript
// Via Etherscan Write Contract (connected as OPERATOR)
mintProofOfImpact(
  contributionId: 0,
  impactScore: 1000,
  beneficiariesReached: 100,
  resourcesDeployed: 50,
  category: "IDRO",
  ipfsCID: "QmTest123..."
)
```

---

## Step 8: Update Documentation

### 8.1 Update README.md

Add deployed contract address to README:
```markdown
## VCD-01 Deployed Contracts

**Sepolia Testnet:**
- PeaceContributionEngine: `0xYOUR_CONTRACT_ADDRESS`
- Deployment Date: 2026-02-04
- Deployer: `0xYOUR_ADDRESS`
- Etherscan: https://sepolia.etherscan.io/address/0xYOUR_CONTRACT_ADDRESS
```

### 8.2 Update VCD-01_Manifesto.md

Update contract addresses section (lines 347-351):
```markdown
### Smart Contract Addresses

**VCD-01 Core Contract:** `0xYOUR_CONTRACT_ADDRESS`
**Network:** Sepolia Testnet
**Peace Contribution Engine:** `0xYOUR_CONTRACT_ADDRESS`
```

### 8.3 Create deployment record

Create `deployments/sepolia.json`:
```json
{
  "network": "sepolia",
  "chainId": 11155111,
  "contracts": {
    "PeaceContributionEngine": {
      "address": "0xYOUR_CONTRACT_ADDRESS",
      "deployedAt": "2026-02-04T00:00:00Z",
      "deployer": "0xYOUR_ADDRESS",
      "txHash": "0xTX_HASH",
      "blockNumber": 12345678
    }
  },
  "multisig": {
    "logosCouncil": {
      "address": "0xLOGOS_SAFE_ADDRESS",
      "threshold": "5/9"
    },
    "veOperators": {
      "address": "0xVE_SAFE_ADDRESS",
      "threshold": "3/5"
    }
  }
}
```

---

## Step 9: Start Node Monitoring

### 9.1 Configure monitoring

Update monitoring script configuration:
```bash
# Edit scripts/monitoring/node-monitor.js
# Update contract address
```

### 9.2 Start monitoring

```bash
node scripts/monitoring/node-monitor.js
```

**Expected output:**
```
[INFO] Initializing VCD-01 Node Monitor
[INFO] Resonance target: 0.043 Hz ±0.001
[INFO] Integrity threshold: 98.4%
[INFO] BFT threshold: 95.0%
```

### 9.3 Verify metrics

Monitor should track:
- ✓ Resonance frequency
- ✓ Node integrity
- ✓ Byzantine Fault Tolerance
- ✓ IPFS connectivity
- ✓ Ethereum sync status

---

## Step 10: Security Checklist

### Pre-Production Checklist

- [ ] Contract verified on Etherscan
- [ ] Admin role transferred to multi-sig
- [ ] OPERATOR roles assigned to trusted addresses
- [ ] VALIDATOR roles assigned
- [ ] Test contributions completed successfully
- [ ] Impact NFTs minted and verified
- [ ] Category allocations verified (IDRO 40%, HELIOS 35%, etc.)
- [ ] Multi-sig wallets tested
- [ ] Monitoring active and reporting
- [ ] Backup of all private keys secured
- [ ] Documentation updated with addresses
- [ ] Emergency procedures documented
- [ ] 24-hour monitoring period completed

---

## Troubleshooting

### Deployment fails with "insufficient funds"

**Solution:**
```bash
# Check balance
cast balance YOUR_ADDRESS --rpc-url $SEPOLIA_RPC_URL

# Get more Sepolia ETH from faucet
# Recommended: 0.05 ETH minimum
```

### "Nonce too high" error

**Solution:**
```bash
# Reset nonce in MetaMask: Settings → Advanced → Reset Account
# Or specify nonce manually in deployment script
```

### Contract verification fails

**Solution:**
```bash
# Flatten contract first
npx hardhat flatten contracts/PeaceContributionEngine.sol > flattened.sol

# Remove duplicate SPDX licenses
# Then verify manually on Etherscan
```

### "Contract not found" after deployment

**Solution:**
- Wait 1-2 minutes for Etherscan indexing
- Check transaction on Etherscan: https://sepolia.etherscan.io/tx/0xYOUR_TX_HASH
- Verify contract creation succeeded

### Role grant transaction fails

**Solution:**
- Ensure you're connected with deployer wallet
- Check wallet has ETH for gas
- Verify role hash is correct

---

## Migration to Mainnet

### Prerequisites for Mainnet

1. **Security Audit:** Complete professional audit (Trail of Bits, Consensys, OpenZeppelin)
2. **Testnet Operation:** Minimum 30 days on Sepolia with no issues
3. **Multi-sig Setup:** Hardware wallet-based multi-sigs for all roles
4. **Insurance:** Consider smart contract insurance (Nexus Mutual, etc.)
5. **Legal Review:** Ensure compliance with applicable regulations

### Mainnet Deployment Differences

- Use Ethereum Mainnet RPC
- Real ETH required (~0.5-1 ETH for deployment)
- Higher gas prices (monitor: etherscan.io/gastracker)
- More conservative approach (test everything twice)
- Immediate transfer to multi-sig after deployment
- Consider using CREATE2 for deterministic addresses

---

## Support & Resources

### Documentation
- VCD-01 Manifesto: `/docs/VCD-01_Manifesto.md`
- Security Framework: `/docs/SECURITY.md`
- Governance: `/docs/GOVERNANCE.md`
- Node Setup: `/docs/NODE_SETUP.md`

### Community
- Discord: https://discord.gg/vcd01 (if available)
- GitHub Issues: https://github.com/hannesmitterer/Peacebonds/issues
- Email: governance@vcd01.network (if available)

### Emergency Contacts
- Security Issues: security@vcd01.network
- Technical Support: ops@vcd01.network

---

## Deployment Record Template

After successful deployment, fill out:

```
DEPLOYMENT RECORD - VCD-01 PEACECONTRIBUTIONENGINE

Date: 2026-02-04
Network: Sepolia Testnet
Chain ID: 11155111

CONTRACT DETAILS:
- Address: 0x_______________________________________
- Deployer: 0x_______________________________________
- TX Hash: 0x_______________________________________
- Block Number: ___________
- Gas Used: ___________
- Gas Price: ___________ gwei

VERIFICATION:
- Etherscan Verified: [ ] Yes [ ] No
- Source Code Public: [ ] Yes [ ] No

ROLES ASSIGNED:
- Admin: 0x_______________________________________ (Multi-sig)
- Operators: 
  - 0x_______________________________________
  - 0x_______________________________________
  - 0x_______________________________________
- Validators:
  - 0x_______________________________________
  - 0x_______________________________________

MULTI-SIG WALLETS:
- LOGOS Council (5/9): 0x_______________________________________
- VE Operators (3/5): 0x_______________________________________

TESTING COMPLETED:
- [ ] Test contribution successful
- [ ] Impact NFT minting successful
- [ ] Category allocations verified
- [ ] Multi-sig tested
- [ ] Monitoring active

NOTES:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

Deployed by: _______________________
Signature: _______________________
```

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-04  
**Maintained By:** VCD-01 Technical Team
