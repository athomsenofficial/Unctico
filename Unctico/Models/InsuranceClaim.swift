import Foundation

// MARK: - Insurance Claim Models

struct InsuranceClaim: Identifiable, Codable {
    let id: UUID
    var claimNumber: String
    var clientId: UUID
    var insuranceProviderId: UUID
    var appointmentIds: [UUID]
    var dateOfService: Date
    var dateSubmitted: Date?
    var status: ClaimStatus
    var totalBilled: Double
    var allowedAmount: Double?
    var paidAmount: Double?
    var patientResponsibility: Double?
    var adjustments: [ClaimAdjustment]
    var denialReason: String?
    var diagnosisCodes: [String]
    var procedureCodes: [ProcedureCode]
    var modifiers: [String]
    var placeOfService: String
    var authorizationNumber: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        claimNumber: String = "",
        clientId: UUID,
        insuranceProviderId: UUID,
        appointmentIds: [UUID],
        dateOfService: Date,
        dateSubmitted: Date? = nil,
        status: ClaimStatus = .draft,
        totalBilled: Double,
        allowedAmount: Double? = nil,
        paidAmount: Double? = nil,
        patientResponsibility: Double? = nil,
        adjustments: [ClaimAdjustment] = [],
        denialReason: String? = nil,
        diagnosisCodes: [String] = [],
        procedureCodes: [ProcedureCode] = [],
        modifiers: [String] = [],
        placeOfService: String = "11", // Office
        authorizationNumber: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.claimNumber = claimNumber.isEmpty ? "CLM-\(Int.random(in: 10000...99999))" : claimNumber
        self.clientId = clientId
        self.insuranceProviderId = insuranceProviderId
        self.appointmentIds = appointmentIds
        self.dateOfService = dateOfService
        self.dateSubmitted = dateSubmitted
        self.status = status
        self.totalBilled = totalBilled
        self.allowedAmount = allowedAmount
        self.paidAmount = paidAmount
        self.patientResponsibility = patientResponsibility
        self.adjustments = adjustments
        self.denialReason = denialReason
        self.diagnosisCodes = diagnosisCodes
        self.procedureCodes = procedureCodes
        self.modifiers = modifiers
        self.placeOfService = placeOfService
        self.authorizationNumber = authorizationNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var outstandingBalance: Double {
        totalBilled - (paidAmount ?? 0) - (patientResponsibility ?? 0)
    }
}

enum ClaimStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case ready = "Ready to Submit"
    case submitted = "Submitted"
    case inReview = "In Review"
    case approved = "Approved"
    case partiallyPaid = "Partially Paid"
    case paid = "Paid"
    case denied = "Denied"
    case appealed = "Appealed"
    case resubmitted = "Resubmitted"
}

struct ProcedureCode: Identifiable, Codable {
    let id: UUID
    var code: String
    var description: String
    var units: Int
    var chargeAmount: Double
    var modifiers: [String]

    init(
        id: UUID = UUID(),
        code: String,
        description: String,
        units: Int = 1,
        chargeAmount: Double,
        modifiers: [String] = []
    ) {
        self.id = id
        self.code = code
        self.description = description
        self.units = units
        self.chargeAmount = chargeAmount
        self.modifiers = modifiers
    }
}

struct ClaimAdjustment: Identifiable, Codable {
    let id: UUID
    var adjustmentCode: String
    var adjustmentAmount: Double
    var adjustmentReason: String
    var date: Date

    init(
        id: UUID = UUID(),
        adjustmentCode: String,
        adjustmentAmount: Double,
        adjustmentReason: String,
        date: Date = Date()
    ) {
        self.id = id
        self.adjustmentCode = adjustmentCode
        self.adjustmentAmount = adjustmentAmount
        self.adjustmentReason = adjustmentReason
        self.date = date
    }
}

// MARK: - Insurance Provider

struct InsuranceProvider: Identifiable, Codable {
    let id: UUID
    var name: String
    var payerId: String
    var phone: String?
    var claimsAddress: String?
    var website: String?
    var electronicPayerId: String?
    var notes: String?
    var isPreferred: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        payerId: String,
        phone: String? = nil,
        claimsAddress: String? = nil,
        website: String? = nil,
        electronicPayerId: String? = nil,
        notes: String? = nil,
        isPreferred: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.payerId = payerId
        self.phone = phone
        self.claimsAddress = claimsAddress
        self.website = website
        self.electronicPayerId = electronicPayerId
        self.notes = notes
        self.isPreferred = isPreferred
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Client Insurance Info

struct ClientInsurance: Codable {
    var primaryInsurance: InsurancePolicy?
    var secondaryInsurance: InsurancePolicy?
    var verificationDate: Date?
    var verificationStatus: VerificationStatus?
    var deductible: Double?
    var deductibleMet: Double?
    var copay: Double?
    var coinsurance: Double?
    var outOfPocketMax: Double?
    var outOfPocketMet: Double?
    var coverageNotes: String?

    enum VerificationStatus: String, Codable {
        case active = "Active"
        case inactive = "Inactive"
        case pending = "Pending Verification"
        case expired = "Expired"
    }
}

struct InsurancePolicy: Codable {
    var insuranceProviderId: UUID
    var policyNumber: String
    var groupNumber: String?
    var subscriberName: String?
    var subscriberRelationship: SubscriberRelationship
    var subscriberDOB: Date?
    var effectiveDate: Date
    var terminationDate: Date?

    enum SubscriberRelationship: String, Codable, CaseIterable {
        case self_ = "Self"
        case spouse = "Spouse"
        case child = "Child"
        case other = "Other"
    }
}

// MARK: - Common CPT Codes for Massage Therapy

struct MassageCPTCodes {
    static let codes: [String: String] = [
        "97124": "Massage Therapy (15 minutes)",
        "97140": "Manual Therapy Techniques (15 minutes)",
        "97112": "Neuromuscular Reeducation (15 minutes)",
        "97110": "Therapeutic Exercise (15 minutes)",
        "97010": "Hot/Cold Packs",
        "97032": "Electrical Stimulation",
        "97035": "Ultrasound",
        "97530": "Therapeutic Activities (15 minutes)"
    ]

    static func getDescription(for code: String) -> String {
        return codes[code] ?? "Unknown Code"
    }
}

// MARK: - ICD-10 Diagnosis Codes (Common for Massage)

struct MassageICD10Codes {
    static let codes: [String: String] = [
        "M79.1": "Myalgia (Muscle Pain)",
        "M54.5": "Low Back Pain",
        "M54.2": "Cervicalgia (Neck Pain)",
        "M25.50": "Joint Pain, Unspecified",
        "M62.81": "Muscle Weakness",
        "M79.3": "Panniculitis (Soft Tissue)",
        "M79.7": "Fibromyalgia",
        "G89.29": "Chronic Pain",
        "M54.6": "Pain in Thoracic Spine",
        "M25.511": "Pain in Right Shoulder",
        "M25.512": "Pain in Left Shoulder",
        "M54.12": "Radiculopathy, Cervical",
        "M54.16": "Radiculopathy, Lumbar",
        "M79.89": "Other Specified Soft Tissue Disorders"
    ]

    static func getDescription(for code: String) -> String {
        return codes[code] ?? "Unknown Diagnosis"
    }
}
