# VCD-01 Deployment - Ready to Execute

## ✅ Completed (Options 1 & 2)

### Option 1: Deployment Script
**File:** `/scripts/deploy-peace-contribution-engine.ts`

**Features:**
- Automated contract deployment
- Pre-flight checks (balance, artifacts)
- Progress indicators
- Post-deployment instructions
- Error handling and troubleshooting

**Usage:**
```bash
npx hardhat run scripts/deploy-peace-contribution-engine.ts --network sepolia
```

### Option 2: Comprehensive Documentation
**File:** `/docs/DEPLOY_VCD01.md`

**Includes:**
- 10-step deployment process
- Prerequisites and requirements
- Multi-sig wallet setup (Gnosis Safe)
- Testing procedures
- Troubleshooting guide
- Mainnet migration path
- Security checklist

---

## 🚀 How to Deploy (User Action Required)

### Prerequisites You Need:

1. **Sepolia ETH** (0.01-0.05 ETH)
   - Get from: https://sepoliafaucet.com/
   - Or: https://www.alchemy.com/faucets/ethereum-sepolia

2. **Configure `.env`** file:
   ```env
   SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR-API-KEY
   PRIVATE_KEY=your_private_key_without_0x
   ```

3. **Compile contracts**:
   ```bash
   npm install
   npm run compile
   ```

### Deploy Command:

```bash
npx hardhat run scripts/deploy-peace-contribution-engine.ts --network sepolia
```

**Or with ts-node:**
```bash
npx ts-node scripts/deploy-peace-contribution-engine.ts
```

---

## 📋 What Happens During Deployment

The script will:
1. ✓ Check your wallet has Sepolia ETH
2. ✓ Load the compiled contract
3. ✓ Deploy to Sepolia testnet (30-60 seconds)
4. ✓ Display the contract address
5. ✓ Show next steps (verification, role grants, multi-sig)

**Expected Output:**
```
========================================
✓ Deployment Successful!
========================================

Contract Address: 0x1234567890abcdef...
Network: Sepolia Testnet
Deployer: 0xYourAddress...
Transaction: 0xabcd...

Next Steps:
1. Save contract address to .env
2. Verify on Etherscan
3. Grant OPERATOR roles
4. Grant VALIDATOR roles
5. Set up multi-sig wallets
6. Test the contract
```

---

## ⚠️ Important Notes

### What I (Copilot) Cannot Do:
- ❌ Execute the actual deployment (requires your private key)
- ❌ Sign transactions with your wallet
- ❌ Access your Sepolia ETH
- ❌ Interact with MetaMask or hardware wallets

### What I Have Prepared:
- ✅ Complete deployment script
- ✅ Comprehensive documentation (14KB guide)
- ✅ Error handling and validation
- ✅ Post-deployment instructions
- ✅ Testing procedures
- ✅ Multi-sig setup guides

### What You Need to Do:
1. **Fund wallet** with Sepolia ETH
2. **Configure** `.env` with your credentials
3. **Run** the deployment script
4. **Follow** post-deployment steps in output
5. **Verify** contract on Etherscan
6. **Set up** multi-sig wallets
7. **Test** the deployment

---

## 📖 Documentation References

| Document | Purpose |
|----------|---------|
| `/docs/DEPLOY_VCD01.md` | Complete deployment guide (10 steps) |
| `/scripts/deploy-peace-contribution-engine.ts` | Automated deployment script |
| `/docs/VCD-01_Manifesto.md` | Framework overview |
| `/docs/SECURITY.md` | Security protocols |
| `/docs/GOVERNANCE.md` | Multi-sig and governance |
| `/docs/NODE_SETUP.md` | Node operator guide |

---

## 🔐 Security Reminders

- ⚠️ **NEVER** use mainnet private keys on testnet
- ⚠️ Use a **dedicated testnet wallet**
- ⚠️ Keep `.env` file **secure** (never commit to git)
- ⚠️ For mainnet: use **hardware wallet** or **multi-sig**
- ⚠️ Get **professional audit** before mainnet deployment

---

## 🎯 Quick Start

If you're ready to deploy right now:

```bash
# 1. Get Sepolia ETH (if you don't have it)
# Visit: https://sepoliafaucet.com/

# 2. Configure environment
cp .env.example .env
nano .env  # Add your SEPOLIA_RPC_URL and PRIVATE_KEY

# 3. Compile contracts
npm install
npm run compile

# 4. Deploy!
npx hardhat run scripts/deploy-peace-contribution-engine.ts --network sepolia

# 5. Follow the on-screen instructions
```

---

## 📞 Support

If you encounter issues:
1. Check `/docs/DEPLOY_VCD01.md` troubleshooting section
2. Review script output for error messages
3. Verify wallet has sufficient Sepolia ETH
4. Ensure `.env` is configured correctly
5. Check contract compilation succeeded

---

## ✨ Success Criteria

Your deployment is successful when:
- ✓ Script completes without errors
- ✓ Contract address is displayed
- ✓ Transaction confirmed on Sepolia
- ✓ Contract visible on Sepolia Etherscan
- ✓ Source code verified
- ✓ Roles granted to operators
- ✓ Test contribution successful

---

**You have everything needed to deploy. The rest is in your hands!**

Good luck with the deployment! 🚀

---

**Created:** 2026-02-04  
**Commit:** 2e77c08  
**Files Added:** 2 (script + documentation)
