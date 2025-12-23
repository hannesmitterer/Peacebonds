# Seedbringer Treasury System Documentation

## Overview

The Seedbringer Treasury System provides real-time treasury monitoring, sustainability runway calculation, and automated notification propagation for the Framework Euystacio project. This system integrates across the Apollo Assistant framework to deliver transparent, resilient treasury management.

## Features

### 1. Real-Time Treasury Queries
- **BTC/ETH Balance Monitoring**: Query current cryptocurrency balances in real-time
- **Multi-chain Support**: Compatible with Ethereum and EVM-compatible chains
- **Price Integration**: Automatic USD conversion using current market prices

### 2. Sustainability Runway Calculation
- **Runway Metrics**: Calculate operational runway in months and days
- **Health Status**: Automatic classification (HEALTHY, STABLE, WARNING, CRITICAL)
- **Burn Rate Analysis**: Configurable monthly operational cost tracking
- **Project Longevity**: Comprehensive metrics for long-term planning

### 3. Apollo Assistant Commands
User-facing commands for treasury inquiries:

```bash
# Get current treasury balance
treasury:balance

# Get sustainability runway metrics
treasury:runway

# Get project longevity metrics
treasury:longevity

# Get full treasury status with IPFS snapshot
treasury:status
```

### 4. Notification Propagation
- **Discord Integration**: Real-time updates to Discord channels
- **Telegram Support**: Critical alerts via Telegram bot
- **Event-Based**: Smart routing based on event type and priority
- **Rate Limiting**: Configurable limits to prevent spam

### 5. IPFS Data Integration
- **Permanent Storage**: Treasury snapshots stored on IPFS
- **Data Resilience**: Redundant copies across multiple gateways
- **Historical Access**: Retrieve past treasury states
- **Verification**: Cryptographic proof of data integrity

## Installation

### Prerequisites
- Node.js 16+ or React environment
- Access to Ethereum RPC endpoint (optional, for live data)
- Discord webhook URL (optional, for notifications)
- Telegram bot token (optional, for notifications)

### Setup

1. **Install Dependencies**
```bash
npm install
```

2. **Configure Environment Variables**
Create a `.env` file:
```env
# Discord Configuration
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/YOUR_WEBHOOK_URL

# Telegram Configuration
TELEGRAM_BOT_TOKEN=YOUR_BOT_TOKEN
TELEGRAM_CHAT_ID=YOUR_CHAT_ID

# Optional: Custom RPC endpoints
ETH_RPC_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
```

3. **Verify Configuration**
```bash
npm test
```

## Usage

### Command-Line Interface

```javascript
const treasuryCommands = require('./src/commands/treasuryCommands');

// Get treasury balance
const balance = await treasuryCommands.processCommand('treasury:balance');
console.log(balance.message);

// Get sustainability runway
const runway = await treasuryCommands.processCommand('treasury:runway');
console.log(runway.message);
```

### Direct API Usage

```javascript
const treasuryService = require('./src/services/treasuryService');

// Get current metrics
const metrics = await treasuryService.getTreasuryMetrics();
console.log('Balance:', metrics.balances.eth, 'ETH');
console.log('Runway:', metrics.runway.runwayMonths, 'months');
console.log('Status:', metrics.runway.healthStatus);

// Calculate custom runway
const runway = treasuryService.calculateSustainabilityRunway(
  { eth: 10, btc: 0.1 },
  5000, // Monthly burn rate in USD
  { ethPrice: 2000, btcPrice: 40000 }
);
```

### Notification Service

```javascript
const notificationService = require('./src/services/notificationService');

// Send manual notification
await notificationService.propagateEvent('balance_change', {
  balance_eth: '10.5',
  balance_usd: '21000',
  runway_months: 4,
  health_status: 'STABLE'
});

// Notify on treasury update
const metrics = await treasuryService.getTreasuryMetrics();
await notificationService.notifyTreasuryUpdate(metrics);
```

## Configuration

### Treasury Configuration

Edit `src/services/treasuryService.js`:

```javascript
const TREASURY_CONFIG = {
  ethAddress: '0x5d61a4B25034393A37ef9307C8Ba3aE99e49944b',
  btcAddress: 'YOUR_BTC_ADDRESS',
  ipfsGateway: 'https://ipfs.io/ipfs/',
  ipfsRoot: 'QmEustacioFrameworkGenesis2026Complete'
};
```

### Notification Configuration

Edit `src/config/notification_propagation.yml`:

```yaml
channels:
  discord:
    enabled: true
    channels:
      - name: "treasury-updates"
        priority: "high"
        events:
          - "balance_change"
          - "runway_warning"

events:
  runway_warning:
    thresholds:
      critical: 90  # days
      warning: 180
      stable: 365
```

## Architecture

### Component Structure

```
src/
├── services/
│   ├── treasuryService.js       # Core treasury logic
│   └── notificationService.js   # Notification propagation
├── commands/
│   └── treasuryCommands.js      # Apollo Assistant commands
├── config/
│   └── notification_propagation.yml  # Notification settings
└── utils/
    └── (future utilities)

tests/
├── treasuryService.test.js      # Treasury service tests
└── treasuryCommands.test.js     # Command handler tests
```

### Data Flow

```
User Command
    ↓
Command Handler (treasuryCommands.js)
    ↓
Treasury Service (treasuryService.js)
    ↓
External APIs (Etherscan, Blockchain.info)
    ↓
Calculate Metrics
    ↓
Store to IPFS (optional)
    ↓
Notification Service (if configured)
    ↓
Discord/Telegram
```

## Health Status Levels

| Status | Runway | Description | Action |
|--------|--------|-------------|--------|
| **HEALTHY** | ≥ 12 months | Excellent sustainability | Continue operations |
| **STABLE** | 6-12 months | Good sustainability | Monitor regularly |
| **WARNING** | 3-6 months | Moderate concern | Increase fundraising |
| **CRITICAL** | < 3 months | Immediate action needed | Emergency measures |

## API Reference

### Treasury Service

#### `getTreasuryMetrics()`
Returns comprehensive treasury metrics.

**Returns:**
```javascript
{
  balances: { eth: number, btc: number },
  prices: { ethPrice: number, btcPrice: number },
  runway: {
    totalValueUSD: number,
    runwayMonths: number,
    runwayDays: number,
    healthStatus: string,
    lastUpdated: string
  },
  treasuryAddress: { eth: string, btc: string },
  timestamp: string
}
```

#### `calculateSustainabilityRunway(balances, monthlyBurnRate, prices)`
Calculates sustainability runway metrics.

**Parameters:**
- `balances` (Object): `{ eth: number, btc: number }`
- `monthlyBurnRate` (number): Monthly operational costs in USD
- `prices` (Object): `{ ethPrice: number, btcPrice: number }`

**Returns:**
```javascript
{
  totalValueUSD: number,
  runwayMonths: number,
  runwayDays: number,
  healthStatus: string,
  lastUpdated: string
}
```

#### `storeToIPFS(data)`
Stores data to IPFS for long-term resilience.

**Parameters:**
- `data` (Object): Data to store

**Returns:** Promise<string> - IPFS hash

### Treasury Commands

#### `processCommand(command)`
Processes user command and returns formatted response.

**Parameters:**
- `command` (string): Command name (e.g., 'treasury:balance')

**Returns:**
```javascript
{
  success: boolean,
  message: string
}
```

**Available Commands:**
- `treasury:balance` - Get current treasury balance
- `treasury:runway` - Get sustainability runway
- `treasury:longevity` - Get project longevity metrics
- `treasury:status` - Get full status with IPFS snapshot

## Testing

### Run Unit Tests

```bash
npm test
```

### Test Coverage

- Treasury Service: Balance queries, runway calculations, IPFS integration
- Treasury Commands: All command handlers, error handling, formatting
- Notification Service: Event propagation, Discord/Telegram integration

### Example Test

```javascript
const treasuryService = require('./src/services/treasuryService');

test('should calculate correct runway', () => {
  const balances = { eth: 10, btc: 0 };
  const result = treasuryService.calculateSustainabilityRunway(
    balances, 
    5000, 
    { ethPrice: 2000, btcPrice: 40000 }
  );
  
  expect(result.totalValueUSD).toBe(20000);
  expect(result.runwayMonths).toBe(4);
  expect(result.healthStatus).toBe('STABLE');
});
```

## Integration with Apollo Assistant

### Discord Bot Integration

```javascript
// In your Discord bot command handler
client.on('messageCreate', async message => {
  if (message.content.startsWith('!treasury')) {
    const command = message.content.split(' ')[1];
    const result = await treasuryCommands.processCommand(`treasury:${command}`);
    message.reply(result.message);
  }
});
```

### Telegram Bot Integration

```javascript
// In your Telegram bot
bot.onText(/\/treasury (.+)/, async (msg, match) => {
  const command = match[1];
  const result = await treasuryCommands.processCommand(`treasury:${command}`);
  bot.sendMessage(msg.chat.id, result.message, { parse_mode: 'Markdown' });
});
```

### Web Dashboard Integration

```javascript
import { getTreasuryMetrics } from './src/services/treasuryService';

function TreasuryDashboard() {
  const [metrics, setMetrics] = useState(null);
  
  useEffect(() => {
    async function loadMetrics() {
      const data = await getTreasuryMetrics();
      setMetrics(data);
    }
    loadMetrics();
  }, []);
  
  return (
    <div>
      <h2>Treasury Balance: {metrics?.balances.eth} ETH</h2>
      <p>Runway: {metrics?.runway.runwayMonths} months</p>
      <p>Status: {metrics?.runway.healthStatus}</p>
    </div>
  );
}
```

## Compliance

### NSR (Network State Resilience)
- **Redundancy**: Multiple IPFS gateways and notification channels
- **Fallback**: Automatic failover on service unavailability
- **Data Persistence**: IPFS ensures long-term data availability

### OLF (Open Ledger Framework)
- **Transparency**: All treasury data publicly accessible
- **Audit Trail**: Blockchain-based verification
- **Public Access**: No authentication required for viewing metrics

## Scheduled Testing

**Test Date**: January 10, 2026

### Test Checklist
- [ ] Verify real-time balance queries
- [ ] Validate runway calculations
- [ ] Test Discord notifications
- [ ] Test Telegram notifications
- [ ] Verify IPFS storage and retrieval
- [ ] Validate all Apollo Assistant commands
- [ ] Check health status classifications
- [ ] Verify error handling
- [ ] Confirm NSR/OLF compliance

## Troubleshooting

### Common Issues

**Issue**: Balance returns 0
- **Solution**: Check Ethereum RPC endpoint configuration
- **Verify**: Network connectivity and API rate limits

**Issue**: Notifications not sending
- **Solution**: Verify Discord webhook URL or Telegram bot token
- **Check**: Environment variables are correctly set

**Issue**: IPFS storage fails
- **Solution**: Check IPFS gateway availability
- **Alternative**: Use local IPFS node

## Support

- **Repository**: https://github.com/hannesmitterer/Peacebonds
- **Issues**: https://github.com/hannesmitterer/Peacebonds/issues
- **Discord**: #development channel
- **Documentation**: See README.md and this file

## License

MIT License - See repository LICENSE file

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

---

**Last Updated**: December 2025  
**Version**: 1.0.0  
**Status**: Production Ready
