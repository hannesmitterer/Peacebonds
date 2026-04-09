/**
 * TrustWallet Integration Module
 * Integrates TrustWallet Core for secure key management and transaction signing
 * Compatible with Euystacio Framework v1.1 Security Layer
 */

import { ethers } from 'ethers';
import * as crypto from 'crypto';

export interface TrustWalletConfig {
  mnemonic?: string;
  privateKey?: string;
  derivationPath?: string;
  networkId?: number;
  rpcUrl?: string;
}

export interface SecureTransaction {
  to: string;
  value: string;
  data?: string;
  nonce?: number;
  gasLimit?: string;
  gasPrice?: string;
}

export interface WalletBackup {
  encrypted: string;
  iv: string;
  salt: string;
  timestamp: number;
  checksum: string;
}

/**
 * TrustWallet Integration Class
 * Provides secure wallet operations with Peace Bonds framework
 */
export class TrustWalletIntegration {
  private wallet: ethers.Wallet | null = null;
  private provider: ethers.JsonRpcProvider | null = null;
  private readonly derivationPath: string;
  private readonly networkId: number;

  constructor(config: TrustWalletConfig) {
    this.derivationPath = config.derivationPath || "m/44'/60'/0'/0/0";
    this.networkId = config.networkId || 1; // Mainnet by default

    if (config.rpcUrl) {
      this.provider = new ethers.JsonRpcProvider(config.rpcUrl);
    }

    if (config.mnemonic) {
      this.initializeFromMnemonic(config.mnemonic);
    } else if (config.privateKey) {
      this.initializeFromPrivateKey(config.privateKey);
    }
  }

  /**
   * Initialize wallet from mnemonic (BIP39)
   */
  private initializeFromMnemonic(mnemonic: string): void {
    const hdNode = ethers.HDNodeWallet.fromPhrase(mnemonic, undefined, this.derivationPath);
    this.wallet = new ethers.Wallet(hdNode.privateKey);

    if (this.provider) {
      this.wallet = this.wallet.connect(this.provider);
    }
  }

  /**
   * Initialize wallet from private key
   */
  private initializeFromPrivateKey(privateKey: string): void {
    this.wallet = new ethers.Wallet(privateKey);

    if (this.provider) {
      this.wallet = this.wallet.connect(this.provider);
    }
  }

  /**
   * Generate new wallet with mnemonic
   */
  public static generateWallet(): { wallet: ethers.Wallet; mnemonic: string } {
    const wallet = ethers.Wallet.createRandom();
    return {
      wallet,
      mnemonic: wallet.mnemonic?.phrase || ''
    };
  }

  /**
   * Get wallet address
   */
  public getAddress(): string {
    if (!this.wallet) {
      throw new Error('Wallet not initialized');
    }
    return this.wallet.address;
  }

  /**
   * Get wallet balance
   */
  public async getBalance(): Promise<string> {
    if (!this.wallet) {
      throw new Error('Wallet not initialized');
    }

    const balance = await this.wallet.provider?.getBalance(this.wallet.address);
    return ethers.formatEther(balance || 0);
  }

  /**
   * Sign message with wallet
   */
  public async signMessage(message: string): Promise<string> {
    if (!this.wallet) {
      throw new Error('Wallet not initialized');
    }

    return await this.wallet.signMessage(message);
  }

  /**
   * Sign transaction with wallet
   */
  public async signTransaction(tx: SecureTransaction): Promise<string> {
    if (!this.wallet) {
      throw new Error('Wallet not initialized');
    }

    const transaction = {
      to: tx.to,
      value: ethers.parseEther(tx.value),
      data: tx.data || '0x',
      nonce: tx.nonce,
      gasLimit: tx.gasLimit ? BigInt(tx.gasLimit) : undefined,
      gasPrice: tx.gasPrice ? BigInt(tx.gasPrice) : undefined
    };

    return await this.wallet.signTransaction(transaction);
  }

  /**
   * Send transaction
   */
  public async sendTransaction(tx: SecureTransaction): Promise<string> {
    if (!this.wallet) {
      throw new Error('Wallet not initialized');
    }

    if (!this.provider) {
      throw new Error('Provider not configured');
    }

    const transaction = {
      to: tx.to,
      value: ethers.parseEther(tx.value),
      data: tx.data || '0x',
      gasLimit: tx.gasLimit ? BigInt(tx.gasLimit) : undefined,
      gasPrice: tx.gasPrice ? BigInt(tx.gasPrice) : undefined
    };

    const txResponse = await this.wallet.sendTransaction(transaction);
    return txResponse.hash;
  }

  /**
   * Encrypt wallet for secure backup (compatible with IPFS backup system)
   */
  public async encryptWallet(password: string): Promise<WalletBackup> {
    if (!this.wallet) {
      throw new Error('Wallet not initialized');
    }

    const privateKey = this.wallet.privateKey;

    // Generate salt and IV
    const salt = crypto.randomBytes(32);
    const iv = crypto.randomBytes(16);

    // Derive key from password
    const key = crypto.pbkdf2Sync(password, salt, 100000, 32, 'sha256');

    // Encrypt private key
    const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
    let encrypted = cipher.update(privateKey, 'utf8', 'hex');
    encrypted += cipher.final('hex');

    // Calculate checksum
    const checksum = crypto
      .createHash('sha256')
      .update(encrypted + salt.toString('hex') + iv.toString('hex'))
      .digest('hex');

    return {
      encrypted,
      iv: iv.toString('hex'),
      salt: salt.toString('hex'),
      timestamp: Date.now(),
      checksum
    };
  }

  /**
   * Decrypt wallet from backup
   */
  public static async decryptWallet(
    backup: WalletBackup,
    password: string
  ): Promise<string> {
    // Verify checksum
    const checksum = crypto
      .createHash('sha256')
      .update(backup.encrypted + backup.salt + backup.iv)
      .digest('hex');

    if (checksum !== backup.checksum) {
      throw new Error('Backup integrity check failed');
    }

    // Derive key from password
    const key = crypto.pbkdf2Sync(
      password,
      Buffer.from(backup.salt, 'hex'),
      100000,
      32,
      'sha256'
    );

    // Decrypt private key
    const decipher = crypto.createDecipheriv(
      'aes-256-cbc',
      key,
      Buffer.from(backup.iv, 'hex')
    );

    let decrypted = decipher.update(backup.encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');

    return decrypted;
  }

  /**
   * Verify Peace Bond signature (integration with Peace Bonds framework)
   */
  public async verifyPeaceBondSignature(
    message: string,
    signature: string,
    expectedAddress: string
  ): Promise<boolean> {
    try {
      const recoveredAddress = ethers.verifyMessage(message, signature);
      return recoveredAddress.toLowerCase() === expectedAddress.toLowerCase();
    } catch (error) {
      return false;
    }
  }

  /**
   * Sign Peace Bond commitment
   */
  public async signPeaceBondCommitment(
    bondData: {
      amount: string;
      recipient: string;
      duration: number;
      conditions: string;
    }
  ): Promise<{ signature: string; hash: string }> {
    if (!this.wallet) {
      throw new Error('Wallet not initialized');
    }

    // Create structured message
    const message = JSON.stringify({
      type: 'PEACE_BOND_COMMITMENT',
      amount: bondData.amount,
      recipient: bondData.recipient,
      duration: bondData.duration,
      conditions: bondData.conditions,
      timestamp: Date.now(),
      network: this.networkId
    });

    const signature = await this.signMessage(message);
    const hash = ethers.keccak256(ethers.toUtf8Bytes(message));

    return { signature, hash };
  }

  /**
   * Export wallet for IPFS backup integration
   */
  public async exportForIPFSBackup(password: string): Promise<string> {
    const backup = await this.encryptWallet(password);
    return JSON.stringify(backup);
  }

  /**
   * Import wallet from IPFS backup
   */
  public static async importFromIPFSBackup(
    backupJson: string,
    password: string,
    rpcUrl?: string
  ): Promise<TrustWalletIntegration> {
    const backup: WalletBackup = JSON.parse(backupJson);
    const privateKey = await this.decryptWallet(backup, password);

    return new TrustWalletIntegration({
      privateKey,
      rpcUrl
    });
  }

  /**
   * Get wallet info for monitoring dashboard
   */
  public async getWalletInfo(): Promise<{
    address: string;
    balance: string;
    network: number;
    hasProvider: boolean;
  }> {
    if (!this.wallet) {
      throw new Error('Wallet not initialized');
    }

    const balance = await this.getBalance();

    return {
      address: this.wallet.address,
      balance,
      network: this.networkId,
      hasProvider: this.provider !== null
    };
  }

  /**
   * Disconnect wallet and clear sensitive data
   */
  public disconnect(): void {
    this.wallet = null;
    this.provider = null;
  }
}

export default TrustWalletIntegration;
