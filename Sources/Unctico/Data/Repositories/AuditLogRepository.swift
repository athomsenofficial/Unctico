import Foundation
import SwiftData

/// Repository for managing HIPAA-compliant audit logs
@MainActor
class AuditLogRepository: ObservableObject {
    private let storageKey = "unctico_audit_logs"
    @Published var logs: [AuditLog] = []

    init() {
        loadLogs()
    }

    // MARK: - Logging Functions

    /// Log an audit event
    func logEvent(
        userId: UUID,
        userName: String,
        action: AuditAction,
        resourceType: ResourceType,
        resourceId: UUID,
        resourceIdentifier: String,
        result: ActionResult = .success,
        details: String? = nil
    ) {
        let log = AuditLog(
            userId: userId,
            userName: userName,
            action: action,
            resourceType: resourceType,
            resourceId: resourceId,
            resourceIdentifier: resourceIdentifier,
            ipAddress: getCurrentIP(),
            deviceInfo: getDeviceInfo(),
            result: result,
            details: details
        )

        logs.insert(log, at: 0)
        saveLogs()
    }

    /// Log a client access event
    func logClientAccess(
        userId: UUID,
        userName: String,
        action: AuditAction,
        clientId: UUID,
        clientName: String,
        result: ActionResult = .success
    ) {
        logEvent(
            userId: userId,
            userName: userName,
            action: action,
            resourceType: .client,
            resourceId: clientId,
            resourceIdentifier: clientName,
            result: result
        )
    }

    /// Log an appointment access event
    func logAppointmentAccess(
        userId: UUID,
        userName: String,
        action: AuditAction,
        appointmentId: UUID,
        appointmentInfo: String,
        result: ActionResult = .success
    ) {
        logEvent(
            userId: userId,
            userName: userName,
            action: action,
            resourceType: .appointment,
            resourceId: appointmentId,
            resourceIdentifier: appointmentInfo,
            result: result
        )
    }

    /// Log a SOAP note access event
    func logSOAPNoteAccess(
        userId: UUID,
        userName: String,
        action: AuditAction,
        noteId: UUID,
        clientName: String,
        result: ActionResult = .success
    ) {
        logEvent(
            userId: userId,
            userName: userName,
            action: action,
            resourceType: .soapNote,
            resourceId: noteId,
            resourceIdentifier: "SOAP Note for \(clientName)",
            result: result
        )
    }

    /// Log a medical history access event
    func logMedicalHistoryAccess(
        userId: UUID,
        userName: String,
        action: AuditAction,
        clientId: UUID,
        clientName: String,
        result: ActionResult = .success
    ) {
        logEvent(
            userId: userId,
            userName: userName,
            action: action,
            resourceType: .medicalHistory,
            resourceId: clientId,
            resourceIdentifier: "Medical History - \(clientName)",
            result: result
        )
    }

    /// Log a payment event
    func logPaymentAccess(
        userId: UUID,
        userName: String,
        action: AuditAction,
        paymentId: UUID,
        paymentInfo: String,
        result: ActionResult = .success
    ) {
        logEvent(
            userId: userId,
            userName: userName,
            action: action,
            resourceType: .payment,
            resourceId: paymentId,
            resourceIdentifier: paymentInfo,
            result: result
        )
    }

    /// Log an insurance claim event
    func logInsuranceClaimAccess(
        userId: UUID,
        userName: String,
        action: AuditAction,
        claimId: UUID,
        claimInfo: String,
        result: ActionResult = .success
    ) {
        logEvent(
            userId: userId,
            userName: userName,
            action: action,
            resourceType: .insuranceClaim,
            resourceId: claimId,
            resourceIdentifier: claimInfo,
            result: result
        )
    }

    /// Log authentication events
    func logAuthentication(
        userId: UUID?,
        userName: String,
        action: AuditAction,
        result: ActionResult
    ) {
        logEvent(
            userId: userId ?? UUID(),
            userName: userName,
            action: action,
            resourceType: .user,
            resourceId: userId ?? UUID(),
            resourceIdentifier: userName,
            result: result,
            details: action == .failedLogin ? "Authentication failed" : nil
        )
    }

    /// Log access denied events
    func logAccessDenied(
        userId: UUID,
        userName: String,
        resourceType: ResourceType,
        resourceId: UUID,
        requiredPermission: Permission
    ) {
        logEvent(
            userId: userId,
            userName: userName,
            action: .accessDenied,
            resourceType: resourceType,
            resourceId: resourceId,
            resourceIdentifier: "Access Denied",
            result: .denied,
            details: "Required permission: \(requiredPermission.description)"
        )
    }

    /// Log data export events (important for HIPAA)
    func logDataExport(
        userId: UUID,
        userName: String,
        exportType: String,
        recordCount: Int,
        result: ActionResult = .success
    ) {
        logEvent(
            userId: userId,
            userName: userName,
            action: .dataExport,
            resourceType: .report,
            resourceId: UUID(),
            resourceIdentifier: exportType,
            result: result,
            details: "Exported \(recordCount) records"
        )
    }

    // MARK: - Query Functions

    /// Get logs for a specific user
    func getLogs(forUser userId: UUID) -> [AuditLog] {
        logs.filter { $0.userId == userId }
    }

    /// Get logs for a specific resource
    func getLogs(forResource resourceId: UUID) -> [AuditLog] {
        logs.filter { $0.resourceId == resourceId }
    }

    /// Get logs by action type
    func getLogs(byAction action: AuditAction) -> [AuditLog] {
        logs.filter { $0.action == action }
    }

    /// Get logs by resource type
    func getLogs(byResourceType resourceType: ResourceType) -> [AuditLog] {
        logs.filter { $0.resourceType == resourceType }
    }

    /// Get logs within a date range
    func getLogs(from startDate: Date, to endDate: Date) -> [AuditLog] {
        logs.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }

    /// Get failed access attempts
    func getFailedAttempts() -> [AuditLog] {
        logs.filter { $0.result == .failure || $0.result == .denied || $0.action == .failedLogin }
    }

    /// Get recent logs (last N entries)
    func getRecentLogs(limit: Int = 50) -> [AuditLog] {
        Array(logs.prefix(limit))
    }

    /// Search logs by resource identifier or details
    func searchLogs(query: String) -> [AuditLog] {
        let lowercaseQuery = query.lowercased()
        return logs.filter { log in
            log.resourceIdentifier.lowercased().contains(lowercaseQuery) ||
            log.userName.lowercased().contains(lowercaseQuery) ||
            (log.details?.lowercased().contains(lowercaseQuery) ?? false)
        }
    }

    /// Get audit statistics
    func getAuditStatistics(for period: DateComponents) -> AuditStatistics {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: period, to: endDate) else {
            return AuditStatistics()
        }

        let periodLogs = getLogs(from: startDate, to: endDate)

        var actionCounts: [AuditAction: Int] = [:]
        var resourceCounts: [ResourceType: Int] = [:]
        var userCounts: [UUID: Int] = [:]

        for log in periodLogs {
            actionCounts[log.action, default: 0] += 1
            resourceCounts[log.resourceType, default: 0] += 1
            userCounts[log.userId, default: 0] += 1
        }

        return AuditStatistics(
            totalEvents: periodLogs.count,
            failedAttempts: periodLogs.filter { $0.result != .success }.count,
            uniqueUsers: userCounts.count,
            actionBreakdown: actionCounts,
            resourceBreakdown: resourceCounts,
            periodStart: startDate,
            periodEnd: endDate
        )
    }

    // MARK: - Compliance Functions

    /// Export audit logs for compliance reporting (HIPAA requirement)
    func exportAuditLogs(from startDate: Date, to endDate: Date) -> String {
        let logsToExport = getLogs(from: startDate, to: endDate)

        var csv = "Timestamp,User,Action,Resource Type,Resource,Result,IP Address,Device,Details\n"

        for log in logsToExport {
            let row = [
                formatDate(log.timestamp),
                log.userName,
                log.action.description,
                log.resourceType.displayName,
                log.resourceIdentifier,
                log.result.rawValue,
                log.ipAddress ?? "N/A",
                log.deviceInfo ?? "N/A",
                log.details ?? ""
            ].map { "\"\($0)\"" }.joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    /// Check if audit retention period is compliant (HIPAA requires 6 years)
    func checkRetentionCompliance() -> (isCompliant: Bool, oldestLog: Date?) {
        guard let oldestLog = logs.last?.timestamp else {
            return (true, nil)
        }

        let sixYearsAgo = Calendar.current.date(byAdding: .year, value: -6, to: Date()) ?? Date()
        return (oldestLog >= sixYearsAgo, oldestLog)
    }

    /// Archive old logs (for retention compliance)
    func archiveOldLogs(olderThan years: Int = 7) -> Int {
        let archiveDate = Calendar.current.date(byAdding: .year, value: -years, to: Date()) ?? Date()
        let logsToKeep = logs.filter { $0.timestamp >= archiveDate }
        let archivedCount = logs.count - logsToKeep.count

        logs = logsToKeep
        saveLogs()

        return archivedCount
    }

    // MARK: - Persistence

    private func loadLogs() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([AuditLog].self, from: data) {
            logs = decoded
        }
    }

    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    // MARK: - Utility Functions

    private func getCurrentIP() -> String {
        // In production, this would get the actual IP address
        // For now, return localhost
        return "127.0.0.1"
    }

    private func getDeviceInfo() -> String {
        #if os(iOS)
        let device = UIDevice.current
        return "\(device.systemName) \(device.systemVersion) - \(device.model)"
        #elseif os(macOS)
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        #else
        return "Unknown Device"
        #endif
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

/// Audit statistics for compliance reporting
struct AuditStatistics {
    let totalEvents: Int
    let failedAttempts: Int
    let uniqueUsers: Int
    let actionBreakdown: [AuditAction: Int]
    let resourceBreakdown: [ResourceType: Int]
    let periodStart: Date
    let periodEnd: Date

    init(
        totalEvents: Int = 0,
        failedAttempts: Int = 0,
        uniqueUsers: Int = 0,
        actionBreakdown: [AuditAction: Int] = [:],
        resourceBreakdown: [ResourceType: Int] = [:],
        periodStart: Date = Date(),
        periodEnd: Date = Date()
    ) {
        self.totalEvents = totalEvents
        self.failedAttempts = failedAttempts
        self.uniqueUsers = uniqueUsers
        self.actionBreakdown = actionBreakdown
        self.resourceBreakdown = resourceBreakdown
        self.periodStart = periodStart
        self.periodEnd = periodEnd
    }
}
