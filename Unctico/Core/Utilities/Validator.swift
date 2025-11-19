// Validator.swift
// Input validation utilities for forms

import Foundation

/// Validation utilities for user input
enum Validator {

    // MARK: - Email Validation

    /// Validate an email address
    /// - Parameter email: The email to validate
    /// - Returns: True if valid, false otherwise
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    // MARK: - Phone Validation

    /// Validate a US phone number
    /// - Parameter phone: The phone number to validate
    /// - Returns: True if valid, false otherwise
    static func isValidPhoneNumber(_ phone: String) -> Bool {
        // Remove all non-numeric characters
        let digits = phone.filter { $0.isNumber }

        // US phone numbers should have 10 digits
        return digits.count == 10
    }

    /// Format a phone number for display
    /// - Parameter phone: Raw phone number
    /// - Returns: Formatted phone number (e.g., "(123) 456-7890")
    static func formatPhoneNumber(_ phone: String) -> String {
        let digits = phone.filter { $0.isNumber }

        guard digits.count == 10 else {
            return phone
        }

        let areaCode = String(digits.prefix(3))
        let prefix = String(digits.dropFirst(3).prefix(3))
        let suffix = String(digits.suffix(4))

        return "(\(areaCode)) \(prefix)-\(suffix)"
    }

    // MARK: - Password Validation

    /// Validate a password strength
    /// - Parameter password: The password to validate
    /// - Returns: ValidationResult with strength and message
    static func validatePassword(_ password: String) -> ValidationResult {
        if password.count < 8 {
            return ValidationResult(isValid: false, message: "Password must be at least 8 characters")
        }

        let hasUppercase = password.contains(where: { $0.isUppercase })
        let hasLowercase = password.contains(where: { $0.isLowercase })
        let hasNumber = password.contains(where: { $0.isNumber })

        if !hasUppercase || !hasLowercase || !hasNumber {
            return ValidationResult(
                isValid: false,
                message: "Password must contain uppercase, lowercase, and number"
            )
        }

        return ValidationResult(isValid: true, message: "Strong password")
    }

    // MARK: - Name Validation

    /// Validate a person's name
    /// - Parameter name: The name to validate
    /// - Returns: True if valid, false otherwise
    static func isValidName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2
    }

    // MARK: - License Number Validation

    /// Validate a massage therapy license number
    /// - Parameter license: The license number to validate
    /// - Returns: True if valid format, false otherwise
    static func isValidLicenseNumber(_ license: String) -> Bool {
        let trimmed = license.trimmingCharacters(in: .whitespacesAndNewlines)
        // Most license numbers are alphanumeric and 5-20 characters
        return trimmed.count >= 5 && trimmed.count <= 20
    }
}

// MARK: - Validation Result

/// Result of a validation operation
struct ValidationResult {
    let isValid: Bool
    let message: String
}
