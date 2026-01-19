# Peace Stream Integration Guide

## Overview

The Peace Stream is the real-time data flow that connects VCD-01 nodes, enabling synchronized operations, contribution tracking, and impact measurement across the distributed network. This guide explains how to integrate with the Peace Stream for node operators, developers, and service providers.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Peace Stream Layer                     │
│                                                          │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐         │
│  │  IPFS    │    │Blockchain│    │  Oracle  │         │
│  │  Events  │───▶│  Events  │◀───│  Feeds   │         │
│  └──────────┘    └──────────┘    └──────────┘         │
│       │                │                │               │
│       └────────────────┴────────────────┘               │
│                        │                                 │
│                        ▼                                 │
│              ┌─────────────────┐                        │
│              │ Stream Processor │                        │
│              └─────────────────┘                        │
│                        │                                 │
│         ┌──────────────┼──────────────┐                │
│         │              │               │                │
│         ▼              ▼               ▼                │
│   ┌──────────┐  ┌──────────┐   ┌──────────┐          │
│   │Resonance │  │ δ_E      │   │ Impact   │          │
│   │Sync      │  │Tracking  │   │Metrics   │          │
│   └──────────┘  └──────────┘   └──────────┘          │
└─────────────────────────────────────────────────────────┘
```

## Data Sources

### 1. IPFS Events

**Content Discovery:**
```javascript
const ipfs = require('ipfs-http-client');

async function subscribeToVCD01Content() {
  const client = ipfs.create({
    host: 'ipfs.vcd01.network',
    port: 5001,
    protocol: 'https'
  });
  
  // Subscribe to VCD-01 namespace
  const subscription = client.pubsub.subscribe(
    'vcd01-peace-stream',
    (message) => {
      const data = JSON.parse(message.data.toString());
      handlePeaceStreamEvent(data);
    }
  );
  
  return subscription;
}

function handlePeaceStreamEvent(event) {
  switch(event.type) {
    case 'MANIFEST_UPDATE':
      updateLocalManifest(event.cid);
      break;
    case 'IMPACT_REPORT':
      processImpactMetrics(event.data);
      break;
    case 'GOVERNANCE_PROPOSAL':
      notifyGovernanceUpdate(event.proposal);
      break;
    default:
      logUnknownEvent(event);
  }
}
```

**Document Pinning:**
```javascript
async function monitorCriticalContent() {
  const criticalCIDs = await loadCriticalDocuments();
  
  for (const doc of criticalCIDs) {
    // Ensure local pin
    await client.pin.add(doc.cid);
    
    // Monitor for updates
    client.name.resolve(doc.ipnsKey, (err, path) => {
      if (path !== doc.currentPath) {
        console.log(`Update detected for ${doc.name}`);
        handleDocumentUpdate(doc, path);
      }
    });
  }
}
```

### 2. Blockchain Events

**Smart Contract Event Listening:**
```javascript
const ethers = require('ethers');

async function subscribeToContractEvents() {
  const provider = new ethers.providers.JsonRpcProvider(
    process.env.ETHEREUM_RPC_URL
  );
  
  // PeaceContributionEngine events
  const contributionContract = new ethers.Contract(
    process.env.CONTRIBUTION_ENGINE_ADDRESS,
    ContributionEngineABI,
    provider
  );
  
  // Listen for contributions
  contributionContract.on('ContributionReceived', 
    (contributionId, contributor, amount, tax, category, event) => {
      console.log(`New contribution: ${contributionId}`);
      
      streamEvent({
        type: 'CONTRIBUTION',
        contributionId: contributionId.toString(),
        contributor: contributor,
        amount: ethers.utils.formatEther(amount),
        contributionTax: ethers.utils.formatEther(tax),
        category: category,
        blockNumber: event.blockNumber,
        transactionHash: event.transactionHash
      });
    }
  );
  
  // Listen for Impact NFT minting
  contributionContract.on('ImpactNFTMinted',
    (tokenId, contributionId, recipient, impactScore, ipfsCID, event) => {
      console.log(`Impact NFT minted: ${tokenId}`);
      
      streamEvent({
        type: 'IMPACT_NFT',
        tokenId: tokenId.toString(),
        contributionId: contributionId.toString(),
        recipient: recipient,
        impactScore: impactScore.toString(),
        reportCID: ipfsCID,
        blockNumber: event.blockNumber,
        transactionHash: event.transactionHash
      });
      
      // Fetch and process impact report
      fetchImpactReport(ipfsCID);
    }
  );
  
  // Listen for fund distributions
  contributionContract.on('FundsDistributed',
    (contributionId, category, amount, recipient, event) => {
      console.log(`Funds distributed: ${category}`);
      
      streamEvent({
        type: 'DISTRIBUTION',
        contributionId: contributionId.toString(),
        category: category,
        amount: ethers.utils.formatEther(amount),
        recipient: recipient,
        blockNumber: event.blockNumber,
        transactionHash: event.transactionHash
      });
    }
  );
  
  // PeaceBondAnchor events
  const anchorContract = new ethers.Contract(
    process.env.ANCHOR_CONTRACT_ADDRESS,
    PeaceBondAnchorABI,
    provider
  );
  
  anchorContract.on('PeaceBondAnchored',
    (tokenId, manifestCID, signatureCID, manifestHash, signatureHash, 
     creator, timestamp, event) => {
      console.log(`PeaceBond anchored: ${tokenId}`);
      
      streamEvent({
        type: 'PEACEBOND_ANCHOR',
        tokenId: tokenId.toString(),
        manifestCID: manifestCID,
        signatureCID: signatureCID,
        creator: creator,
        timestamp: timestamp.toString(),
        blockNumber: event.blockNumber,
        transactionHash: event.transactionHash
      });
      
      // Pin the manifest and signatures
      pinPeaceBondContent(manifestCID, signatureCID);
    }
  );
}
```

**Historical Event Sync:**
```javascript
async function syncHistoricalEvents(fromBlock = 0) {
  const provider = new ethers.providers.JsonRpcProvider(
    process.env.ETHEREUM_RPC_URL
  );
  
  const contract = new ethers.Contract(
    process.env.CONTRIBUTION_ENGINE_ADDRESS,
    ContributionEngineABI,
    provider
  );
  
  // Fetch in chunks to avoid RPC limits
  const currentBlock = await provider.getBlockNumber();
  const chunkSize = 10000;
  
  for (let i = fromBlock; i < currentBlock; i += chunkSize) {
    const toBlock = Math.min(i + chunkSize - 1, currentBlock);
    
    console.log(`Syncing blocks ${i} to ${toBlock}`);
    
    const contributionEvents = await contract.queryFilter(
      contract.filters.ContributionReceived(),
      i,
      toBlock
    );
    
    for (const event of contributionEvents) {
      await processHistoricalContribution(event);
    }
    
    // Save checkpoint
    await saveCheckpoint(toBlock);
  }
}
```

### 3. Oracle Feeds

**Real-World Data Integration:**
```javascript
async function subscribeToOracleFeeds() {
  // Example: Chainlink price feeds for ETH/USD
  const aggregatorV3InterfaceABI = [
    {
      inputs: [],
      name: "latestRoundData",
      outputs: [
        { name: "roundId", type: "uint80" },
        { name: "answer", type: "int256" },
        { name: "startedAt", type: "uint256" },
        { name: "updatedAt", type: "uint256" },
        { name: "answeredInRound", type: "uint80" }
      ],
      stateMutability: "view",
      type: "function"
    }
  ];
  
  const provider = new ethers.providers.JsonRpcProvider(
    process.env.ETHEREUM_RPC_URL
  );
  
  const priceFeed = new ethers.Contract(
    '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419', // ETH/USD on Mainnet
    aggregatorV3InterfaceABI,
    provider
  );
  
  // Poll for price updates
  setInterval(async () => {
    const roundData = await priceFeed.latestRoundData();
    const price = parseFloat(ethers.utils.formatUnits(roundData.answer, 8));
    
    streamEvent({
      type: 'PRICE_UPDATE',
      asset: 'ETH/USD',
      price: price,
      timestamp: roundData.updatedAt.toString()
    });
  }, 60000); // Every minute
}

// Custom oracle for impact metrics
async function publishImpactMetrics(metrics) {
  const provider = new ethers.providers.JsonRpcProvider(
    process.env.ETHEREUM_RPC_URL
  );
  
  const wallet = new ethers.Wallet(
    process.env.ORACLE_PRIVATE_KEY,
    provider
  );
  
  const oracleContract = new ethers.Contract(
    process.env.IMPACT_ORACLE_ADDRESS,
    ImpactOracleABI,
    wallet
  );
  
  // Publish signed metrics
  const message = ethers.utils.solidityKeccak256(
    ['uint256', 'uint256', 'uint256', 'uint256'],
    [
      metrics.beneficiariesReached,
      metrics.resourcesDeployed,
      metrics.impactScore,
      Math.floor(Date.now() / 1000)
    ]
  );
  
  const signature = await wallet.signMessage(
    ethers.utils.arrayify(message)
  );
  
  const tx = await oracleContract.publishMetrics(
    metrics.beneficiariesReached,
    metrics.resourcesDeployed,
    metrics.impactScore,
    signature
  );
  
  await tx.wait();
  
  console.log(`Impact metrics published: ${tx.hash}`);
}
```

## Stream Processing

### Event Aggregation

```javascript
class PeaceStreamProcessor {
  constructor() {
    this.eventQueue = [];
    this.subscribers = new Map();
    this.metrics = {
      totalContributions: 0,
      totalImpact: 0,
      activeNodes: 0,
      resonanceCoherence: 0
    };
  }
  
  // Add event to queue
  async addEvent(event) {
    event.receivedAt = Date.now();
    this.eventQueue.push(event);
    
    // Process immediately
    await this.processEvent(event);
    
    // Notify subscribers
    this.notifySubscribers(event);
  }
  
  // Process individual event
  async processEvent(event) {
    switch(event.type) {
      case 'CONTRIBUTION':
        this.metrics.totalContributions += parseFloat(event.amount);
        await this.updateDashboard('contributions', this.metrics.totalContributions);
        break;
        
      case 'IMPACT_NFT':
        this.metrics.totalImpact += parseInt(event.impactScore);
        await this.updateDashboard('impact', this.metrics.totalImpact);
        break;
        
      case 'NODE_STATUS':
        await this.updateNodeStatus(event);
        break;
        
      case 'RESONANCE_UPDATE':
        this.metrics.resonanceCoherence = parseFloat(event.coherence);
        break;
        
      default:
        console.warn(`Unknown event type: ${event.type}`);
    }
  }
  
  // Subscribe to specific event types
  subscribe(eventType, callback) {
    if (!this.subscribers.has(eventType)) {
      this.subscribers.set(eventType, []);
    }
    this.subscribers.get(eventType).push(callback);
  }
  
  // Notify all subscribers of an event
  notifySubscribers(event) {
    const typeSubscribers = this.subscribers.get(event.type) || [];
    const allSubscribers = this.subscribers.get('*') || [];
    
    [...typeSubscribers, ...allSubscribers].forEach(callback => {
      try {
        callback(event);
      } catch (error) {
        console.error(`Subscriber error: ${error.message}`);
      }
    });
  }
  
  // Get aggregated metrics
  getMetrics() {
    return {
      ...this.metrics,
      timestamp: Date.now(),
      eventQueueSize: this.eventQueue.length
    };
  }
}

// Initialize processor
const streamProcessor = new PeaceStreamProcessor();

// Subscribe to contributions
streamProcessor.subscribe('CONTRIBUTION', async (event) => {
  console.log(`Processing contribution: ${event.contributionId}`);
  
  // Update database
  await db.contributions.insert({
    id: event.contributionId,
    contributor: event.contributor,
    amount: event.amount,
    category: event.category,
    timestamp: Date.now()
  });
  
  // Trigger impact calculation
  await calculatePotentialImpact(event);
});

// Subscribe to all events for logging
streamProcessor.subscribe('*', async (event) => {
  await db.eventLog.insert({
    type: event.type,
    data: event,
    processedAt: Date.now()
  });
});
```

### Real-Time Dashboard Updates

```javascript
const WebSocket = require('ws');

class DashboardServer {
  constructor(port = 8080) {
    this.wss = new WebSocket.Server({ port });
    this.clients = new Set();
    
    this.wss.on('connection', (ws) => {
      this.clients.add(ws);
      
      // Send current state
      ws.send(JSON.stringify({
        type: 'INITIAL_STATE',
        data: streamProcessor.getMetrics()
      }));
      
      ws.on('close', () => {
        this.clients.delete(ws);
      });
    });
  }
  
  broadcast(event) {
    const message = JSON.stringify(event);
    
    this.clients.forEach(client => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(message);
      }
    });
  }
}

// Start dashboard server
const dashboard = new DashboardServer(8080);

// Forward all stream events to dashboard
streamProcessor.subscribe('*', (event) => {
  dashboard.broadcast({
    type: 'STREAM_EVENT',
    event: event
  });
});

// Periodic metrics broadcast
setInterval(() => {
  dashboard.broadcast({
    type: 'METRICS_UPDATE',
    metrics: streamProcessor.getMetrics()
  });
}, 5000); // Every 5 seconds
```

## Resonance Synchronization

### Ψ₀.₀₄₃ Frequency Tracking

```javascript
class ResonanceTracker {
  constructor() {
    this.targetFrequency = 0.043; // Ψ₀.₀₄₃ Hz
    this.tolerance = 0.001;
    this.measurements = [];
    this.syncStatus = 'unknown';
  }
  
  async measureResonance() {
    // In production: actual network timing measurements
    // For now: simulate with NTP sync and network latency
    
    const ntpSync = await this.checkNTPSync();
    const networkLatency = await this.measureNetworkLatency();
    const consensusDelay = await this.measureConsensusDelay();
    
    // Calculate effective resonance frequency
    const baseFrequency = this.targetFrequency;
    const jitter = this.calculateJitter(ntpSync, networkLatency, consensusDelay);
    const currentFrequency = baseFrequency + jitter;
    
    this.measurements.push({
      timestamp: Date.now(),
      frequency: currentFrequency,
      ntpSync: ntpSync,
      networkLatency: networkLatency,
      consensusDelay: consensusDelay
    });
    
    // Keep last 100 measurements
    if (this.measurements.length > 100) {
      this.measurements.shift();
    }
    
    // Update sync status
    const deviation = Math.abs(currentFrequency - this.targetFrequency);
    this.syncStatus = deviation <= this.tolerance ? 'synchronized' : 'out-of-sync';
    
    // Stream resonance update
    streamEvent({
      type: 'RESONANCE_UPDATE',
      frequency: currentFrequency,
      target: this.targetFrequency,
      deviation: deviation,
      status: this.syncStatus,
      coherence: this.calculateCoherence()
    });
    
    return {
      frequency: currentFrequency,
      status: this.syncStatus
    };
  }
  
  calculateJitter(ntpSync, networkLatency, consensusDelay) {
    // Simplified jitter calculation
    // In production: use actual network timing protocols
    const ntpJitter = ntpSync ? 0.0001 : 0.001;
    const latencyJitter = networkLatency / 10000;
    const consensusJitter = consensusDelay / 5000;
    
    return (ntpJitter + latencyJitter + consensusJitter) * (Math.random() - 0.5);
  }
  
  calculateCoherence() {
    if (this.measurements.length < 10) {
      return 0;
    }
    
    // Calculate standard deviation of recent measurements
    const recent = this.measurements.slice(-20);
    const frequencies = recent.map(m => m.frequency);
    const mean = frequencies.reduce((a, b) => a + b) / frequencies.length;
    const variance = frequencies.reduce((sum, f) => sum + Math.pow(f - mean, 2), 0) / frequencies.length;
    const stdDev = Math.sqrt(variance);
    
    // Coherence is inverse of deviation (0-100%)
    const coherence = Math.max(0, 100 - (stdDev / this.tolerance * 100));
    
    return coherence;
  }
  
  async checkNTPSync() {
    // Check if system time is synchronized via NTP
    try {
      const { exec } = require('child_process');
      const { promisify } = require('util');
      const execAsync = promisify(exec);
      
      const { stdout } = await execAsync('timedatectl status');
      return stdout.includes('synchronized: yes') || stdout.includes('NTP service: active');
    } catch (error) {
      return false;
    }
  }
  
  async measureNetworkLatency() {
    // Measure round-trip time to reference nodes
    const referenceNodes = [
      'https://node1.vcd01.network',
      'https://node2.vcd01.network',
      'https://node3.vcd01.network'
    ];
    
    const latencies = [];
    
    for (const node of referenceNodes) {
      const start = Date.now();
      try {
        await fetch(`${node}/ping`);
        const latency = Date.now() - start;
        latencies.push(latency);
      } catch (error) {
        // Node unavailable, skip
      }
    }
    
    if (latencies.length === 0) {
      return 1000; // Default high latency if no nodes reachable
    }
    
    // Return median latency
    latencies.sort((a, b) => a - b);
    return latencies[Math.floor(latencies.length / 2)];
  }
  
  async measureConsensusDelay() {
    // Measure time for consensus round
    // In production: actual BFT consensus timing
    // For now: simulate based on recent block times
    
    const provider = new ethers.providers.JsonRpcProvider(
      process.env.ETHEREUM_RPC_URL
    );
    
    try {
      const currentBlock = await provider.getBlockNumber();
      const block1 = await provider.getBlock(currentBlock);
      const block2 = await provider.getBlock(currentBlock - 1);
      
      const delay = block1.timestamp - block2.timestamp;
      return delay * 1000; // Convert to ms
    } catch (error) {
      return 12000; // Default 12s block time
    }
  }
}

// Start resonance tracking
const resonanceTracker = new ResonanceTracker();

setInterval(async () => {
  await resonanceTracker.measureResonance();
}, 60000); // Every minute
```

## δ_E (Ethical Dividend) Tracking

### Contribution Flow Monitoring

```javascript
async function trackContributionFlow() {
  streamProcessor.subscribe('CONTRIBUTION', async (event) => {
    const contribution = {
      id: event.contributionId,
      contributor: event.contributor,
      amount: parseFloat(event.amount),
      tax: parseFloat(event.contributionTax),
      category: event.category,
      timestamp: Date.now(),
      blockNumber: event.blockNumber,
      txHash: event.transactionHash
    };
    
    // Calculate allocations
    const allocations = {
      IDRO: contribution.tax * 0.40,
      HELIOS: contribution.tax * 0.35,
      RnD: contribution.tax * 0.15,
      Operations: contribution.tax * 0.10
    };
    
    // Store and broadcast
    await db.contributions.insert(contribution);
    await db.allocations.insert({
      contributionId: contribution.id,
      ...allocations,
      timestamp: Date.now()
    });
    
    dashboard.broadcast({
      type: 'ALLOCATION_UPDATE',
      contributionId: contribution.id,
      allocations: allocations,
      totalAllocated: contribution.tax
    });
  });
}
```

### Impact Metrics Aggregation

```javascript
async function aggregateImpactMetrics() {
  streamProcessor.subscribe('IMPACT_NFT', async (event) => {
    // Fetch full impact report from IPFS
    const report = await ipfs.cat(event.reportCID);
    const impactData = JSON.parse(report.toString());
    
    // Aggregate metrics
    const metrics = {
      tokenId: event.tokenId,
      contributionId: event.contributionId,
      impactScore: parseInt(event.impactScore),
      beneficiariesReached: impactData.beneficiariesReached,
      resourcesDeployed: impactData.resourcesDeployed,
      category: impactData.category,
      details: impactData.details,
      timestamp: Date.now()
    };
    
    await db.impactMetrics.insert(metrics);
    
    // Update aggregate statistics
    const aggregates = await db.impactMetrics.aggregate([
      {
        $group: {
          _id: '$category',
          totalImpact: { $sum: '$impactScore' },
          totalBeneficiaries: { $sum: '$beneficiariesReached' },
          totalResources: { $sum: '$resourcesDeployed' },
          count: { $sum: 1 }
        }
      }
    ]);
    
    dashboard.broadcast({
      type: 'IMPACT_AGGREGATES',
      aggregates: aggregates
    });
  });
}
```

## Integration Examples

### Node Operator Integration

```javascript
// example-node-integration.js
const { PeaceStreamClient } = require('vcd01-peace-stream');

async function main() {
  // Initialize client
  const client = new PeaceStreamClient({
    nodeId: process.env.NODE_ID,
    privateKey: process.env.NODE_PRIVATE_KEY,
    ipfsHost: 'ipfs.vcd01.network',
    rpcUrl: process.env.ETHEREUM_RPC_URL
  });
  
  // Connect to stream
  await client.connect();
  
  // Subscribe to events relevant to this node
  client.on('CONTRIBUTION', (event) => {
    console.log(`Contribution received: ${event.contributionId}`);
  });
  
  client.on('GOVERNANCE_PROPOSAL', (event) => {
    console.log(`New proposal: ${event.proposal.title}`);
    // Trigger voting notification
  });
  
  // Publish node status
  setInterval(() => {
    client.publish({
      type: 'NODE_STATUS',
      nodeId: process.env.NODE_ID,
      uptime: process.uptime(),
      resonance: resonanceTracker.measurements.slice(-1)[0],
      peersConnected: getPeerCount()
    });
  }, 60000);
  
  // Handle graceful shutdown
  process.on('SIGINT', async () => {
    await client.disconnect();
    process.exit(0);
  });
}

main().catch(console.error);
```

### Application Integration

```javascript
// example-app-integration.js
const { PeaceStreamClient } = require('vcd01-peace-stream');

class VCD01Application {
  constructor() {
    this.client = new PeaceStreamClient({
      appId: 'my-vcd01-app',
      apiKey: process.env.VCD01_API_KEY
    });
  }
  
  async initialize() {
    await this.client.connect();
    
    // Subscribe to impact updates
    this.client.on('IMPACT_NFT', async (event) => {
      await this.displayImpact(event);
    });
    
    // Subscribe to contribution flow
    this.client.on('CONTRIBUTION', async (event) => {
      await this.updateContributionStats(event);
    });
  }
  
  async makeContribution(amount) {
    // Submit contribution through Peace Contribution Engine
    const tx = await this.client.contribute(amount);
    
    console.log(`Contribution submitted: ${tx.hash}`);
    
    // Wait for confirmation and impact assessment
    const receipt = await tx.wait();
    
    return receipt;
  }
  
  async getImpactStats() {
    // Query aggregated impact metrics
    return await this.client.queryMetrics({
      type: 'impact',
      timeRange: '30d',
      categories: ['IDRO', 'HELIOS']
    });
  }
}
```

## API Reference

### PeaceStreamClient

```typescript
class PeaceStreamClient {
  constructor(config: {
    nodeId?: string;
    appId?: string;
    privateKey?: string;
    apiKey?: string;
    ipfsHost?: string;
    rpcUrl?: string;
  });
  
  // Connection management
  async connect(): Promise<void>;
  async disconnect(): Promise<void>;
  
  // Event subscription
  on(eventType: string, callback: (event: any) => void): void;
  off(eventType: string, callback: (event: any) => void): void;
  
  // Event publishing
  async publish(event: object): Promise<void>;
  
  // Contribution methods
  async contribute(amount: string): Promise<Transaction>;
  async getContributionHistory(address: string): Promise<Contribution[]>;
  
  // Impact queries
  async queryMetrics(query: MetricsQuery): Promise<Metrics>;
  async getImpactReport(tokenId: string): Promise<ImpactReport>;
  
  // Governance
  async getProposals(filter?: ProposalFilter): Promise<Proposal[]>;
  async vote(proposalId: string, vote: boolean): Promise<Transaction>;
}
```

## Testing

### Local Development Setup

```bash
# Start local IPFS node
ipfs daemon &

# Start local Ethereum node
npx hardhat node &

# Deploy contracts
npm run deploy:local

# Start Peace Stream processor
node src/stream/processor.js &

# Start dashboard server
node src/dashboard/server.js &

# Run integration tests
npm test
```

### Integration Tests

```javascript
// test/peace-stream.test.js
const { expect } = require('chai');
const { PeaceStreamClient } = require('../src');

describe('Peace Stream Integration', () => {
  let client;
  
  beforeEach(async () => {
    client = new PeaceStreamClient({
      rpcUrl: 'http://localhost:8545'
    });
    await client.connect();
  });
  
  afterEach(async () => {
    await client.disconnect();
  });
  
  it('should receive contribution events', (done) => {
    client.on('CONTRIBUTION', (event) => {
      expect(event.type).to.equal('CONTRIBUTION');
      expect(event.contributionId).to.exist;
      done();
    });
    
    // Trigger contribution
    client.contribute('1.0');
  });
  
  it('should track impact metrics', async () => {
    const metrics = await client.queryMetrics({
      type: 'impact',
      timeRange: '7d'
    });
    
    expect(metrics).to.have.property('totalImpact');
    expect(metrics).to.have.property('beneficiariesReached');
  });
});
```

## Troubleshooting

### Common Issues

**Stream Connection Fails:**
```
Error: Failed to connect to Peace Stream

Solution:
1. Check network connectivity
2. Verify IPFS daemon is running: ipfs id
3. Check Ethereum RPC URL is accessible
4. Ensure firewall allows required ports (4001, 30303)
```

**Events Not Received:**
```
Warning: No events received for 5 minutes

Solution:
1. Verify subscription is active
2. Check event filters are correct
3. Ensure blockchain sync is complete
4. Review IPFS pubsub subscriptions: ipfs pubsub ls
```

**High Latency:**
```
Warning: Stream latency >5 seconds

Solution:
1. Check network bandwidth
2. Reduce event subscription scope
3. Use local IPFS node instead of remote
4. Optimize event processing logic
```

## Best Practices

1. **Event Handling:**
   - Process events asynchronously
   - Implement retry logic for failures
   - Use message queues for high throughput
   - Log all events for debugging

2. **Resource Management:**
   - Close connections on shutdown
   - Limit concurrent subscriptions
   - Implement backpressure handling
   - Monitor memory usage

3. **Security:**
   - Validate all incoming events
   - Use secure websocket (wss://)
   - Keep private keys secure
   - Implement rate limiting

4. **Monitoring:**
   - Track event processing latency
   - Monitor subscription health
   - Alert on missing events
   - Log anomalies

## Support

- **Documentation:** https://docs.vcd01.network/peace-stream
- **Discord:** https://discord.gg/vcd01 #peace-stream
- **GitHub:** https://github.com/hannesmitterer/Peacebonds/issues
- **Email:** developers@vcd01.network

---

**Document Version:** 1.0  
**Last Updated:** January 2026  
**Maintained By:** VE Technical Team
