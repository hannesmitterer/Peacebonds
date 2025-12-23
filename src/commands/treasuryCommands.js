/**
 * Apollo Assistant Treasury Commands
 * User-facing commands for treasury inquiries
 */

const treasuryService = require('../services/treasuryService');

/**
 * Command: Get treasury balance
 */
async function handleBalanceCommand() {
  try {
    const metrics = await treasuryService.getTreasuryMetrics();
    
    return {
      success: true,
      message: formatBalanceResponse(metrics)
    };
  } catch (error) {
    return {
      success: false,
      message: `Error retrieving treasury balance: ${error.message}`
    };
  }
}

/**
 * Command: Get sustainability runway
 */
async function handleRunwayCommand() {
  try {
    const metrics = await treasuryService.getTreasuryMetrics();
    
    return {
      success: true,
      message: formatRunwayResponse(metrics.runway)
    };
  } catch (error) {
    return {
      success: false,
      message: `Error calculating runway: ${error.message}`
    };
  }
}

/**
 * Command: Get project longevity metrics
 */
async function handleLongevityCommand() {
  try {
    const metrics = await treasuryService.getTreasuryMetrics();
    
    return {
      success: true,
      message: formatLongevityResponse(metrics)
    };
  } catch (error) {
    return {
      success: false,
      message: `Error retrieving longevity metrics: ${error.message}`
    };
  }
}

/**
 * Command: Get full treasury status
 */
async function handleStatusCommand() {
  try {
    const metrics = await treasuryService.getTreasuryMetrics();
    
    // Store snapshot to IPFS for resilience
    const ipfsHash = await treasuryService.storeToIPFS(metrics);
    
    return {
      success: true,
      message: formatFullStatusResponse(metrics, ipfsHash)
    };
  } catch (error) {
    return {
      success: false,
      message: `Error retrieving treasury status: ${error.message}`
    };
  }
}

/**
 * Format balance response for user display
 */
function formatBalanceResponse(metrics) {
  return `
📊 **Treasury Balance**

💰 ETH: ${metrics.balances.eth.toFixed(4)} ETH (≈ $${(metrics.balances.eth * metrics.prices.ethPrice).toFixed(2)})
₿ BTC: ${metrics.balances.btc.toFixed(8)} BTC (≈ $${(metrics.balances.btc * metrics.prices.btcPrice).toFixed(2)})

**Total Value**: $${metrics.runway.totalValueUSD.toFixed(2)} USD

Treasury Address (ETH): ${metrics.treasuryAddress.eth}
  `.trim();
}

/**
 * Format runway response for user display
 */
function formatRunwayResponse(runway) {
  const statusEmoji = {
    'HEALTHY': '🟢',
    'STABLE': '🟡',
    'WARNING': '🟠',
    'CRITICAL': '🔴'
  };
  
  return `
🛣️ **Sustainability Runway**

${statusEmoji[runway.healthStatus]} Status: ${runway.healthStatus}

⏱️ Runway: ${runway.runwayMonths} months (${runway.runwayDays} days)
💵 Total Value: $${runway.totalValueUSD.toFixed(2)} USD

Last Updated: ${new Date(runway.lastUpdated).toLocaleString()}
  `.trim();
}

/**
 * Format longevity response for user display
 */
function formatLongevityResponse(metrics) {
  const runway = metrics.runway;
  const projectedEndDate = new Date();
  projectedEndDate.setDate(projectedEndDate.getDate() + runway.runwayDays);
  
  return `
🌱 **Project Longevity Metrics**

Current Sustainability: ${runway.healthStatus}
Operational Runway: ${runway.runwayMonths} months
Projected Coverage Until: ${projectedEndDate.toLocaleDateString()}

Treasury Health Score: ${calculateHealthScore(runway)}%

💡 Framework Euystacio aims for continuous development and community sustainability.
  `.trim();
}

/**
 * Format full status response
 */
function formatFullStatusResponse(metrics, ipfsHash) {
  return `
🏦 **Seedbringer Treasury Status**

${formatBalanceResponse(metrics)}

${formatRunwayResponse(metrics.runway)}

📌 IPFS Snapshot: ${ipfsHash}
🔗 Retrieve: ipfs://${ipfsHash}

Timestamp: ${metrics.timestamp}
  `.trim();
}

/**
 * Calculate health score (0-100)
 */
function calculateHealthScore(runway) {
  if (runway.runwayMonths >= 12) return 100;
  if (runway.runwayMonths >= 6) return 75;
  if (runway.runwayMonths >= 3) return 50;
  if (runway.runwayMonths >= 1) return 25;
  return 10;
}

/**
 * Command registry for Apollo Assistant
 */
const commands = {
  'treasury:balance': handleBalanceCommand,
  'treasury:runway': handleRunwayCommand,
  'treasury:longevity': handleLongevityCommand,
  'treasury:status': handleStatusCommand
};

/**
 * Process command from user input
 * @param {string} command - Command name
 * @returns {Promise<Object>} Command result
 */
async function processCommand(command) {
  const handler = commands[command];
  
  if (!handler) {
    return {
      success: false,
      message: `Unknown command: ${command}\n\nAvailable commands:\n- treasury:balance\n- treasury:runway\n- treasury:longevity\n- treasury:status`
    };
  }
  
  return await handler();
}

module.exports = {
  processCommand,
  handleBalanceCommand,
  handleRunwayCommand,
  handleLongevityCommand,
  handleStatusCommand,
  commands
};
