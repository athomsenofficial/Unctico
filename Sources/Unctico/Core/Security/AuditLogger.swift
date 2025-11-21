//
//  AuditLogger.swift
//  Unctico
//
//  HIPAA-compliant audit logging
//  Ported from MassageTherapySOAP project
//

import Foundation

final class AuditLogger {
    static let shared = AuditLogger()

    private var auditLog: [AuditEntry] = []
    private let logFileURL: URL

    private init() {
        // Set up audit log file location
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        logFileURL = documentsPath.appendingPathComponent("audit_log.json")
        loadAuditLog()
    }

    // MARK: - Public Methods

    func log(event: AuditEventType, details: String, userId: UUID? = nil) {
        let entry = AuditEntry(
            timestamp: Date(),
            userId: userId ?? UUID(), // Use current user ID in production
            event: event,
            details: SecurityManager.shared.sanitizeForLog(details),
            ipAddress: getDeviceIP()
        )

        auditLog.append(entry)
        saveAuditLog()
    }

    func getAuditEntries(for userId: UUID? = nil, since: Date? = nil) -> [AuditEntry] {
        var filtered = auditLog

        if let userId = userId {
            filtered = filtered.filter { $0.userId == userId }
        }

        if let since = since {
            filtered = filtered.filter { $0.timestamp >= since }
        }

        return filtered.sorted { $0.timestamp > $1.timestamp }
    }

    func exportAuditLog() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return try? encoder.encode(auditLog)
    }

    // MARK: - Private Methods

    private func loadAuditLog() {
        guard FileManager.default.fileExists(atPath: logFileURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: logFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            auditLog = try decoder.decode([AuditEntry].self, from: data)
        } catch {
            print("Failed to load audit log: \(error)")
        }
    }

    private func saveAuditLog() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(auditLog)
            try data.write(to: logFileURL, options: .atomic)
        } catch {
            print("Failed to save audit log: \(error)")
        }
    }

    private func getDeviceIP() -> String? {
        // Simplified IP detection - in production, use proper network info
        return "local"
    }
}

// MARK: - Audit Entry

struct AuditEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let userId: UUID
    let event: AuditEventType
    let details: String
    let ipAddress: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        userId: UUID,
        event: AuditEventType,
        details: String,
        ipAddress: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.userId = userId
        self.event = event
        self.details = details
        self.ipAddress = ipAddress
    }
}

// MARK: - Audit Event Types

enum AuditEventType: String, Codable {
    // Authentication
    case login
    case logout
    case failedLogin
    case passwordChange

    // Data Access
    case dataViewed
    case dataCreated
    case dataModified
    case dataDeleted
    case dataExported

    // SOAP Notes
    case soapNoteCreated
    case soapNoteViewed
    case soapNoteModified
    case soapNoteSigned
    case soapNoteDeleted

    // Client Records
    case clientCreated
    case clientViewed
    case clientModified
    case clientDeleted

    // Payments & Financial
    case paymentProcessed
    case paymentRefunded
    case invoiceGenerated
    case invoiceViewed

    // Insurance
    case claimSubmitted
    case claimViewed
    case claimModified

    // System
    case userAction
    case systemError
    case securityEvent
    case configurationChanged

    var displayName: String {
        switch self {
        case .login: return "User Login"
        case .logout: return "User Logout"
        case .failedLogin: return "Failed Login Attempt"
        case .passwordChange: return "Password Changed"
        case .dataViewed: return "Data Viewed"
        case .dataCreated: return "Data Created"
        case .dataModified: return "Data Modified"
        case .dataDeleted: return "Data Deleted"
        case .dataExported: return "Data Exported"
        case .soapNoteCreated: return "SOAP Note Created"
        case .soapNoteViewed: return "SOAP Note Viewed"
        case .soapNoteModified: return "SOAP Note Modified"
        case .soapNoteSigned: return "SOAP Note Signed"
        case .soapNoteDeleted: return "SOAP Note Deleted"
        case .clientCreated: return "Client Created"
        case .clientViewed: return "Client Viewed"
        case .clientModified: return "Client Modified"
        case .clientDeleted: return "Client Deleted"
        case .paymentProcessed: return "Payment Processed"
        case .paymentRefunded: return "Payment Refunded"
        case .invoiceGenerated: return "Invoice Generated"
        case .invoiceViewed: return "Invoice Viewed"
        case .claimSubmitted: return "Insurance Claim Submitted"
        case .claimViewed: return "Insurance Claim Viewed"
        case .claimModified: return "Insurance Claim Modified"
        case .userAction: return "User Action"
        case .systemError: return "System Error"
        case .securityEvent: return "Security Event"
        case .configurationChanged: return "Configuration Changed"
        }
    }
}
