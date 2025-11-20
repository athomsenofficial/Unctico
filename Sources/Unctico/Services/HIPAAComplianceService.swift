import Foundation
import CryptoKit

/// Service for managing HIPAA compliance features
@MainActor
class HIPAAComplianceService: ObservableObject {
    private let auditLogRepository: AuditLogRepository
    @Published var accessControls: [UUID: UserAccessControl] = [:]
    @Published var sessionTimeout: TimeInterval = 900 // 15 minutes default
    @Published var lastActivity: Date = Date()
    @Published var isSessionActive: Bool = true

    private let storageKey = "unctico_access_controls"

    init(auditLogRepository: AuditLogRepository) {
        self.auditLogRepository = auditLogRepository
        loadAccessControls()
        startSessionMonitoring()
    }

    // MARK: - Access Control Management

    /// Set access level for a user
    func setAccessLevel(for userId: UUID, accessLevel: AccessLevel) {
        if var control = accessControls[userId] {
            control.accessLevel = accessLevel
            accessControls[userId] = control
        } else {
            accessControls[userId] = UserAccessControl(
                userId: userId,
                accessLevel: accessLevel
            )
        }
        saveAccessControls()
    }

    /// Grant custom permission to a user
    func grantPermission(_ permission: Permission, to userId: UUID) {
        if var control = accessControls[userId] {
            control.customPermissions.insert(permission)
            accessControls[userId] = control
        } else {
            accessControls[userId] = UserAccessControl(
                userId: userId,
                accessLevel: .readOnly,
                customPermissions: [permission]
            )
        }
        saveAccessControls()
    }

    /// Revoke custom permission from a user
    func revokePermission(_ permission: Permission, from userId: UUID) {
        guard var control = accessControls[userId] else { return }
        control.customPermissions.remove(permission)
        accessControls[userId] = control
        saveAccessControls()
    }

    /// Check if user has permission
    func hasPermission(_ permission: Permission, userId: UUID) -> Bool {
        guard let control = accessControls[userId], control.isActive else {
            return false
        }
        return control.hasPermission(permission)
    }

    /// Check access and log the attempt
    func checkAccess(
        permission: Permission,
        userId: UUID,
        userName: String,
        resourceType: ResourceType,
        resourceId: UUID,
        resourceIdentifier: String
    ) -> Bool {
        let hasAccess = hasPermission(permission, userId: userId)

        if hasAccess {
            updateLastActivity()
        } else {
            auditLogRepository.logAccessDenied(
                userId: userId,
                userName: userName,
                resourceType: resourceType,
                resourceId: resourceId,
                requiredPermission: permission
            )
        }

        return hasAccess
    }

    /// Deactivate user access
    func deactivateUser(_ userId: UUID) {
        guard var control = accessControls[userId] else { return }
        control.isActive = false
        accessControls[userId] = control
        saveAccessControls()
    }

    /// Reactivate user access
    func reactivateUser(_ userId: UUID) {
        guard var control = accessControls[userId] else { return }
        control.isActive = true
        accessControls[userId] = control
        saveAccessControls()
    }

    /// Schedule access review
    func scheduleAccessReview(for userId: UUID, reviewDate: Date) {
        guard var control = accessControls[userId] else { return }
        control.nextAccessReview = reviewDate
        accessControls[userId] = control
        saveAccessControls()
    }

    /// Mark access review as completed
    func completeAccessReview(for userId: UUID) {
        guard var control = accessControls[userId] else { return }
        control.lastAccessReview = Date()
        // Schedule next review in 6 months (HIPAA recommended)
        control.nextAccessReview = Calendar.current.date(byAdding: .month, value: 6, to: Date())
        accessControls[userId] = control
        saveAccessControls()
    }

    /// Get users needing access review
    func getUsersNeedingAccessReview() -> [UserAccessControl] {
        let today = Date()
        return accessControls.values.filter { control in
            if let reviewDate = control.nextAccessReview {
                return reviewDate <= today
            }
            // If no review date set, consider it overdue
            return control.lastAccessReview == nil
        }
    }

    // MARK: - Session Management (HIPAA requires automatic logoff)

    private func startSessionMonitoring() {
        // Monitor session timeout
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkSessionTimeout()
            }
        }
    }

    func updateLastActivity() {
        lastActivity = Date()
        isSessionActive = true
    }

    private func checkSessionTimeout() {
        let timeSinceLastActivity = Date().timeIntervalSince(lastActivity)
        if timeSinceLastActivity >= sessionTimeout {
            isSessionActive = false
        }
    }

    func endSession(userId: UUID, userName: String) {
        isSessionActive = false
        auditLogRepository.logAuthentication(
            userId: userId,
            userName: userName,
            action: .logout,
            result: .success
        )
    }

    // MARK: - Data Encryption (HIPAA requirement)

    /// Encrypt sensitive data
    func encryptData(_ data: String) throws -> Data {
        guard let dataToEncrypt = data.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }

        // Generate a symmetric key (in production, this should be stored securely in Keychain)
        let key = SymmetricKey(size: .bits256)

        // Encrypt the data
        let sealedBox = try AES.GCM.seal(dataToEncrypt, using: key)

        guard let encryptedData = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }

        return encryptedData
    }

    /// Decrypt sensitive data
    func decryptData(_ encryptedData: Data) throws -> String {
        // In production, retrieve the key from Keychain
        let key = SymmetricKey(size: .bits256)

        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.invalidData
        }

        return decryptedString
    }

    /// Hash sensitive data for secure comparison (e.g., passwords)
    func hashData(_ data: String) -> String {
        let inputData = Data(data.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Minimum Necessary Access (HIPAA principle)

    /// Check if access is minimum necessary
    func isMinimumNecessaryAccess(
        requestedFields: Set<String>,
        userRole: AccessLevel,
        purpose: String
    ) -> Bool {
        // Define minimum necessary fields by role and purpose
        let minimumFields: Set<String>

        switch (userRole, purpose) {
        case (.receptionist, "scheduling"):
            minimumFields = ["name", "phone", "email", "appointmentHistory"]
        case (.billing, "payment"):
            minimumFields = ["name", "insuranceInfo", "paymentHistory"]
        case (.therapist, "treatment"):
            minimumFields = ["name", "medicalHistory", "soapNotes", "treatmentPlan"]
        default:
            return true // Admin has full access
        }

        // Check if requested fields exceed minimum necessary
        return requestedFields.isSubset(of: minimumFields)
    }

    // MARK: - Privacy & Security Settings

    /// Get encryption status for data at rest
    func getEncryptionStatus() -> EncryptionStatus {
        // Check if device/keychain encryption is enabled
        // This is a simplified check - in production, verify actual encryption status
        return EncryptionStatus(
            dataAtRest: true, // iOS/macOS encrypts app data by default
            dataInTransit: true, // HTTPS/TLS
            databaseEncrypted: false, // Would need to implement database encryption
            keychain: true // iOS/macOS keychain is encrypted
        )
    }

    /// Generate privacy notice delivery record
    func recordPrivacyNoticeDelivery(
        clientId: UUID,
        clientName: String,
        deliveryMethod: String,
        acknowledgmentSignature: Data?
    ) {
        auditLogRepository.logEvent(
            userId: UUID(), // System event
            userName: "System",
            action: .create,
            resourceType: .consentForm,
            resourceId: clientId,
            resourceIdentifier: "Privacy Notice - \(clientName)",
            result: .success,
            details: "Delivered via \(deliveryMethod)"
        )
    }

    /// Check for potential security breaches
    func checkForSecurityConcerns() -> [SecurityConcern] {
        var concerns: [SecurityConcern] = []

        // Check for excessive failed login attempts
        let failedAttempts = auditLogRepository.getFailedAttempts()
        let recentFailures = failedAttempts.filter {
            Date().timeIntervalSince($0.timestamp) < 3600 // Last hour
        }

        if recentFailures.count > 5 {
            concerns.append(SecurityConcern(
                severity: .high,
                type: .excessiveFailedLogins,
                description: "\(recentFailures.count) failed login attempts in the last hour",
                timestamp: Date()
            ))
        }

        // Check for users needing access review
        let needingReview = getUsersNeedingAccessReview()
        if !needingReview.isEmpty {
            concerns.append(SecurityConcern(
                severity: .medium,
                type: .accessReviewOverdue,
                description: "\(needingReview.count) users need access review",
                timestamp: Date()
            ))
        }

        // Check audit log retention
        let retention = auditLogRepository.checkRetentionCompliance()
        if !retention.isCompliant {
            concerns.append(SecurityConcern(
                severity: .high,
                type: .auditRetentionIssue,
                description: "Audit logs do not meet 6-year retention requirement",
                timestamp: Date()
            ))
        }

        return concerns
    }

    // MARK: - Compliance Reporting

    /// Generate HIPAA compliance report
    func generateComplianceReport(for period: DateComponents) -> ComplianceReport {
        let stats = auditLogRepository.getAuditStatistics(for: period)
        let securityConcerns = checkForSecurityConcerns()
        let encryptionStatus = getEncryptionStatus()

        return ComplianceReport(
            reportDate: Date(),
            periodStart: stats.periodStart,
            periodEnd: stats.periodEnd,
            auditStatistics: stats,
            securityConcerns: securityConcerns,
            encryptionStatus: encryptionStatus,
            activeUsers: accessControls.values.filter { $0.isActive }.count,
            usersNeedingReview: getUsersNeedingAccessReview().count
        )
    }

    // MARK: - Persistence

    private func loadAccessControls() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([UUID: UserAccessControl].self, from: data) {
            accessControls = decoded
        }
    }

    private func saveAccessControls() {
        if let encoded = try? JSONEncoder().encode(accessControls) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}

// MARK: - Supporting Types

enum EncryptionError: Error {
    case invalidData
    case encryptionFailed
    case decryptionFailed
}

struct EncryptionStatus {
    let dataAtRest: Bool
    let dataInTransit: Bool
    let databaseEncrypted: Bool
    let keychain: Bool

    var isFullyEncrypted: Bool {
        dataAtRest && dataInTransit && databaseEncrypted && keychain
    }
}

struct SecurityConcern: Identifiable {
    let id = UUID()
    let severity: Severity
    let type: ConcernType
    let description: String
    let timestamp: Date

    enum Severity {
        case low, medium, high, critical
    }

    enum ConcernType {
        case excessiveFailedLogins
        case accessReviewOverdue
        case auditRetentionIssue
        case unauthorizedAccess
        case dataBreachSuspected
        case encryptionDisabled
    }
}

struct ComplianceReport {
    let reportDate: Date
    let periodStart: Date
    let periodEnd: Date
    let auditStatistics: AuditStatistics
    let securityConcerns: [SecurityConcern]
    let encryptionStatus: EncryptionStatus
    let activeUsers: Int
    let usersNeedingReview: Int

    var isCompliant: Bool {
        securityConcerns.filter { $0.severity == .high || $0.severity == .critical }.isEmpty &&
        encryptionStatus.isFullyEncrypted &&
        usersNeedingReview == 0
    }
}
