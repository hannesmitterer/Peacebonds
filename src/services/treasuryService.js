/**
 * Seedbringer Treasury Service
 * Handles real-time treasury data queries and sustainability calculations
 */

// Polyfill for fetch in Node.js < 18
const fetch = globalThis.fetch || require('node-fetch');

const TREASURY_CONFIG = {
  ethAddress: '0x5d61a4B25034393A37ef9307C8Ba3aE99e49944b',
  btcAddress: '', // To be configured
  ipfsGateway: 'https://ipfs.io/ipfs/',
  ipfsRoot: 'QmEustacioFrameworkGenesis2026Complete',
  monthlyBurnRate: parseFloat(process.env.MONTHLY_BURN_RATE) || 5000 // USD, configurable via env
};

/**
 * Validate Ethereum address format (simple 0x-prefixed, 40-hex-characters check)
 * @param {string} address
 * @returns {boolean}
 */
function isValidEthereumAddress(address) {
  if (typeof address !== 'string') {
    return false;
  }
  return /^0x[a-fA-F0-9]{40}$/.test(address);
}

/**
 * Validate Bitcoin address format (legacy and bech32)
 * @param {string} address
 * @returns {boolean}
 */
function isValidBitcoinAddress(address) {
  if (typeof address !== 'string') return false;
  const trimmed = address.trim();
  if (!trimmed) return false;

  // Legacy P2PKH/P2SH (Base58) addresses starting with 1 or 3
  const legacyRegex = /^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$/;
  // Bech32 (bc1...) addresses
  const bech32Regex = /^(bc1)[0-9ac-hj-np-z]{11,71}$/;

  return legacyRegex.test(trimmed) || bech32Regex.test(trimmed);
}

/**
 * Query real-time ETH balance
 * @param {string} address - Ethereum address
 * @returns {Promise<number>} Balance in ETH
 */
async function getEthBalance(address = TREASURY_CONFIG.ethAddress) {
  try {
    if (!isValidEthereumAddress(address)) {
      console.error('Invalid Ethereum address provided to getEthBalance:', address);
      return 0;
    }

    // For production, integrate with Web3 provider
    // This is a placeholder for the actual implementation
    const apiKey = process.env.ETHERSCAN_API_KEY;
    const url = `https://api.etherscan.io/api?module=account&action=balance&address=${address}&tag=latest${apiKey ? `&apikey=${apiKey}` : ''}`;
    const response = await fetch(url);
    const data = await response.json();
    
    if (data.status === '1') {
      return parseFloat(data.result) / 1e18; // Convert Wei to ETH
    }
    return 0;
  } catch (error) {
    console.error('Error fetching ETH balance:', error);
    return 0;
  }
}

/**
 * Query real-time BTC balance
 * @param {string} address - Bitcoin address
 * @returns {Promise<number>} Balance in BTC
 */
async function getBtcBalance(address = TREASURY_CONFIG.btcAddress) {
  try {
    const normalizedAddress = typeof address === 'string' ? address.trim() : '';

    if (!normalizedAddress) {
      return 0;
    }

    if (!isValidBitcoinAddress(normalizedAddress)) {
      console.warn('Invalid Bitcoin address provided to getBtcBalance:', address);
      return 0;
    }
    
    // For production, integrate with Bitcoin API
    const response = await fetch(`https://blockchain.info/q/addressbalance/${normalizedAddress}`);
    const satoshis = await response.text();
    
    return parseFloat(satoshis) / 1e8; // Convert Satoshis to BTC
  } catch (error) {
    console.error('Error fetching BTC balance:', error);
    return 0;
  }
}

/**
 * Calculate Sustainability Runway
 * @param {Object} balances - Current treasury balances
 * @param {number} monthlyBurnRate - Monthly operational costs in USD
 * @param {Object} prices - Current crypto prices in USD
 * @returns {Object} Runway metrics
 */
function calculateSustainabilityRunway(balances, monthlyBurnRate = TREASURY_CONFIG.monthlyBurnRate, prices = {}) {
  // Validate inputs
  const safeBalances = {
    eth: (typeof balances?.eth === 'number' && balances.eth >= 0) ? balances.eth : 0,
    btc: (typeof balances?.btc === 'number' && balances.btc >= 0) ? balances.btc : 0
  };
  
  const safeBurnRate = (typeof monthlyBurnRate === 'number' && monthlyBurnRate >= 0) ? monthlyBurnRate : TREASURY_CONFIG.monthlyBurnRate;
  
  const safePrices = {
    ethPrice: (typeof prices?.ethPrice === 'number' && prices.ethPrice >= 0) ? prices.ethPrice : 2000,
    btcPrice: (typeof prices?.btcPrice === 'number' && prices.btcPrice >= 0) ? prices.btcPrice : 40000
  };
  
  const totalValueUSD = (safeBalances.eth * safePrices.ethPrice) + (safeBalances.btc * safePrices.btcPrice);
  const runwayMonths = safeBurnRate > 0 ? totalValueUSD / safeBurnRate : Infinity;
  const runwayDays = runwayMonths * 30;
  
  return {
    totalValueUSD,
    runwayMonths: Math.floor(runwayMonths * 100) / 100,
    runwayDays: Math.floor(runwayDays),
    healthStatus: getHealthStatus(runwayMonths),
    lastUpdated: new Date().toISOString()
  };
}

/**
 * Determine treasury health status
 * @param {number} runwayMonths - Months of runway remaining
 * @returns {string} Health status
 */
function getHealthStatus(runwayMonths) {
  if (runwayMonths >= 12) return 'HEALTHY';
  if (runwayMonths >= 6) return 'STABLE';
  if (runwayMonths >= 3) return 'WARNING';
  return 'CRITICAL';
}

/**
 * Fetch real-time cryptocurrency prices
 * @returns {Promise<{ ethPrice: number, btcPrice: number }>}
 */
async function fetchCryptoPrices() {
  try {
    const response = await fetch(
      'https://api.coingecko.com/api/v3/simple/price?ids=ethereum,bitcoin&vs_currencies=usd'
    );
    const data = await response.json();

    const ethPrice = data?.ethereum?.usd;
    const btcPrice = data?.bitcoin?.usd;

    if (typeof ethPrice === 'number' && typeof btcPrice === 'number') {
      return {
        ethPrice,
        btcPrice
      };
    }

    console.error('Unexpected price data format from CoinGecko:', data);
  } catch (error) {
    console.error('Error fetching crypto prices from CoinGecko:', error);
  }

  // Fallback to previous placeholder values to avoid breaking behavior
  return {
    ethPrice: 2000, // USD
    btcPrice: 40000 // USD
  };
}

/**
 * Get comprehensive treasury metrics
 * @returns {Promise<Object>} Complete treasury data
 */
async function getTreasuryMetrics() {
  const ethBalance = await getEthBalance();
  const btcBalance = await getBtcBalance();

  const prices = await fetchCryptoPrices();

  const balances = { eth: ethBalance, btc: btcBalance };
  const runway = calculateSustainabilityRunway(balances, TREASURY_CONFIG.monthlyBurnRate, prices);
  
  return {
    balances,
    prices,
    runway,
    treasuryAddress: {
      eth: TREASURY_CONFIG.ethAddress,
      btc: TREASURY_CONFIG.btcAddress
    },
    timestamp: new Date().toISOString()
  };
}

/**
 * Store treasury data to IPFS
 * @param {Object} data - Treasury data to store
 * @returns {Promise<string>} IPFS hash
 */
async function storeToIPFS(data) {
  try {
    // Placeholder for IPFS integration
    // In production, use IPFS client library (ipfs-http-client) or pinning service API
    const jsonData = JSON.stringify(data, null, 2);
    console.log('Storing to IPFS:', jsonData);
    
    // Return mock hash for now
    // TODO: Integrate with actual IPFS pinning service (Pinata, Web3.Storage, etc.)
    return 'Qm' + Math.random().toString(36).substring(2, 15);
  } catch (error) {
    console.error('Error storing to IPFS:', error);
    throw error;
  }
}

/**
 * Retrieve treasury data from IPFS
 * @param {string} hash - IPFS hash
 * @returns {Promise<Object>} Treasury data
 */
async function retrieveFromIPFS(hash) {
  try {
    const response = await fetch(`${TREASURY_CONFIG.ipfsGateway}${hash}`);
    return await response.json();
  } catch (error) {
    console.error('Error retrieving from IPFS:', error);
    throw error;
  }
}

module.exports = {
  getEthBalance,
  getBtcBalance,
  calculateSustainabilityRunway,
  getTreasuryMetrics,
  storeToIPFS,
  retrieveFromIPFS,
  TREASURY_CONFIG
};
