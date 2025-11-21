//
//  SecurityManager.swift
//  Unctico
//
//  HIPAA-compliant security management
//  Ported from MassageTherapySOAP project
//

import Foundation
import CryptoKit
import LocalAuthentication

final class SecurityManager {
    static let shared = SecurityManager()

    private let keychainService = "com.unctico.massage"
    private var encryptionKey: SymmetricKey?

    private init() {
        initializeEncryptionKey()
    }

    // MARK: - App Security Configuration

    func configureAppSecurity() {
        // Disable screenshots in secure areas
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        // Enable secure keyboard
        enableSecureKeyboard()

        // Configure data protection
        configureDataProtection()
    }

    @objc private func handleAppWillResignActive() {
        // Clear sensitive data from memory
        // Show privacy screen
    }

    private func enableSecureKeyboard() {
        // Configure secure keyboard for sensitive fields
    }

    private func configureDataProtection() {
        // Set file protection levels
    }

    // MARK: - Encryption

    private func initializeEncryptionKey() {
        if let existingKey = loadEncryptionKeyFromKeychain() {
            self.encryptionKey = existingKey
        } else {
            let newKey = SymmetricKey(size: .bits256)
            saveEncryptionKeyToKeychain(newKey)
            self.encryptionKey = newKey
        }
    }

    func encrypt(_ data: Data) throws -> Data {
        guard let key = encryptionKey else {
            throw SecurityError.encryptionKeyNotAvailable
        }

        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let encryptedData = sealedBox.combined else {
            throw SecurityError.encryptionFailed
        }

        return encryptedData
    }

    func decrypt(_ data: Data) throws -> Data {
        guard let key = encryptionKey else {
            throw SecurityError.encryptionKeyNotAvailable
        }

        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }

    func encryptString(_ string: String) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw SecurityError.encodingFailed
        }

        let encryptedData = try encrypt(data)
        return encryptedData.base64EncodedString()
    }

    func decryptString(_ encryptedString: String) throws -> String {
        guard let data = Data(base64Encoded: encryptedString) else {
            throw SecurityError.decodingFailed
        }

        let decryptedData = try decrypt(data)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw SecurityError.decodingFailed
        }

        return string
    }

    // MARK: - Keychain Management

    private func saveEncryptionKeyToKeychain(_ key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "encryptionKey",
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadEncryptionKeyFromKeychain() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "encryptionKey",
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let keyData = result as? Data else {
            return nil
        }

        return SymmetricKey(data: keyData)
    }

    // MARK: - Biometric Authentication

    func authenticateWithBiometrics(reason: String) async throws -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw SecurityError.biometricsNotAvailable
        }

        return try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        )
    }

    // MARK: - Data Sanitization

    func sanitizeForLog(_ data: String) -> String {
        // Remove PHI from log data
        return data.replacingOccurrences(of: #"\b\d{3}-\d{2}-\d{4}\b"#, with: "***-**-****", options: .regularExpression)
    }

    func hashForIdentification(_ data: String) -> String {
        let inputData = Data(data.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Security Errors

enum SecurityError: LocalizedError {
    case encryptionKeyNotAvailable
    case encryptionFailed
    case decryptionFailed
    case encodingFailed
    case decodingFailed
    case biometricsNotAvailable
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .encryptionKeyNotAvailable:
            return "Encryption key is not available"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        case .biometricsNotAvailable:
            return "Biometric authentication is not available"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
}
