/**
 * Notification Propagation Service
 * Handles Discord and Telegram notifications for treasury updates
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

// Polyfill for fetch in Node.js < 18
const fetch = globalThis.fetch || require('node-fetch');

// Load configuration with improved error handling
let rawConfig;
try {
  const configPath = path.join(__dirname, '../config/notification_propagation.yml');
  const fileContents = fs.readFileSync(configPath, 'utf8');
  rawConfig = yaml.load(fileContents) || {};
} catch (e) {
  console.error('Error loading notification config:', e);
  rawConfig = {};
}

/**
 * Normalize and apply safe defaults to the notification configuration.
 * Ensures required nested objects exist even if the YAML file is malformed
 * or missing sections.
 * @param {any} value - Raw configuration value loaded from YAML
 * @returns {Object} Normalized configuration object
 */
function normalizeNotificationConfig(value) {
  const config = (value && typeof value === 'object') ? value : {};

  // Ensure channels object and nested channel configs exist
  if (!config.channels || typeof config.channels !== 'object') {
    config.channels = {};
  }

  if (!config.channels.discord || typeof config.channels.discord !== 'object') {
    config.channels.discord = {};
  }
  if (typeof config.channels.discord.enabled !== 'boolean') {
    config.channels.discord.enabled = false;
  }

  if (!config.channels.telegram || typeof config.channels.telegram !== 'object') {
    config.channels.telegram = {};
  }
  if (typeof config.channels.telegram.enabled !== 'boolean') {
    config.channels.telegram.enabled = false;
  }

  // Ensure propagation configuration exists with safe nested structure
  if (!config.propagation || typeof config.propagation !== 'object') {
    config.propagation = {};
  }
  if (!config.propagation.instant_updates || typeof config.propagation.instant_updates !== 'object') {
    config.propagation.instant_updates = {};
  }
  if (!Array.isArray(config.propagation.instant_updates.events)) {
    config.propagation.instant_updates.events = [];
  }
  if (!config.propagation.batch_updates || typeof config.propagation.batch_updates !== 'object') {
    config.propagation.batch_updates = {};
  }
  if (!Array.isArray(config.propagation.batch_updates.events)) {
    config.propagation.batch_updates.events = [];
  }

  // Ensure templates exist
  if (!config.templates || typeof config.templates !== 'object') {
    config.templates = { discord: {}, telegram: {} };
  }

  return config;
}

// Final, normalized configuration used by this module
const config = normalizeNotificationConfig(rawConfig);

/**
 * Send Discord notification
 * @param {string} channel - Channel name
 * @param {string} message - Message content
 * @param {Object} data - Data for template interpolation
 */
async function sendDiscordNotification(channel, message, data = {}) {
  if (!config.channels.discord.enabled) {
    console.log('[Discord] Notifications disabled');
    return { success: false, reason: 'disabled' };
  }
  
  const webhookUrl = process.env[config.channels.discord.webhook_url_env];
  
  if (!webhookUrl) {
    console.warn('[Discord] Webhook URL not configured');
    return { success: false, reason: 'not_configured' };
  }
  
  try {
    const formattedMessage = interpolateTemplate(message, data);
    
    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        content: formattedMessage,
        username: 'Seedbringer Treasury',
        avatar_url: 'https://avatars.githubusercontent.com/u/seedbringer'
      })
    });
    
    if (response.ok) {
      console.log(`[Discord] Notification sent to ${channel}`);
      return { success: true, channel, timestamp: new Date().toISOString() };
    } else {
      throw new Error(`Discord API error: ${response.status}`);
    }
  } catch (error) {
    console.error('[Discord] Error sending notification:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Send Telegram notification
 * @param {string} channel - Channel name
 * @param {string} message - Message content
 * @param {Object} data - Data for template interpolation
 */
async function sendTelegramNotification(channel, message, data = {}) {
  if (!config.channels.telegram.enabled) {
    console.log('[Telegram] Notifications disabled');
    return { success: false, reason: 'disabled' };
  }
  
  const botToken = process.env[config.channels.telegram.bot_token_env];
  const chatId = process.env[config.channels.telegram.chat_id_env];
  
  if (!botToken || !chatId) {
    console.warn('[Telegram] Bot token or chat ID not configured');
    return { success: false, reason: 'not_configured' };
  }
  
  try {
    const formattedMessage = interpolateTemplate(message, data);
    
    const response = await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: chatId,
        text: formattedMessage,
        parse_mode: 'Markdown'
      })
    });
    
    const result = await response.json();
    
    if (result.ok) {
      console.log(`[Telegram] Notification sent to ${channel}`);
      return { success: true, channel, timestamp: new Date().toISOString() };
    } else {
      throw new Error(`Telegram API error: ${result.description}`);
    }
  } catch (error) {
    console.error('[Telegram] Error sending notification:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Interpolate template with data using safe string replacement
 * @param {string} template - Message template
 * @param {Object} data - Data for interpolation
 * @returns {string} Formatted message
 */
function interpolateTemplate(template, data) {
  let message = template;
  
  for (const [key, value] of Object.entries(data)) {
    const placeholder = `{${key}}`;
    // Use split/join instead of RegExp for security
    message = message.split(placeholder).join(String(value));
  }
  
  return message;
}

/**
 * Propagate event to all configured channels
 * @param {string} eventType - Type of event
 * @param {Object} eventData - Event data
 */
async function propagateEvent(eventType, eventData) {
  const results = [];
  
  // Determine priority
  const isPriorityEvent = config.propagation.instant_updates.events.includes(eventType);
  
  if (isPriorityEvent || shouldPropagate(eventType)) {
    // Discord propagation
    if (config.channels.discord.enabled) {
      const discordChannels = findChannelsForEvent('discord', eventType);
      
      for (const channel of discordChannels) {
        const template = config.templates.discord[eventType] || `Event: ${eventType}\nData: ${JSON.stringify(eventData)}`;
        const result = await sendDiscordNotification(channel, template, eventData);
        results.push({ platform: 'discord', channel, ...result });
      }
    }
    
    // Telegram propagation
    if (config.channels.telegram.enabled) {
      const telegramChannels = findChannelsForEvent('telegram', eventType);
      
      for (const channel of telegramChannels) {
        const template = config.templates.telegram[eventType] || `*${eventType}*\n${JSON.stringify(eventData)}`;
        const result = await sendTelegramNotification(channel, template, eventData);
        results.push({ platform: 'telegram', channel, ...result });
      }
    }
  }
  
  return {
    eventType,
    propagated: results.length > 0,
    results,
    timestamp: new Date().toISOString()
  };
}

/**
 * Find channels that should receive event
 * @param {string} platform - Platform name (discord/telegram)
 * @param {string} eventType - Event type
 * @returns {Array<string>} List of channel names
 */
function findChannelsForEvent(platform, eventType) {
  const channels = config.channels[platform]?.channels || [];
  
  return channels
    .filter(channel => channel.events.includes(eventType))
    .map(channel => channel.name);
}

/**
 * Check if event should be propagated based on configuration
 * @param {string} eventType - Event type
 * @returns {boolean} Whether to propagate
 */
function shouldPropagate(eventType) {
  // Check instant updates
  if (config.propagation.instant_updates.events.includes(eventType)) {
    return true;
  }
  
  // Check batch updates
  if (config.propagation.batch_updates.events.includes(eventType)) {
    // In production, implement batching logic
    return true;
  }
  
  return false;
}

/**
 * Create treasury update notification
 * @param {Object} metrics - Treasury metrics
 */
async function notifyTreasuryUpdate(metrics) {
  // Validate metrics object structure to prevent runtime errors
  if (!metrics || typeof metrics !== 'object') {
    console.error('Invalid metrics object provided to notifyTreasuryUpdate');
    return { eventType: 'balance_change', propagated: false, results: [], timestamp: new Date().toISOString() };
  }

  const balances = metrics.balances || {};
  const prices = metrics.prices || {};
  const runway = metrics.runway || {};

  const eventData = {
    balance_eth: (typeof balances.eth === 'number' ? balances.eth : 0).toFixed(4),
    balance_usd: (typeof balances.eth === 'number' && typeof prices.ethPrice === 'number' 
      ? balances.eth * prices.ethPrice 
      : 0).toFixed(2),
    runway_months: runway.runwayMonths || 0,
    runway_days: runway.runwayDays || 0,
    health_status: runway.healthStatus || 'UNKNOWN',
    total_value_usd: (typeof runway.totalValueUSD === 'number' ? runway.totalValueUSD : 0).toFixed(2),
    timestamp: new Date().toLocaleString()
  };
  
  return await propagateEvent('balance_change', eventData);
}

/**
 * Create runway warning notification
 * @param {Object} runway - Runway data
 */
async function notifyRunwayWarning(runway) {
  const eventData = {
    runway_days: runway.runwayDays || 0,
    runway_months: runway.runwayMonths || 0,
    health_status: runway.healthStatus || 'UNKNOWN',
    total_value_usd: (typeof runway.totalValueUSD === 'number' ? runway.totalValueUSD : 0).toFixed(2)
  };
  
  const eventType = runway.healthStatus === 'CRITICAL' ? 'runway_critical' : 'runway_warning';
  
  return await propagateEvent(eventType, eventData);
}

/**
 * Create IPFS snapshot notification
 * @param {string} ipfsHash - IPFS hash
 * @param {Object} metrics - Treasury metrics
 */
async function notifyIPFSSnapshot(ipfsHash, metrics) {
  const balances = metrics?.balances || {};
  
  const eventData = {
    ipfs_hash: ipfsHash || '',
    timestamp: new Date().toLocaleString(),
    balance_eth: (typeof balances.eth === 'number' ? balances.eth : 0).toFixed(4)
  };
  
  return await propagateEvent('ipfs_snapshot', eventData);
}

/**
 * Create funding received notification
 * @param {number} amount - Amount received in ETH
 * @param {Object} metrics - Updated treasury metrics
 */
async function notifyFundingReceived(amount, metrics) {
  const balances = metrics?.balances || {};
  const prices = metrics?.prices || {};
  const runway = metrics?.runway || {};
  
  const eventData = {
    amount_eth: (typeof amount === 'number' ? amount : 0).toFixed(4),
    amount_usd: (typeof amount === 'number' && typeof prices.ethPrice === 'number' 
      ? amount * prices.ethPrice 
      : 0).toFixed(2),
    balance_eth: (typeof balances.eth === 'number' ? balances.eth : 0).toFixed(4),
    runway_months: runway.runwayMonths || 0
  };
  
  return await propagateEvent('funding_received', eventData);
}

module.exports = {
  sendDiscordNotification,
  sendTelegramNotification,
  propagateEvent,
  notifyTreasuryUpdate,
  notifyRunwayWarning,
  notifyIPFSSnapshot,
  notifyFundingReceived
};
