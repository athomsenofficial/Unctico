// DateFormatters.swift
// Reusable date formatters for consistent date formatting across the app

import Foundation

/// Centralized date formatting utilities
/// Use these instead of creating new DateFormatter instances everywhere
enum DateFormatters {

    // MARK: - Static Formatters

    /// Standard date format: "Jan 15, 2024"
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Date with time: "Jan 15, 2024 at 2:30 PM"
    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Time only: "2:30 PM"
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// Full date: "Monday, January 15, 2024"
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()

    /// ISO 8601 format for API calls: "2024-01-15T14:30:00Z"
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    // MARK: - Helper Methods

    /// Format a date for display
    /// - Parameters:
    ///   - date: The date to format
    ///   - style: The format style to use
    /// - Returns: Formatted date string
    static func format(_ date: Date, style: Style = .shortDate) -> String {
        switch style {
        case .shortDate:
            return shortDate.string(from: date)
        case .dateTime:
            return dateTime.string(from: date)
        case .timeOnly:
            return timeOnly.string(from: date)
        case .fullDate:
            return fullDate.string(from: date)
        }
    }

    /// Check if a date is today
    static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    /// Check if a date is within the next 7 days
    static func isThisWeek(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: today) ?? today

        return date >= today && date <= weekFromNow
    }

    /// Get a friendly relative date string (e.g., "Today", "Yesterday", "2 days ago")
    static func relativeString(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let components = calendar.dateComponents([.day], from: date, to: now)
            if let days = components.day {
                if days > 0 {
                    return "\(days) day\(days == 1 ? "" : "s") ago"
                } else {
                    return "In \(-days) day\(days == -1 ? "" : "s")"
                }
            }
        }

        return format(date, style: .shortDate)
    }

    // MARK: - Style Enum

    enum Style {
        case shortDate
        case dateTime
        case timeOnly
        case fullDate
    }
}
