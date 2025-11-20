import Foundation

/// Audit log entry for HIPAA compliance tracking
/// Tracks all access to Protected Health Information (PHI)
struct AuditLog: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let userId: UUID
    let userName: String
    let action: AuditAction
    let resourceType: ResourceType
    let resourceId: UUID
    let resourceIdentifier: String // e.g., client name, appointment ID
    let ipAddress: String?
    let deviceInfo: String?
    let result: ActionResult
    let details: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        userId: UUID,
        userName: String,
        action: AuditAction,
        resourceType: ResourceType,
        resourceId: UUID,
        resourceIdentifier: String,
        ipAddress: String? = nil,
        deviceInfo: String? = nil,
        result: ActionResult = .success,
        details: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.userId = userId
        self.userName = userName
        self.action = action
        self.resourceType = resourceType
        self.resourceId = resourceId
        self.resourceIdentifier = resourceIdentifier
        self.ipAddress = ipAddress
        self.deviceInfo = deviceInfo
        self.result = result
        self.details = details
    }
}

/// Types of actions that can be audited
enum AuditAction: String, Codable, CaseIterable {
    case view = "VIEW"
    case create = "CREATE"
    case update = "UPDATE"
    case delete = "DELETE"
    case export = "EXPORT"
    case print = "PRINT"
    case share = "SHARE"
    case login = "LOGIN"
    case logout = "LOGOUT"
    case failedLogin = "FAILED_LOGIN"
    case accessDenied = "ACCESS_DENIED"
    case dataExport = "DATA_EXPORT"
    case settingsChange = "SETTINGS_CHANGE"
    case bulkOperation = "BULK_OPERATION"

    var description: String {
        switch self {
        case .view: return "Viewed"
        case .create: return "Created"
        case .update: return "Updated"
        case .delete: return "Deleted"
        case .export: return "Exported"
        case .print: return "Printed"
        case .share: return "Shared"
        case .login: return "Logged in"
        case .logout: return "Logged out"
        case .failedLogin: return "Failed login attempt"
        case .accessDenied: return "Access denied"
        case .dataExport: return "Exported data"
        case .settingsChange: return "Changed settings"
        case .bulkOperation: return "Bulk operation"
        }
    }
}

/// Types of resources that contain PHI
enum ResourceType: String, Codable, CaseIterable {
    case client = "CLIENT"
    case appointment = "APPOINTMENT"
    case soapNote = "SOAP_NOTE"
    case medicalHistory = "MEDICAL_HISTORY"
    case insuranceClaim = "INSURANCE_CLAIM"
    case payment = "PAYMENT"
    case consentForm = "CONSENT_FORM"
    case intakeForm = "INTAKE_FORM"
    case document = "DOCUMENT"
    case report = "REPORT"
    case settings = "SETTINGS"
    case user = "USER"

    var displayName: String {
        switch self {
        case .client: return "Client Record"
        case .appointment: return "Appointment"
        case .soapNote: return "SOAP Note"
        case .medicalHistory: return "Medical History"
        case .insuranceClaim: return "Insurance Claim"
        case .payment: return "Payment"
        case .consentForm: return "Consent Form"
        case .intakeForm: return "Intake Form"
        case .document: return "Document"
        case .report: return "Report"
        case .settings: return "Settings"
        case .user: return "User"
        }
    }
}

/// Result of an audited action
enum ActionResult: String, Codable {
    case success = "SUCCESS"
    case failure = "FAILURE"
    case denied = "DENIED"
    case error = "ERROR"
}

/// HIPAA-compliant access levels for users
enum AccessLevel: String, Codable, CaseIterable {
    case admin = "ADMIN"
    case therapist = "THERAPIST"
    case receptionist = "RECEPTIONIST"
    case billing = "BILLING"
    case readOnly = "READ_ONLY"

    var permissions: Set<Permission> {
        switch self {
        case .admin:
            return Set(Permission.allCases)
        case .therapist:
            return [.viewClients, .editClients, .viewAppointments, .editAppointments,
                    .viewSOAPNotes, .editSOAPNotes, .viewMedicalHistory, .viewPayments]
        case .receptionist:
            return [.viewClients, .editClients, .viewAppointments, .editAppointments,
                    .viewPayments, .processPayments]
        case .billing:
            return [.viewClients, .viewAppointments, .viewPayments, .processPayments,
                    .viewInsuranceClaims, .editInsuranceClaims, .viewReports]
        case .readOnly:
            return [.viewClients, .viewAppointments, .viewReports]
        }
    }

    var description: String {
        switch self {
        case .admin: return "Administrator - Full Access"
        case .therapist: return "Therapist - Clinical Access"
        case .receptionist: return "Receptionist - Scheduling & Billing"
        case .billing: return "Billing - Financial Only"
        case .readOnly: return "Read Only - View Access"
        }
    }
}

/// Granular permissions for access control
enum Permission: String, Codable, CaseIterable {
    // Client permissions
    case viewClients = "VIEW_CLIENTS"
    case editClients = "EDIT_CLIENTS"
    case deleteClients = "DELETE_CLIENTS"
    case exportClients = "EXPORT_CLIENTS"

    // Appointment permissions
    case viewAppointments = "VIEW_APPOINTMENTS"
    case editAppointments = "EDIT_APPOINTMENTS"
    case deleteAppointments = "DELETE_APPOINTMENTS"

    // Clinical documentation permissions
    case viewSOAPNotes = "VIEW_SOAP_NOTES"
    case editSOAPNotes = "EDIT_SOAP_NOTES"
    case deleteSOAPNotes = "DELETE_SOAP_NOTES"

    // Medical history permissions
    case viewMedicalHistory = "VIEW_MEDICAL_HISTORY"
    case editMedicalHistory = "EDIT_MEDICAL_HISTORY"

    // Payment permissions
    case viewPayments = "VIEW_PAYMENTS"
    case processPayments = "PROCESS_PAYMENTS"
    case refundPayments = "REFUND_PAYMENTS"

    // Insurance permissions
    case viewInsuranceClaims = "VIEW_INSURANCE_CLAIMS"
    case editInsuranceClaims = "EDIT_INSURANCE_CLAIMS"
    case submitInsuranceClaims = "SUBMIT_INSURANCE_CLAIMS"

    // Reporting permissions
    case viewReports = "VIEW_REPORTS"
    case exportReports = "EXPORT_REPORTS"

    // Administrative permissions
    case manageUsers = "MANAGE_USERS"
    case manageSettings = "MANAGE_SETTINGS"
    case viewAuditLogs = "VIEW_AUDIT_LOGS"
    case manageCompliance = "MANAGE_COMPLIANCE"

    var description: String {
        rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

/// User access control information
struct UserAccessControl: Codable {
    let userId: UUID
    var accessLevel: AccessLevel
    var customPermissions: Set<Permission>
    var isActive: Bool
    var lastAccessReview: Date?
    var nextAccessReview: Date?

    /// Get all effective permissions (access level + custom)
    var effectivePermissions: Set<Permission> {
        accessLevel.permissions.union(customPermissions)
    }

    /// Check if user has a specific permission
    func hasPermission(_ permission: Permission) -> Bool {
        effectivePermissions.contains(permission)
    }

    init(
        userId: UUID,
        accessLevel: AccessLevel,
        customPermissions: Set<Permission> = [],
        isActive: Bool = true,
        lastAccessReview: Date? = nil,
        nextAccessReview: Date? = nil
    ) {
        self.userId = userId
        self.accessLevel = accessLevel
        self.customPermissions = customPermissions
        self.isActive = isActive
        self.lastAccessReview = lastAccessReview
        self.nextAccessReview = nextAccessReview
    }
}
