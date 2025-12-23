/**
 * Unit Tests for Treasury Commands
 */

const treasuryCommands = require('../src/commands/treasuryCommands');

describe('Treasury Commands', () => {
  describe('processCommand', () => {
    test('should process treasury:balance command', async () => {
      const result = await treasuryCommands.processCommand('treasury:balance');
      
      expect(result).toHaveProperty('success');
      expect(result).toHaveProperty('message');
      expect(typeof result.message).toBe('string');
    });
    
    test('should process treasury:runway command', async () => {
      const result = await treasuryCommands.processCommand('treasury:runway');
      
      expect(result).toHaveProperty('success');
      expect(result).toHaveProperty('message');
      expect(typeof result.message).toBe('string');
    });
    
    test('should process treasury:longevity command', async () => {
      const result = await treasuryCommands.processCommand('treasury:longevity');
      
      expect(result).toHaveProperty('success');
      expect(result).toHaveProperty('message');
      expect(typeof result.message).toBe('string');
    });
    
    test('should process treasury:status command', async () => {
      const result = await treasuryCommands.processCommand('treasury:status');
      
      expect(result).toHaveProperty('success');
      expect(result).toHaveProperty('message');
      expect(typeof result.message).toBe('string');
    });
    
    test('should handle unknown command', async () => {
      const result = await treasuryCommands.processCommand('treasury:unknown');
      
      expect(result.success).toBe(false);
      expect(result.message).toContain('Unknown command');
      expect(result.message).toContain('Available commands');
    });
    
    test('should list available commands on error', async () => {
      const result = await treasuryCommands.processCommand('invalid');
      
      expect(result.message).toContain('treasury:balance');
      expect(result.message).toContain('treasury:runway');
      expect(result.message).toContain('treasury:longevity');
      expect(result.message).toContain('treasury:status');
    });
  });
  
  describe('handleBalanceCommand', () => {
    test('should return balance information', async () => {
      const result = await treasuryCommands.handleBalanceCommand();
      
      expect(result.success).toBe(true);
      expect(result.message).toContain('Treasury Balance');
      expect(result.message).toContain('ETH');
      expect(result.message).toContain('Total Value');
    });
    
    test('should include treasury address', async () => {
      const result = await treasuryCommands.handleBalanceCommand();
      
      expect(result.message).toContain('Treasury Address');
      expect(result.message).toContain('0x');
    });
  });
  
  describe('handleRunwayCommand', () => {
    test('should return runway information', async () => {
      const result = await treasuryCommands.handleRunwayCommand();
      
      expect(result.success).toBe(true);
      expect(result.message).toContain('Sustainability Runway');
      expect(result.message).toContain('Status');
      expect(result.message).toContain('Runway');
      expect(result.message).toContain('months');
    });
    
    test('should include health status emoji', async () => {
      const result = await treasuryCommands.handleRunwayCommand();
      
      // Should contain one of the status emojis
      const hasEmoji = result.message.includes('🟢') || 
                       result.message.includes('🟡') || 
                       result.message.includes('🟠') || 
                       result.message.includes('🔴');
      expect(hasEmoji).toBe(true);
    });
    
    test('should include last updated timestamp', async () => {
      const result = await treasuryCommands.handleRunwayCommand();
      
      expect(result.message).toContain('Last Updated');
    });
  });
  
  describe('handleLongevityCommand', () => {
    test('should return longevity metrics', async () => {
      const result = await treasuryCommands.handleLongevityCommand();
      
      expect(result.success).toBe(true);
      expect(result.message).toContain('Project Longevity Metrics');
      expect(result.message).toContain('Sustainability');
      expect(result.message).toContain('Operational Runway');
    });
    
    test('should include health score', async () => {
      const result = await treasuryCommands.handleLongevityCommand();
      
      expect(result.message).toContain('Health Score');
      expect(result.message).toMatch(/\d+%/);
    });
    
    test('should mention Framework Euystacio', async () => {
      const result = await treasuryCommands.handleLongevityCommand();
      
      expect(result.message).toContain('Framework Euystacio');
    });
  });
  
  describe('handleStatusCommand', () => {
    test('should return full status', async () => {
      const result = await treasuryCommands.handleStatusCommand();
      
      expect(result.success).toBe(true);
      expect(result.message).toContain('Seedbringer Treasury Status');
      expect(result.message).toContain('Treasury Balance');
      expect(result.message).toContain('Sustainability Runway');
    });
    
    test('should include IPFS snapshot hash', async () => {
      const result = await treasuryCommands.handleStatusCommand();
      
      expect(result.message).toContain('IPFS Snapshot');
      expect(result.message).toContain('Qm');
    });
    
    test('should include timestamp', async () => {
      const result = await treasuryCommands.handleStatusCommand();
      
      expect(result.message).toContain('Timestamp');
    });
  });
  
  describe('commands registry', () => {
    test('should have all required commands', () => {
      expect(treasuryCommands.commands).toHaveProperty('treasury:balance');
      expect(treasuryCommands.commands).toHaveProperty('treasury:runway');
      expect(treasuryCommands.commands).toHaveProperty('treasury:longevity');
      expect(treasuryCommands.commands).toHaveProperty('treasury:status');
    });
    
    test('all commands should be functions', () => {
      Object.values(treasuryCommands.commands).forEach(command => {
        expect(typeof command).toBe('function');
      });
    });
  });
});
