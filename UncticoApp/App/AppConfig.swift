// AppConfig.swift
// Central configuration file for the entire app
// QA Note: All app-wide settings are defined here

import Foundation

/// Main configuration settings for Unctico app
/// Simple names, easy to understand
struct AppConfig {

    // MARK: - App Information
    static let appName = "Unctico"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"

    // MARK: - Security Settings
    static let autoLogoutMinutes = 5
    static let maxLoginAttempts = 3
    static let lockoutDurationSeconds = 60

    // MARK: - Session Settings
    static let sessionTimeoutMinutes = 120  // 2 hours

    // MARK: - Data Storage
    static let enableEncryption = true
    static let enableCloudSync = true
    static let autoBackupEnabled = true
    static let backupFrequencyHours = 24

    // MARK: - Voice Features
    static let enableVoiceInput = true
    static let voiceLanguage = "en-US"

    // MARK: - Reminder Settings
    static let defaultReminderHours = 24  // Remind 24 hours before appointment
    static let enablePushNotifications = true

    // MARK: - Limits
    static let maxPhotosPerClient = 50
    static let maxNotesLength = 10000
    static let maxClientsCount = 10000  // Unlimited for practical purposes
}
