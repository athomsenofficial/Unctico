// EncryptionManager.swift
// Handles encryption and decryption of sensitive data (SOAP notes, medical history, etc.)

import Foundation
import CryptoKit

/// Manages encryption and decryption of sensitive data
/// Uses AES-256 encryption for HIPAA compliance
class EncryptionManager {

    // MARK: - Singleton

    static let shared = EncryptionManager()

    private init() {}

    // MARK: - Public Methods

    /// Encrypt a string
    /// - Parameter plaintext: The text to encrypt
    /// - Returns: Encrypted data as a base64 string, or nil if encryption fails
    func encrypt(_ plaintext: String) -> String? {
        guard let data = plaintext.data(using: .utf8) else {
            return nil
        }

        return encrypt(data)
    }

    /// Encrypt data
    /// - Parameter data: The data to encrypt
    /// - Returns: Encrypted data as a base64 string, or nil if encryption fails
    func encrypt(_ data: Data) -> String? {
        do {
            // Get the encryption key
            let key = try getOrCreateEncryptionKey()

            // Create a sealed box (this encrypts the data)
            let sealedBox = try AES.GCM.seal(data, using: key)

            // Get the combined data (nonce + ciphertext + tag)
            guard let combined = sealedBox.combined else {
                return nil
            }

            // Return as base64 string for easy storage
            return combined.base64EncodedString()

        } catch {
            print("❌ Encryption failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Decrypt a string
    /// - Parameter encryptedBase64: The encrypted data as a base64 string
    /// - Returns: Decrypted plain text, or nil if decryption fails
    func decrypt(_ encryptedBase64: String) -> String? {
        guard let decryptedData = decryptData(encryptedBase64) else {
            return nil
        }

        return String(data: decryptedData, encoding: .utf8)
    }

    /// Decrypt data
    /// - Parameter encryptedBase64: The encrypted data as a base64 string
    /// - Returns: Decrypted data, or nil if decryption fails
    func decryptData(_ encryptedBase64: String) -> Data? {
        do {
            // Get the encryption key
            let key = try getOrCreateEncryptionKey()

            // Convert from base64 to data
            guard let combined = Data(base64Encoded: encryptedBase64) else {
                return nil
            }

            // Create a sealed box from the combined data
            let sealedBox = try AES.GCM.SealedBox(combined: combined)

            // Decrypt the data
            let decryptedData = try AES.GCM.open(sealedBox, using: key)

            return decryptedData

        } catch {
            print("❌ Decryption failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Private Methods

    /// Get the encryption key from keychain, or create a new one if it doesn't exist
    /// - Returns: The symmetric encryption key
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        let keychain = KeychainManager.shared

        // Try to load existing key
        if let keyData = keychain.getData(forKey: KeychainKey.encryptionKey) {
            return SymmetricKey(data: keyData)
        }

        // No key exists, create a new one
        let newKey = SymmetricKey(size: .bits256)

        // Save it to keychain
        let keyData = newKey.withUnsafeBytes { Data($0) }
        let saved = keychain.save(keyData, forKey: KeychainKey.encryptionKey)

        if !saved {
            throw EncryptionError.failedToSaveKey
        }

        return newKey
    }

    /// Hash data (one-way, cannot be reversed)
    /// Useful for passwords or data integrity checks
    /// - Parameter data: Data to hash
    /// - Returns: SHA256 hash as a hex string
    func hash(_ data: Data) -> String {
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Hash a string
    /// - Parameter string: String to hash
    /// - Returns: SHA256 hash as a hex string
    func hash(_ string: String) -> String? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }
        return hash(data)
    }
}

// MARK: - Errors

enum EncryptionError: Error {
    case failedToSaveKey
    case failedToLoadKey
    case encryptionFailed
    case decryptionFailed
}
