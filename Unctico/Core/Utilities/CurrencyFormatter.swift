// CurrencyFormatter.swift
// Reusable currency formatting utilities

import Foundation

/// Centralized currency formatting
/// Use this for consistent money display across the app
enum CurrencyFormatter {

    // MARK: - Static Formatter

    /// Standard currency formatter (US Dollar)
    static let standard: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    // MARK: - Helper Methods

    /// Format a decimal amount as currency
    /// - Parameter amount: The amount to format
    /// - Returns: Formatted currency string (e.g., "$123.45")
    static func format(_ amount: Decimal) -> String {
        return standard.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }

    /// Format a double amount as currency
    /// - Parameter amount: The amount to format
    /// - Returns: Formatted currency string
    static func format(_ amount: Double) -> String {
        return standard.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    /// Parse a currency string to decimal
    /// - Parameter string: The currency string to parse (e.g., "$123.45")
    /// - Returns: Decimal value or nil if parsing fails
    static func parse(_ string: String) -> Decimal? {
        // Remove currency symbols and whitespace
        let cleaned = string.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)

        return Decimal(string: cleaned)
    }
}
