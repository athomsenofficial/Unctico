import Foundation
import SwiftUI

/// Professional license tracking for compliance
struct ProfessionalLicense: Identifiable, Codable {
    let id: UUID
    let licenseType: LicenseType
    let state: String
    let licenseNumber: String
    let issueDate: Date
    let expirationDate: Date
    let status: LicenseStatus
    let renewalFee: Double?
    let notes: String
    let documentPath: String? // Path to license document/photo

    init(
        id: UUID = UUID(),
        licenseType: LicenseType,
        state: String,
        licenseNumber: String,
        issueDate: Date,
        expirationDate: Date,
        status: LicenseStatus = .active,
        renewalFee: Double? = nil,
        notes: String = "",
        documentPath: String? = nil
    ) {
        self.id = id
        self.licenseType = licenseType
        self.state = state
        self.licenseNumber = licenseNumber
        self.issueDate = issueDate
        self.expirationDate = expirationDate
        self.status = status
        self.renewalFee = renewalFee
        self.notes = notes
        self.documentPath = documentPath
    }

    /// Days until expiration
    var daysUntilExpiration: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
    }

    /// Is license expired?
    var isExpired: Bool {
        Date() > expirationDate
    }

    /// Needs renewal soon? (90 days)
    var needsRenewalSoon: Bool {
        daysUntilExpiration <= 90 && daysUntilExpiration > 0
    }

    /// Critical renewal needed (30 days)
    var criticalRenewal: Bool {
        daysUntilExpiration <= 30 && daysUntilExpiration > 0
    }

    /// Alert level for UI
    var alertLevel: AlertLevel {
        if isExpired { return .critical }
        if criticalRenewal { return .urgent }
        if needsRenewalSoon { return .warning }
        return .none
    }

    enum AlertLevel {
        case none, warning, urgent, critical

        var color: Color {
            switch self {
            case .none: return .green
            case .warning: return .yellow
            case .urgent: return .orange
            case .critical: return .red
            }
        }
    }
}

enum LicenseType: String, Codable, CaseIterable {
    case massageTherapy = "Massage Therapy License"
    case bodywork = "Bodywork License"
    case physicalTherapy = "Physical Therapy License"
    case nursing = "Nursing License"
    case chiropractor = "Chiropractic License"
    case acupuncture = "Acupuncture License"
    case sportsMedicine = "Sports Medicine License"
    case businessLicense = "Business License"
    case facilityPermit = "Facility Permit"
    case other = "Other License"

    var icon: String {
        switch self {
        case .massageTherapy, .bodywork: return "hand.raised.fill"
        case .physicalTherapy: return "figure.walk"
        case .nursing: return "cross.case.fill"
        case .chiropractor: return "figure.stand"
        case .acupuncture: return "cross.fill"
        case .sportsMedicine: return "sportscourt.fill"
        case .businessLicense: return "building.2.fill"
        case .facilityPermit: return "building.fill"
        case .other: return "doc.text.fill"
        }
    }

    var color: Color {
        switch self {
        case .massageTherapy, .bodywork: return .blue
        case .physicalTherapy: return .green
        case .nursing: return .red
        case .chiropractor: return .purple
        case .acupuncture: return .orange
        case .sportsMedicine: return .cyan
        case .businessLicense: return .brown
        case .facilityPermit: return .indigo
        case .other: return .gray
        }
    }
}

enum LicenseStatus: String, Codable, CaseIterable {
    case active = "Active"
    case inactive = "Inactive"
    case expired = "Expired"
    case suspended = "Suspended"
    case pending = "Pending Renewal"
    case reciprocity = "Reciprocity Pending"

    var color: Color {
        switch self {
        case .active: return .green
        case .inactive: return .gray
        case .expired: return .red
        case .suspended: return .red
        case .pending: return .orange
        case .reciprocity: return .blue
        }
    }
}

/// Continuing Education (CE) tracking
struct ContinuingEducation: Identifiable, Codable {
    let id: UUID
    let courseName: String
    let provider: String
    let category: CECategory
    let credits: Double
    let completionDate: Date
    let expirationDate: Date?
    let certificateNumber: String
    let cost: Double?
    let notes: String
    let certificatePath: String? // Path to certificate document

    init(
        id: UUID = UUID(),
        courseName: String,
        provider: String,
        category: CECategory,
        credits: Double,
        completionDate: Date,
        expirationDate: Date? = nil,
        certificateNumber: String = "",
        cost: Double? = nil,
        notes: String = "",
        certificatePath: String? = nil
    ) {
        self.id = id
        self.courseName = courseName
        self.provider = provider
        self.category = category
        self.credits = credits
        self.completionDate = completionDate
        self.expirationDate = expirationDate
        self.certificateNumber = certificateNumber
        self.cost = cost
        self.notes = notes
        self.certificatePath = certificatePath
    }

    /// Is this CE still valid?
    var isValid: Bool {
        guard let expiration = expirationDate else { return true }
        return Date() <= expiration
    }
}

enum CECategory: String, Codable, CaseIterable {
    case ethics = "Ethics"
    case anatomy = "Anatomy & Physiology"
    case pathology = "Pathology"
    case modalities = "Modalities & Techniques"
    case businessPractice = "Business Practice"
    case communication = "Communication Skills"
    case specialPopulations = "Special Populations"
    case safetyHygiene = "Safety & Hygiene"
    case assessment = "Assessment & Treatment Planning"
    case research = "Research & Evidence Based Practice"
    case other = "Other"

    var icon: String {
        switch self {
        case .ethics: return "shield.checkered"
        case .anatomy: return "figure.arms.open"
        case .pathology: return "cross.case.fill"
        case .modalities: return "hand.raised.fill"
        case .businessPractice: return "briefcase.fill"
        case .communication: return "bubble.left.and.bubble.right.fill"
        case .specialPopulations: return "person.2.fill"
        case .safetyHygiene: return "allergens.fill"
        case .assessment: return "stethoscope"
        case .research: return "book.fill"
        case .other: return "graduationcap.fill"
        }
    }

    var color: Color {
        switch self {
        case .ethics: return .purple
        case .anatomy: return .blue
        case .pathology: return .red
        case .modalities: return .green
        case .businessPractice: return .orange
        case .communication: return .cyan
        case .specialPopulations: return .pink
        case .safetyHygiene: return .yellow
        case .assessment: return .indigo
        case .research: return .brown
        case .other: return .gray
        }
    }
}

/// Certification tracking (specialty certifications)
struct Certification: Identifiable, Codable {
    let id: UUID
    let name: String
    let issuingOrganization: String
    let certificationNumber: String
    let issueDate: Date
    let expirationDate: Date?
    let requiresRenewal: Bool
    let renewalCost: Double?
    let notes: String
    let certificatePath: String?

    init(
        id: UUID = UUID(),
        name: String,
        issuingOrganization: String,
        certificationNumber: String = "",
        issueDate: Date,
        expirationDate: Date? = nil,
        requiresRenewal: Bool = false,
        renewalCost: Double? = nil,
        notes: String = "",
        certificatePath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.issuingOrganization = issuingOrganization
        self.certificationNumber = certificationNumber
        self.issueDate = issueDate
        self.expirationDate = expirationDate
        self.requiresRenewal = requiresRenewal
        self.renewalCost = renewalCost
        self.notes = notes
        self.certificatePath = certificatePath
    }

    var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return Date() > expiration
    }

    var needsRenewal: Bool {
        guard let expiration = expirationDate else { return false }
        let warningDate = Calendar.current.date(byAdding: .day, value: -60, to: expiration) ?? expiration
        return Date() > warningDate && !isExpired
    }
}

/// State-specific CE requirements
struct StateCERequirements: Codable {
    let state: String
    let renewalPeriod: RenewalPeriod
    let totalCreditsRequired: Double
    let ethicsCreditsRequired: Double?
    let liveClassRequirement: Double?
    let carryOverAllowed: Bool
    let maxCarryOverCredits: Double?
    let notes: String

    init(
        state: String,
        renewalPeriod: RenewalPeriod,
        totalCreditsRequired: Double,
        ethicsCreditsRequired: Double? = nil,
        liveClassRequirement: Double? = nil,
        carryOverAllowed: Bool = false,
        maxCarryOverCredits: Double? = nil,
        notes: String = ""
    ) {
        self.state = state
        self.renewalPeriod = renewalPeriod
        self.totalCreditsRequired = totalCreditsRequired
        self.ethicsCreditsRequired = ethicsCreditsRequired
        self.liveClassRequirement = liveClassRequirement
        self.carryOverAllowed = carryOverAllowed
        self.maxCarryOverCredits = maxCarryOverCredits
        self.notes = notes
    }
}

enum RenewalPeriod: String, Codable {
    case annual = "Annual"
    case biennial = "Every 2 Years"
    case triennial = "Every 3 Years"
}

/// Renewal reminder settings
struct RenewalReminder: Codable {
    let licenseId: UUID
    let reminderDays: [Int] // Days before expiration to send reminder
    let emailEnabled: Bool
    let smsEnabled: Bool
    let pushEnabled: Bool

    init(
        licenseId: UUID,
        reminderDays: [Int] = [90, 60, 30, 14, 7],
        emailEnabled: Bool = true,
        smsEnabled: Bool = false,
        pushEnabled: Bool = true
    ) {
        self.licenseId = licenseId
        self.reminderDays = reminderDays
        self.emailEnabled = emailEnabled
        self.smsEnabled = smsEnabled
        self.pushEnabled = pushEnabled
    }
}

/// Professional insurance tracking
struct ProfessionalInsurance: Identifiable, Codable {
    let id: UUID
    let insuranceType: InsuranceType
    let provider: String
    let policyNumber: String
    let coverageAmount: Double
    let effectiveDate: Date
    let expirationDate: Date
    let premium: Double
    let paymentFrequency: PaymentFrequency
    let notes: String
    let documentPath: String?

    init(
        id: UUID = UUID(),
        insuranceType: InsuranceType,
        provider: String,
        policyNumber: String,
        coverageAmount: Double,
        effectiveDate: Date,
        expirationDate: Date,
        premium: Double,
        paymentFrequency: PaymentFrequency = .annual,
        notes: String = "",
        documentPath: String? = nil
    ) {
        self.id = id
        self.insuranceType = insuranceType
        self.provider = provider
        self.policyNumber = policyNumber
        self.coverageAmount = coverageAmount
        self.effectiveDate = effectiveDate
        self.expirationDate = expirationDate
        self.premium = premium
        self.paymentFrequency = paymentFrequency
        self.notes = notes
        self.documentPath = documentPath
    }

    var isExpired: Bool {
        Date() > expirationDate
    }

    var needsRenewal: Bool {
        let warningDate = Calendar.current.date(byAdding: .day, value: -60, to: expirationDate) ?? expirationDate
        return Date() > warningDate && !isExpired
    }
}

enum InsuranceType: String, Codable, CaseIterable {
    case liability = "Professional Liability"
    case malpractice = "Malpractice Insurance"
    case generalLiability = "General Liability"
    case businessProperty = "Business Property"
    case workersComp = "Workers' Compensation"
    case other = "Other Insurance"

    var icon: String {
        switch self {
        case .liability, .malpractice: return "shield.checkered"
        case .generalLiability: return "shield.fill"
        case .businessProperty: return "building.2.fill"
        case .workersComp: return "person.2.fill"
        case .other: return "doc.text.fill"
        }
    }
}

enum PaymentFrequency: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case semiAnnual = "Semi-Annual"
    case annual = "Annual"
}
