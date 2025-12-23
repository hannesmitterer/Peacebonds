/**
 * Notification Propagation Service
 * Handles Discord and Telegram notifications for treasury updates
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

// Load configuration
let config;
try {
  const configPath = path.join(__dirname, '../config/notification_propagation.yml');
  const fileContents = fs.readFileSync(configPath, 'utf8');
  config = yaml.load(fileContents);
} catch (e) {
  console.error('Error loading notification config:', e);
  config = { channels: { discord: { enabled: false }, telegram: { enabled: false } } };
}

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
 * Interpolate template with data
 * @param {string} template - Message template
 * @param {Object} data - Data for interpolation
 * @returns {string} Formatted message
 */
function interpolateTemplate(template, data) {
  let message = template;
  
  for (const [key, value] of Object.entries(data)) {
    const placeholder = `{${key}}`;
    message = message.replace(new RegExp(placeholder, 'g'), value);
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
  const eventData = {
    balance_eth: metrics.balances.eth.toFixed(4),
    balance_usd: (metrics.balances.eth * metrics.prices.ethPrice).toFixed(2),
    runway_months: metrics.runway.runwayMonths,
    runway_days: metrics.runway.runwayDays,
    health_status: metrics.runway.healthStatus,
    total_value_usd: metrics.runway.totalValueUSD.toFixed(2),
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
    runway_days: runway.runwayDays,
    runway_months: runway.runwayMonths,
    health_status: runway.healthStatus,
    total_value_usd: runway.totalValueUSD.toFixed(2)
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
  const eventData = {
    ipfs_hash: ipfsHash,
    timestamp: new Date().toLocaleString(),
    balance_eth: metrics.balances.eth.toFixed(4)
  };
  
  return await propagateEvent('ipfs_snapshot', eventData);
}

/**
 * Create funding received notification
 * @param {number} amount - Amount received in ETH
 * @param {Object} metrics - Updated treasury metrics
 */
async function notifyFundingReceived(amount, metrics) {
  const eventData = {
    amount_eth: amount.toFixed(4),
    amount_usd: (amount * metrics.prices.ethPrice).toFixed(2),
    balance_eth: metrics.balances.eth.toFixed(4),
    runway_months: metrics.runway.runwayMonths
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
