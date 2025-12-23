# Seedbringer Treasury Integration - Quick Start

This addendum describes the newly integrated Seedbringer Treasury system for the Peacebonds/Framework Euystacio project.

## What's New

The Seedbringer Treasury system adds comprehensive treasury monitoring and sustainability tracking:

1. **Real-time Balance Queries** - Monitor BTC/ETH balances
2. **Sustainability Runway** - Calculate project longevity metrics
3. **Apollo Assistant Commands** - User-friendly treasury inquiries
4. **Discord/Telegram Notifications** - Instant updates on treasury changes
5. **IPFS Integration** - Permanent, resilient data storage

## Quick Start

### 1. Check Treasury Balance

```javascript
const treasuryCommands = require('./src/commands/treasuryCommands');

const result = await treasuryCommands.processCommand('treasury:balance');
console.log(result.message);
```

### 2. Get Sustainability Metrics

```javascript
const result = await treasuryCommands.processCommand('treasury:runway');
console.log(result.message);
```

### 3. Enable Notifications (Optional)

Create `.env` file:
```env
DISCORD_WEBHOOK_URL=your_webhook_url
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_CHAT_ID=your_chat_id
```

## Available Commands

- `treasury:balance` - Current treasury balance
- `treasury:runway` - Sustainability runway in months/days
- `treasury:longevity` - Project longevity metrics
- `treasury:status` - Full status with IPFS snapshot

## Configuration Files

- `.github/FUNDING.yml` - GitHub funding configuration
- `src/config/notification_propagation.yml` - Discord/Telegram settings
- `src/services/treasuryService.js` - Core treasury logic
- `src/commands/treasuryCommands.js` - Command handlers

## Documentation

See `docs/TREASURY_SYSTEM.md` for complete documentation.

## Testing

```bash
npm install
npm test
```

## Treasury Address

**ETH**: `0x5d61a4B25034393A37ef9307C8Ba3aE99e49944b`

**IPFS Root**: `QmEustacioFrameworkGenesis2026Complete`

## Next Steps

1. Configure environment variables for notifications
2. Run tests to verify installation
3. Integrate with Apollo Assistant framework
4. Set up Discord/Telegram bots (optional)
5. Prepare for January 10 scheduled testing

For detailed information, see the main documentation in `docs/TREASURY_SYSTEM.md`.
