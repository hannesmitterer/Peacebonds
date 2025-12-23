/**
 * Unit Tests for Treasury Service
 */

const treasuryService = require('../src/services/treasuryService');

describe('Treasury Service', () => {
  describe('calculateSustainabilityRunway', () => {
    test('should calculate correct runway with healthy balance', () => {
      const balances = { eth: 10, btc: 0 };
      const monthlyBurnRate = 5000;
      const prices = { ethPrice: 2000, btcPrice: 40000 };
      
      const result = treasuryService.calculateSustainabilityRunway(balances, monthlyBurnRate, prices);
      
      expect(result.totalValueUSD).toBe(20000);
      expect(result.runwayMonths).toBe(4);
      expect(result.runwayDays).toBe(120);
      expect(result.healthStatus).toBe('STABLE');
    });
    
    test('should calculate HEALTHY status with 12+ months runway', () => {
      const balances = { eth: 30, btc: 0 };
      const monthlyBurnRate = 5000;
      const prices = { ethPrice: 2000, btcPrice: 40000 };
      
      const result = treasuryService.calculateSustainabilityRunway(balances, monthlyBurnRate, prices);
      
      expect(result.runwayMonths).toBe(12);
      expect(result.healthStatus).toBe('HEALTHY');
    });
    
    test('should calculate WARNING status with 3-6 months runway', () => {
      const balances = { eth: 5, btc: 0 };
      const monthlyBurnRate = 2000;
      const prices = { ethPrice: 2000, btcPrice: 40000 };
      
      const result = treasuryService.calculateSustainabilityRunway(balances, monthlyBurnRate, prices);
      
      expect(result.runwayMonths).toBe(5);
      expect(result.healthStatus).toBe('WARNING');
    });
    
    test('should calculate CRITICAL status with < 3 months runway', () => {
      const balances = { eth: 1, btc: 0 };
      const monthlyBurnRate = 1000;
      const prices = { ethPrice: 2000, btcPrice: 40000 };
      
      const result = treasuryService.calculateSustainabilityRunway(balances, monthlyBurnRate, prices);
      
      expect(result.runwayMonths).toBe(2);
      expect(result.healthStatus).toBe('CRITICAL');
    });
    
    test('should handle BTC + ETH combined balance', () => {
      const balances = { eth: 5, btc: 0.1 };
      const monthlyBurnRate = 5000;
      const prices = { ethPrice: 2000, btcPrice: 40000 };
      
      const result = treasuryService.calculateSustainabilityRunway(balances, monthlyBurnRate, prices);
      
      expect(result.totalValueUSD).toBe(14000); // (5 * 2000) + (0.1 * 40000)
      expect(result.runwayMonths).toBe(2.8);
    });
    
    test('should handle zero burn rate', () => {
      const balances = { eth: 5, btc: 0 };
      const monthlyBurnRate = 0;
      const prices = { ethPrice: 2000, btcPrice: 40000 };
      
      const result = treasuryService.calculateSustainabilityRunway(balances, monthlyBurnRate, prices);
      
      expect(result.runwayMonths).toBe(Infinity);
      expect(result.healthStatus).toBe('HEALTHY');
    });
    
    test('should include lastUpdated timestamp', () => {
      const balances = { eth: 1, btc: 0 };
      const result = treasuryService.calculateSustainabilityRunway(balances, 1000, { ethPrice: 2000, btcPrice: 40000 });
      
      expect(result.lastUpdated).toBeDefined();
      expect(new Date(result.lastUpdated)).toBeInstanceOf(Date);
    });
  });
  
  describe('getEthBalance', () => {
    test('should return number', async () => {
      const balance = await treasuryService.getEthBalance();
      expect(typeof balance).toBe('number');
      expect(balance).toBeGreaterThanOrEqual(0);
    });
  });
  
  describe('getBtcBalance', () => {
    test('should return number', async () => {
      const balance = await treasuryService.getBtcBalance();
      expect(typeof balance).toBe('number');
      expect(balance).toBeGreaterThanOrEqual(0);
    });
    
    test('should return 0 for empty address', async () => {
      const balance = await treasuryService.getBtcBalance('');
      expect(balance).toBe(0);
    });
  });
  
  describe('getTreasuryMetrics', () => {
    test('should return complete metrics object', async () => {
      const metrics = await treasuryService.getTreasuryMetrics();
      
      expect(metrics).toHaveProperty('balances');
      expect(metrics).toHaveProperty('prices');
      expect(metrics).toHaveProperty('runway');
      expect(metrics).toHaveProperty('treasuryAddress');
      expect(metrics).toHaveProperty('timestamp');
      
      expect(metrics.balances).toHaveProperty('eth');
      expect(metrics.balances).toHaveProperty('btc');
      
      expect(metrics.runway).toHaveProperty('totalValueUSD');
      expect(metrics.runway).toHaveProperty('runwayMonths');
      expect(metrics.runway).toHaveProperty('runwayDays');
      expect(metrics.runway).toHaveProperty('healthStatus');
    });
    
    test('should include treasury addresses', async () => {
      const metrics = await treasuryService.getTreasuryMetrics();
      
      expect(metrics.treasuryAddress.eth).toBe(treasuryService.TREASURY_CONFIG.ethAddress);
    });
  });
  
  describe('storeToIPFS', () => {
    test('should return IPFS hash', async () => {
      const data = { test: 'data' };
      const hash = await treasuryService.storeToIPFS(data);
      
      expect(typeof hash).toBe('string');
      expect(hash).toMatch(/^Qm/); // IPFS hashes start with Qm
    });
  });
  
  describe('TREASURY_CONFIG', () => {
    test('should have valid configuration', () => {
      expect(treasuryService.TREASURY_CONFIG).toBeDefined();
      expect(treasuryService.TREASURY_CONFIG.ethAddress).toBeDefined();
      expect(treasuryService.TREASURY_CONFIG.ipfsGateway).toBeDefined();
      expect(treasuryService.TREASURY_CONFIG.ipfsRoot).toBeDefined();
    });
    
    test('should have correct ETH address format', () => {
      const ethAddress = treasuryService.TREASURY_CONFIG.ethAddress;
      expect(ethAddress).toMatch(/^0x[a-fA-F0-9]{40}$/);
    });
  });
});
