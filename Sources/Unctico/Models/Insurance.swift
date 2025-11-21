import Foundation

/// Insurance integration models
/// TODO: Integrate with insurance clearinghouse API (Change Healthcare, Availity, etc.)

// MARK: - Insurance Claim

struct InsuranceClaim: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    let appointmentId: UUID
    var claimNumber: String
    var submissionDate: Date
    var serviceDate: Date
    var status: ClaimStatus
    var insuranceCompany: InsuranceCompany
    var policyNumber: String
    var groupNumber: String?
    var subscriberName: String
    var patientName: String
    var diagnosis: [DiagnosisCode]
    var procedures: [ProcedureCode]
    var billedAmount: Double
    var allowedAmount: Double?
    var paidAmount: Double?
    var patientResponsibility: Double?
    var adjustments: [ClaimAdjustment]
    var denialReason: String?
    var notes: String

    init(
        id: UUID = UUID(),
        clientId: UUID,
        appointmentId: UUID,
        claimNumber: String,
        submissionDate: Date = Date(),
        serviceDate: Date,
        status: ClaimStatus = .draft,
        insuranceCompany: InsuranceCompany,
        policyNumber: String,
        groupNumber: String? = nil,
        subscriberName: String,
        patientName: String,
        diagnosis: [DiagnosisCode] = [],
        procedures: [ProcedureCode] = [],
        billedAmount: Double,
        allowedAmount: Double? = nil,
        paidAmount: Double? = nil,
        patientResponsibility: Double? = nil,
        adjustments: [ClaimAdjustment] = [],
        denialReason: String? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.clientId = clientId
        self.appointmentId = appointmentId
        self.claimNumber = claimNumber
        self.submissionDate = submissionDate
        self.serviceDate = serviceDate
        self.status = status
        self.insuranceCompany = insuranceCompany
        self.policyNumber = policyNumber
        self.groupNumber = groupNumber
        self.subscriberName = subscriberName
        self.patientName = patientName
        self.diagnosis = diagnosis
        self.procedures = procedures
        self.billedAmount = billedAmount
        self.allowedAmount = allowedAmount
        self.paidAmount = paidAmount
        self.patientResponsibility = patientResponsibility
        self.adjustments = adjustments
        self.denialReason = denialReason
        self.notes = notes
    }
}

enum ClaimStatus: String, Codable {
    case draft = "Draft"
    case submitted = "Submitted"
    case accepted = "Accepted"
    case rejected = "Rejected"
    case pending = "Pending"
    case paid = "Paid"
    case partiallyPaid = "Partially Paid"
    case denied = "Denied"
}

struct InsuranceCompany: Codable {
    var name: String
    var payerId: String // Payer ID for electronic claims
    var phone: String
    var address: String
}

struct DiagnosisCode: Identifiable, Codable {
    let id: UUID
    var code: String // ICD-10 code
    var description: String

    init(id: UUID = UUID(), code: String, description: String) {
        self.id = id
        self.code = code
        self.description = description
    }
}

struct ProcedureCode: Identifiable, Codable {
    let id: UUID
    var code: String // CPT code (e.g., 97124 for massage therapy)
    var description: String
    var units: Int
    var chargePerUnit: Double

    init(id: UUID = UUID(), code: String, description: String, units: Int = 1, chargePerUnit: Double) {
        self.id = id
        self.code = code
        self.description = description
        self.units = units
        self.chargePerUnit = chargePerUnit
    }

    var totalCharge: Double {
        Double(units) * chargePerUnit
    }
}

struct ClaimAdjustment: Identifiable, Codable {
    let id: UUID
    var adjustmentCode: String
    var amount: Double
    var reason: String

    init(id: UUID = UUID(), adjustmentCode: String, amount: Double, reason: String) {
        self.id = id
        self.adjustmentCode = adjustmentCode
        self.amount = amount
        self.reason = reason
    }
}

// MARK: - Eligibility Check

struct EligibilityCheck: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    var checkDate: Date
    var insuranceCompany: InsuranceCompany
    var policyNumber: String
    var subscriberName: String
    var status: EligibilityStatus
    var isActive: Bool
    var coverageDetails: CoverageDetails?
    var copayAmount: Double?
    var deductible: Double?
    var deductibleMet: Double?
    var outOfPocketMax: Double?
    var outOfPocketMet: Double?

    init(
        id: UUID = UUID(),
        clientId: UUID,
        checkDate: Date = Date(),
        insuranceCompany: InsuranceCompany,
        policyNumber: String,
        subscriberName: String,
        status: EligibilityStatus = .pending,
        isActive: Bool = false,
        coverageDetails: CoverageDetails? = nil,
        copayAmount: Double? = nil,
        deductible: Double? = nil,
        deductibleMet: Double? = nil,
        outOfPocketMax: Double? = nil,
        outOfPocketMet: Double? = nil
    ) {
        self.id = id
        self.clientId = clientId
        self.checkDate = checkDate
        self.insuranceCompany = insuranceCompany
        self.policyNumber = policyNumber
        self.subscriberName = subscriberName
        self.status = status
        self.isActive = isActive
        self.coverageDetails = coverageDetails
        self.copayAmount = copayAmount
        self.deductible = deductible
        self.deductibleMet = deductibleMet
        self.outOfPocketMax = outOfPocketMax
        self.outOfPocketMet = outOfPocketMet
    }
}

enum EligibilityStatus: String, Codable {
    case pending = "Pending"
    case verified = "Verified"
    case failed = "Failed"
}

struct CoverageDetails: Codable {
    var massageTherapyCovered: Bool
    var requiresReferral: Bool
    var requiresPreAuthorization: Bool
    var visitLimit: Int?
    var visitsRemaining: Int?
    var coveragePercentage: Double
}

// MARK: - ERA (Electronic Remittance Advice)

struct ElectronicRemittance: Identifiable, Codable {
    let id: UUID
    var eraNumber: String
    var receivedDate: Date
    var paymentDate: Date
    var payerName: String
    var checkNumber: String?
    var totalPaid: Double
    var claims: [ERAClaim]

    init(
        id: UUID = UUID(),
        eraNumber: String,
        receivedDate: Date = Date(),
        paymentDate: Date,
        payerName: String,
        checkNumber: String? = nil,
        totalPaid: Double,
        claims: [ERAClaim] = []
    ) {
        self.id = id
        self.eraNumber = eraNumber
        self.receivedDate = receivedDate
        self.paymentDate = paymentDate
        self.payerName = payerName
        self.checkNumber = checkNumber
        self.totalPaid = totalPaid
        self.claims = claims
    }
}

struct ERAClaim: Identifiable, Codable {
    let id: UUID
    var claimNumber: String
    var patientName: String
    var serviceDate: Date
    var billedAmount: Double
    var allowedAmount: Double
    var paidAmount: Double
    var patientResponsibility: Double
    var adjustments: [ClaimAdjustment]

    init(
        id: UUID = UUID(),
        claimNumber: String,
        patientName: String,
        serviceDate: Date,
        billedAmount: Double,
        allowedAmount: Double,
        paidAmount: Double,
        patientResponsibility: Double,
        adjustments: [ClaimAdjustment] = []
    ) {
        self.id = id
        self.claimNumber = claimNumber
        self.patientName = patientName
        self.serviceDate = serviceDate
        self.billedAmount = billedAmount
        self.allowedAmount = allowedAmount
        self.paidAmount = paidAmount
        self.patientResponsibility = patientResponsibility
        self.adjustments = adjustments
    }
}

// MARK: - Statistics

struct InsuranceStatistics {
    let totalClaims: Int
    let submittedClaims: Int
    let paidClaims: Int
    let deniedClaims: Int
    let totalBilled: Double
    let totalPaid: Double
    let averageReimbursementRate: Double
    let averageDaysToPayment: Double

    init(
        totalClaims: Int = 0,
        submittedClaims: Int = 0,
        paidClaims: Int = 0,
        deniedClaims: Int = 0,
        totalBilled: Double = 0,
        totalPaid: Double = 0,
        averageReimbursementRate: Double = 0,
        averageDaysToPayment: Double = 0
    ) {
        self.totalClaims = totalClaims
        self.submittedClaims = submittedClaims
        self.paidClaims = paidClaims
        self.deniedClaims = deniedClaims
        self.totalBilled = totalBilled
        self.totalPaid = totalPaid
        self.averageReimbursementRate = averageReimbursementRate
        self.averageDaysToPayment = averageDaysToPayment
    }
}
