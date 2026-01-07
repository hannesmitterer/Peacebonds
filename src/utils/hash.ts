import { keccak256, toUtf8Bytes } from 'ethers';

/**
 * Hash utilities for PeaceBonds
 */

/**
 * Computes the keccak256 hash of a string
 * @param content The content to hash
 * @returns The keccak256 hash as a hex string
 */
export function hashString(content: string): string {
  return keccak256(toUtf8Bytes(content));
}

/**
 * Computes the keccak256 hash of binary data
 * @param data The data to hash
 * @returns The keccak256 hash as a hex string
 */
export function hashBytes(data: Uint8Array): string {
  return keccak256(data);
}

/**
 * Verifies that a hash matches the expected value
 * @param content The content to hash
 * @param expectedHash The expected hash value
 * @returns True if hashes match
 */
export function verifyHash(content: string, expectedHash: string): boolean {
  const computed = hashString(content);
  return computed.toLowerCase() === expectedHash.toLowerCase();
}
