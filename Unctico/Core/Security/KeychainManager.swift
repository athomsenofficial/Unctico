// KeychainManager.swift
// Securely stores sensitive data like passwords and tokens using iOS Keychain

import Foundation
import Security

/// Manages secure storage of sensitive data in iOS Keychain
/// Use this for passwords, tokens, and other secrets - NEVER UserDefaults!
class KeychainManager {

    // MARK: - Singleton

    /// Shared instance of KeychainManager (use this everywhere)
    static let shared = KeychainManager()

    /// Private initializer to enforce singleton pattern
    private init() {}

    // MARK: - Public Methods

    /// Save a string value securely in the keychain
    /// - Parameters:
    ///   - value: The string to save (e.g., password, token)
    ///   - key: The key to identify this value (e.g., "userPassword")
    /// - Returns: True if save was successful, false otherwise
    func save(_ value: String, forKey key: String) -> Bool {
        // Convert string to data
        guard let data = value.data(using: .utf8) else {
            return false
        }

        return save(data, forKey: key)
    }

    /// Save data securely in the keychain
    /// - Parameters:
    ///   - data: The data to save
    ///   - key: The key to identify this data
    /// - Returns: True if save was successful, false otherwise
    func save(_ data: Data, forKey key: String) -> Bool {
        // First, delete any existing item with this key
        delete(forKey: key)

        // Create the query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Try to add the item
        let status = SecItemAdd(query as CFDictionary, nil)

        return status == errSecSuccess
    }

    /// Retrieve a string value from the keychain
    /// - Parameter key: The key that identifies the value
    /// - Returns: The stored string, or nil if not found
    func getString(forKey key: String) -> String? {
        guard let data = getData(forKey: key) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    /// Retrieve data from the keychain
    /// - Parameter key: The key that identifies the data
    /// - Returns: The stored data, or nil if not found
    func getData(forKey key: String) -> Data? {
        // Create the search query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        // Try to find the item
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        // Return the data if found
        if status == errSecSuccess {
            return result as? Data
        }

        return nil
    }

    /// Delete a value from the keychain
    /// - Parameter key: The key that identifies the value to delete
    /// - Returns: True if deletion was successful, false otherwise
    @discardableResult
    func delete(forKey key: String) -> Bool {
        // Create the delete query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        // Try to delete the item
        let status = SecItemDelete(query as CFDictionary)

        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Delete all values from the keychain (use with caution!)
    /// - Returns: True if all items were deleted successfully
    func deleteAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]

        let status = SecItemDelete(query as CFDictionary)

        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - Keychain Keys

/// Standard keys used for keychain storage
/// Using an enum prevents typos and makes it clear what's stored
enum KeychainKey {
    static let userPassword = "com.unctico.userPassword"
    static let authToken = "com.unctico.authToken"
    static let refreshToken = "com.unctico.refreshToken"
    static let encryptionKey = "com.unctico.encryptionKey"
}
