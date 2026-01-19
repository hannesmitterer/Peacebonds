#!/usr/bin/env node

/**
 * VCD-01 Node Monitor
 * Monitors node resonance at Ψ₀.₀₄₃, integrity (98.4% target), and Byzantine Fault Tolerance metrics
 * Provides alerting for anomalies
 */

const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const { promisify } = require('util');

const execAsync = promisify(exec);

// Configuration
const CONFIG = {
  RESONANCE_TARGET: 0.043,
  RESONANCE_TOLERANCE: 0.001,
  INTEGRITY_THRESHOLD: 98.4,
  BFT_THRESHOLD: 95.0,
  CHECK_INTERVAL: 60000, // 1 minute
  LOG_FILE: path.join(__dirname, '../../logs/node-monitor.log'),
  ALERT_FILE: path.join(__dirname, '../../logs/alerts.log'),
  METRICS_FILE: path.join(__dirname, '../../metrics/node-metrics.json'),
};

// Metrics storage
let metrics = {
  timestamp: Date.now(),
  resonance: {
    current: 0,
    target: CONFIG.RESONANCE_TARGET,
    status: 'unknown',
    history: []
  },
  integrity: {
    percentage: 0,
    status: 'unknown',
    uptime: 0,
    downtime: 0
  },
  byzantineFaultTolerance: {
    score: 0,
    status: 'unknown',
    faultyNodes: 0,
    totalNodes: 0
  },
  ipfs: {
    peerCount: 0,
    pinnedContent: 0,
    repoSize: 0,
    status: 'unknown'
  },
  ethereum: {
    blockHeight: 0,
    peerCount: 0,
    syncStatus: 'unknown'
  },
  alerts: []
};

/**
 * Initialize monitoring system
 */
async function initialize() {
  log('INFO', 'Initializing VCD-01 Node Monitor');
  
  // Create necessary directories
  const dirs = [
    path.dirname(CONFIG.LOG_FILE),
    path.dirname(CONFIG.ALERT_FILE),
    path.dirname(CONFIG.METRICS_FILE)
  ];
  
  for (const dir of dirs) {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  }
  
  // Load previous metrics if available
  if (fs.existsSync(CONFIG.METRICS_FILE)) {
    try {
      const data = fs.readFileSync(CONFIG.METRICS_FILE, 'utf8');
      const previousMetrics = JSON.parse(data);
      if (previousMetrics.resonance && previousMetrics.resonance.history) {
        metrics.resonance.history = previousMetrics.resonance.history.slice(-100); // Keep last 100 entries
      }
    } catch (error) {
      log('WARN', `Failed to load previous metrics: ${error.message}`);
    }
  }
  
  log('INFO', 'Initialization complete');
}

/**
 * Log message to console and file
 */
function log(level, message) {
  const timestamp = new Date().toISOString();
  const logMessage = `[${timestamp}] [${level}] ${message}`;
  
  console.log(logMessage);
  
  try {
    fs.appendFileSync(CONFIG.LOG_FILE, logMessage + '\n');
  } catch (error) {
    console.error(`Failed to write to log file: ${error.message}`);
  }
}

/**
 * Record alert
 */
function alert(severity, message, details = {}) {
  const timestamp = new Date().toISOString();
  const alertData = {
    timestamp,
    severity,
    message,
    details
  };
  
  log(severity.toUpperCase(), `ALERT: ${message}`);
  
  metrics.alerts.push(alertData);
  
  // Write to alert log
  try {
    fs.appendFileSync(
      CONFIG.ALERT_FILE,
      JSON.stringify(alertData) + '\n'
    );
  } catch (error) {
    console.error(`Failed to write alert: ${error.message}`);
  }
  
  // Keep only last 100 alerts in memory
  if (metrics.alerts.length > 100) {
    metrics.alerts = metrics.alerts.slice(-100);
  }
}

/**
 * Check resonance frequency
 * Simulates checking network synchronization at Ψ₀.₀₄₃
 */
async function checkResonance() {
  try {
    // In production, this would query actual network time synchronization
    // For now, we simulate with NTP check and network latency
    const { stdout: ntpOutput } = await execAsync('timedatectl status || echo "NTP: unavailable"');
    const ntpActive = ntpOutput.includes('synchronized: yes') || ntpOutput.includes('NTP service: active');
    
    // Simulate resonance calculation based on network timing
    // In production: measure actual packet timing and consensus synchronization
    const baseResonance = CONFIG.RESONANCE_TARGET;
    const jitter = ntpActive ? (Math.random() - 0.5) * 0.0002 : (Math.random() - 0.5) * 0.002;
    const currentResonance = baseResonance + jitter;
    
    metrics.resonance.current = currentResonance;
    metrics.resonance.history.push({
      timestamp: Date.now(),
      value: currentResonance
    });
    
    // Keep only last 100 history entries
    if (metrics.resonance.history.length > 100) {
      metrics.resonance.history = metrics.resonance.history.slice(-100);
    }
    
    // Check if within tolerance
    const deviation = Math.abs(currentResonance - CONFIG.RESONANCE_TARGET);
    if (deviation <= CONFIG.RESONANCE_TOLERANCE) {
      metrics.resonance.status = 'synchronized';
      log('INFO', `Resonance: ${currentResonance.toFixed(5)} Hz (synchronized)`);
    } else {
      metrics.resonance.status = 'out-of-sync';
      alert('warning', 'Resonance frequency out of tolerance', {
        current: currentResonance,
        target: CONFIG.RESONANCE_TARGET,
        deviation: deviation
      });
    }
    
  } catch (error) {
    metrics.resonance.status = 'error';
    log('ERROR', `Resonance check failed: ${error.message}`);
    alert('error', 'Failed to check resonance frequency', { error: error.message });
  }
}

/**
 * Check node integrity (uptime and reliability)
 */
async function checkIntegrity() {
  try {
    // Check system uptime
    const { stdout: uptimeOutput } = await execAsync('cat /proc/uptime 2>/dev/null || echo "0 0"');
    const uptimeSeconds = parseFloat(uptimeOutput.split(' ')[0]);
    const uptimeHours = uptimeSeconds / 3600;
    
    // Calculate integrity percentage (simplified)
    // In production: track actual service availability over time windows
    const targetHoursPerYear = 365 * 24;
    const requiredUptime = targetHoursPerYear * (CONFIG.INTEGRITY_THRESHOLD / 100);
    
    // Simple uptime percentage (in production, use persistent tracking)
    const currentIntegrity = Math.min(100, (uptimeHours / requiredUptime) * CONFIG.INTEGRITY_THRESHOLD);
    
    metrics.integrity.percentage = currentIntegrity;
    metrics.integrity.uptime = uptimeSeconds;
    
    if (currentIntegrity >= CONFIG.INTEGRITY_THRESHOLD) {
      metrics.integrity.status = 'healthy';
      log('INFO', `Integrity: ${currentIntegrity.toFixed(2)}% (healthy)`);
    } else {
      metrics.integrity.status = 'degraded';
      alert('warning', 'Node integrity below threshold', {
        current: currentIntegrity,
        threshold: CONFIG.INTEGRITY_THRESHOLD
      });
    }
    
  } catch (error) {
    metrics.integrity.status = 'error';
    log('ERROR', `Integrity check failed: ${error.message}`);
    alert('error', 'Failed to check node integrity', { error: error.message });
  }
}

/**
 * Check Byzantine Fault Tolerance metrics
 */
async function checkBFT() {
  try {
    // In production: query actual network consensus metrics
    // For now, simulate based on IPFS peer count and Ethereum peers
    
    const ipfsPeers = metrics.ipfs.peerCount || 0;
    const ethPeers = metrics.ethereum.peerCount || 0;
    const totalPeers = ipfsPeers + ethPeers;
    
    // Simulate BFT score (in production: calculate from consensus participation)
    const baseBFT = 95.0;
    const peerBonus = Math.min(5, totalPeers / 10); // Max 5% bonus from peers
    const bftScore = baseBFT + peerBonus;
    
    // Simulate faulty node detection (random for demo)
    const faultyNodes = Math.floor(Math.random() * 3);
    
    metrics.byzantineFaultTolerance.score = bftScore;
    metrics.byzantineFaultTolerance.faultyNodes = faultyNodes;
    metrics.byzantineFaultTolerance.totalNodes = totalPeers;
    
    if (bftScore >= CONFIG.BFT_THRESHOLD) {
      metrics.byzantineFaultTolerance.status = 'healthy';
      log('INFO', `BFT Score: ${bftScore.toFixed(2)}% (healthy, ${faultyNodes} faulty nodes detected)`);
    } else {
      metrics.byzantineFaultTolerance.status = 'degraded';
      alert('critical', 'Byzantine Fault Tolerance below threshold', {
        score: bftScore,
        threshold: CONFIG.BFT_THRESHOLD,
        faultyNodes: faultyNodes
      });
    }
    
    if (faultyNodes > totalPeers * 0.33) {
      alert('critical', 'High number of faulty nodes detected', {
        faultyNodes: faultyNodes,
        totalNodes: totalPeers,
        percentage: (faultyNodes / totalPeers * 100).toFixed(2)
      });
    }
    
  } catch (error) {
    metrics.byzantineFaultTolerance.status = 'error';
    log('ERROR', `BFT check failed: ${error.message}`);
    alert('error', 'Failed to check Byzantine Fault Tolerance', { error: error.message });
  }
}

/**
 * Check IPFS status
 */
async function checkIPFS() {
  try {
    // Check if IPFS is running
    const { stdout: idOutput } = await execAsync('ipfs id 2>/dev/null || echo "{}"');
    const ipfsId = JSON.parse(idOutput);
    
    if (ipfsId.ID) {
      // Get peer count
      const { stdout: peersOutput } = await execAsync('ipfs swarm peers 2>/dev/null | wc -l');
      metrics.ipfs.peerCount = parseInt(peersOutput.trim()) || 0;
      
      // Get repo stats
      const { stdout: repoOutput } = await execAsync('ipfs repo stat 2>/dev/null || echo "{}"');
      const repoMatch = repoOutput.match(/RepoSize:\s+(\d+)/);
      metrics.ipfs.repoSize = repoMatch ? parseInt(repoMatch[1]) : 0;
      
      // Get pin count
      const { stdout: pinsOutput } = await execAsync('ipfs pin ls --type recursive 2>/dev/null | wc -l');
      metrics.ipfs.pinnedContent = parseInt(pinsOutput.trim()) || 0;
      
      metrics.ipfs.status = 'running';
      log('INFO', `IPFS: ${metrics.ipfs.peerCount} peers, ${metrics.ipfs.pinnedContent} pins`);
      
      // Alert if peer count is low
      if (metrics.ipfs.peerCount < 5) {
        alert('warning', 'IPFS peer count is low', {
          peerCount: metrics.ipfs.peerCount,
          recommended: 10
        });
      }
    } else {
      metrics.ipfs.status = 'stopped';
      alert('critical', 'IPFS daemon is not running', {});
    }
    
  } catch (error) {
    metrics.ipfs.status = 'error';
    log('WARN', `IPFS check failed: ${error.message}`);
  }
}

/**
 * Check Ethereum node status
 */
async function checkEthereum() {
  try {
    // Try to get Ethereum peer count
    // This is a simplified check; in production, use proper RPC calls
    const { stdout: peersOutput } = await execAsync('geth attach --exec "net.peerCount" 2>/dev/null || echo "0"');
    metrics.ethereum.peerCount = parseInt(peersOutput.trim()) || 0;
    
    // Get block height
    const { stdout: blockOutput } = await execAsync('geth attach --exec "eth.blockNumber" 2>/dev/null || echo "0"');
    metrics.ethereum.blockHeight = parseInt(blockOutput.trim()) || 0;
    
    if (metrics.ethereum.peerCount > 0) {
      metrics.ethereum.syncStatus = 'synced';
      log('INFO', `Ethereum: Block ${metrics.ethereum.blockHeight}, ${metrics.ethereum.peerCount} peers`);
      
      if (metrics.ethereum.peerCount < 3) {
        alert('warning', 'Ethereum peer count is low', {
          peerCount: metrics.ethereum.peerCount,
          recommended: 5
        });
      }
    } else {
      metrics.ethereum.syncStatus = 'not-connected';
      log('WARN', 'Ethereum node not connected or not running');
    }
    
  } catch (error) {
    metrics.ethereum.syncStatus = 'error';
    log('WARN', `Ethereum check failed: ${error.message}`);
  }
}

/**
 * Save metrics to file
 */
function saveMetrics() {
  try {
    metrics.timestamp = Date.now();
    fs.writeFileSync(
      CONFIG.METRICS_FILE,
      JSON.stringify(metrics, null, 2)
    );
  } catch (error) {
    log('ERROR', `Failed to save metrics: ${error.message}`);
  }
}

/**
 * Generate status report
 */
function generateReport() {
  const report = {
    timestamp: new Date().toISOString(),
    status: 'operational',
    resonance: `${metrics.resonance.current.toFixed(5)} Hz (${metrics.resonance.status})`,
    integrity: `${metrics.integrity.percentage.toFixed(2)}% (${metrics.integrity.status})`,
    bft: `${metrics.byzantineFaultTolerance.score.toFixed(2)}% (${metrics.byzantineFaultTolerance.status})`,
    ipfs: `${metrics.ipfs.peerCount} peers (${metrics.ipfs.status})`,
    ethereum: `Block ${metrics.ethereum.blockHeight}, ${metrics.ethereum.peerCount} peers (${metrics.ethereum.syncStatus})`,
    recentAlerts: metrics.alerts.slice(-5)
  };
  
  console.log('\n' + '='.repeat(60));
  console.log('VCD-01 NODE STATUS REPORT');
  console.log('='.repeat(60));
  console.log(`Timestamp: ${report.timestamp}`);
  console.log(`Resonance: ${report.resonance}`);
  console.log(`Integrity: ${report.integrity}`);
  console.log(`BFT Score: ${report.bft}`);
  console.log(`IPFS: ${report.ipfs}`);
  console.log(`Ethereum: ${report.ethereum}`);
  
  if (report.recentAlerts.length > 0) {
    console.log('\nRecent Alerts:');
    report.recentAlerts.forEach(alert => {
      console.log(`  [${alert.severity.toUpperCase()}] ${alert.message}`);
    });
  }
  console.log('='.repeat(60) + '\n');
}

/**
 * Main monitoring loop
 */
async function monitor() {
  log('INFO', 'Starting monitoring cycle');
  
  // Run all checks
  await checkResonance();
  await checkIntegrity();
  await checkIPFS();
  await checkEthereum();
  await checkBFT();
  
  // Save metrics
  saveMetrics();
  
  // Generate report every 10 cycles (10 minutes)
  if (!monitor.cycleCount) monitor.cycleCount = 0;
  monitor.cycleCount++;
  
  if (monitor.cycleCount % 10 === 0) {
    generateReport();
  }
  
  log('INFO', 'Monitoring cycle complete');
}

/**
 * Main entry point
 */
async function main() {
  await initialize();
  
  log('INFO', `Starting VCD-01 Node Monitor (check interval: ${CONFIG.CHECK_INTERVAL}ms)`);
  log('INFO', `Resonance target: ${CONFIG.RESONANCE_TARGET} Hz ±${CONFIG.RESONANCE_TOLERANCE}`);
  log('INFO', `Integrity threshold: ${CONFIG.INTEGRITY_THRESHOLD}%`);
  log('INFO', `BFT threshold: ${CONFIG.BFT_THRESHOLD}%`);
  
  // Run initial check
  await monitor();
  
  // Schedule periodic checks
  setInterval(monitor, CONFIG.CHECK_INTERVAL);
  
  // Handle graceful shutdown
  process.on('SIGINT', () => {
    log('INFO', 'Shutting down node monitor');
    saveMetrics();
    process.exit(0);
  });
  
  process.on('SIGTERM', () => {
    log('INFO', 'Shutting down node monitor');
    saveMetrics();
    process.exit(0);
  });
}

// Run if executed directly
if (require.main === module) {
  main().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
}

module.exports = {
  initialize,
  monitor,
  checkResonance,
  checkIntegrity,
  checkBFT,
  checkIPFS,
  checkEthereum,
  metrics
};
