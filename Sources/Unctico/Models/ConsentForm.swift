import Foundation
import SwiftUI

/// Digital consent and legal forms system
struct ConsentForm: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    let clientName: String
    let formType: ConsentFormType
    let version: String
    let content: String
    let signatureData: Data?
    let signatureDate: Date?
    let isSigned: Bool
    let witnessName: String?
    let witnessSignature: Data?
    let createdDate: Date
    let lastModifiedDate: Date
    let expirationDate: Date?
    let isActive: Bool

    init(
        id: UUID = UUID(),
        clientId: UUID,
        clientName: String,
        formType: ConsentFormType,
        version: String = "1.0",
        content: String,
        signatureData: Data? = nil,
        signatureDate: Date? = nil,
        isSigned: Bool = false,
        witnessName: String? = nil,
        witnessSignature: Data? = nil,
        createdDate: Date = Date(),
        lastModifiedDate: Date = Date(),
        expirationDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.clientId = clientId
        self.clientName = clientName
        self.formType = formType
        self.version = version
        self.content = content
        self.signatureData = signatureData
        self.signatureDate = signatureDate
        self.isSigned = isSigned
        self.witnessName = witnessName
        self.witnessSignature = witnessSignature
        self.createdDate = createdDate
        self.lastModifiedDate = lastModifiedDate
        self.expirationDate = expirationDate
        self.isActive = isActive
    }

    /// Check if form is expired
    var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return Date() > expiration
    }

    /// Check if form needs renewal
    var needsRenewal: Bool {
        guard let expiration = expirationDate else { return false }
        // Warn 30 days before expiration
        let warningDate = Calendar.current.date(byAdding: .day, value: -30, to: expiration) ?? expiration
        return Date() > warningDate
    }
}

/// Types of consent forms
enum ConsentFormType: String, Codable, CaseIterable {
    case informedConsent = "Informed Consent"
    case treatmentAgreement = "Treatment Agreement"
    case liabilityWaiver = "Liability Waiver"
    case privacyNotice = "Privacy Notice (HIPAA)"
    case photoVideoConsent = "Photo/Video Consent"
    case minorConsent = "Minor Consent"
    case cancellationPolicy = "Cancellation Policy"
    case arbitrationAgreement = "Arbitration Agreement"
    case covidScreening = "COVID-19 Screening"
    case scopeOfPractice = "Scope of Practice Disclosure"
    case financialAgreement = "Financial Agreement"
    case releaseOfInformation = "Release of Information"

    var icon: String {
        switch self {
        case .informedConsent: return "doc.text.fill"
        case .treatmentAgreement: return "checkmark.seal.fill"
        case .liabilityWaiver: return "exclamationmark.shield.fill"
        case .privacyNotice: return "lock.shield.fill"
        case .photoVideoConsent: return "camera.fill"
        case .minorConsent: return "person.2.fill"
        case .cancellationPolicy: return "calendar.badge.exclamationmark"
        case .arbitrationAgreement: return "hammer.fill"
        case .covidScreening: return "cross.case.fill"
        case .scopeOfPractice: return "info.circle.fill"
        case .financialAgreement: return "dollarsign.circle.fill"
        case .releaseOfInformation: return "square.and.arrow.up.fill"
        }
    }

    var color: Color {
        switch self {
        case .informedConsent: return .blue
        case .treatmentAgreement: return .green
        case .liabilityWaiver: return .red
        case .privacyNotice: return .purple
        case .photoVideoConsent: return .orange
        case .minorConsent: return .pink
        case .cancellationPolicy: return .yellow
        case .arbitrationAgreement: return .brown
        case .covidScreening: return .teal
        case .scopeOfPractice: return .indigo
        case .financialAgreement: return .cyan
        case .releaseOfInformation: return .mint
        }
    }

    var requiresWitness: Bool {
        switch self {
        case .minorConsent, .arbitrationAgreement:
            return true
        default:
            return false
        }
    }

    var expirationPeriod: DateComponents? {
        switch self {
        case .covidScreening:
            return DateComponents(month: 3)
        case .informedConsent, .treatmentAgreement:
            return DateComponents(year: 1)
        case .privacyNotice:
            return DateComponents(year: 3)
        default:
            return nil // No expiration
        }
    }

    /// Get default template content
    func getDefaultTemplate(practiceName: String, therapistName: String) -> String {
        switch self {
        case .informedConsent:
            return """
            INFORMED CONSENT FOR MASSAGE THERAPY

            Practice: \(practiceName)
            Therapist: \(therapistName)

            I understand that massage therapy is intended to enhance relaxation, reduce pain and muscle tension, improve circulation, and support overall wellness. I acknowledge that:

            1. SCOPE OF PRACTICE
            - Massage therapy is not a substitute for medical examination or diagnosis
            - The therapist is not qualified to diagnose, prescribe, or treat medical conditions
            - I should consult with my physician for any medical concerns

            2. TREATMENT APPROACH
            - I will communicate openly about my health conditions and concerns
            - I will inform the therapist of any discomfort during the session
            - I understand that pressure, techniques, and treatment areas can be adjusted

            3. POTENTIAL BENEFITS
            - Relaxation and stress reduction
            - Relief from muscular tension and pain
            - Improved circulation and flexibility
            - Enhanced sense of well-being

            4. POTENTIAL RISKS
            - Temporary soreness or discomfort
            - Skin irritation from oils or lotions
            - Aggravation of pre-existing conditions (if not properly disclosed)

            5. CONTRAINDICATIONS
            I have disclosed all relevant medical conditions, including but not limited to:
            - Recent injuries or surgeries
            - Cardiovascular conditions
            - Pregnancy
            - Infectious diseases
            - Medications that affect healing

            6. CONSENT
            I voluntarily consent to massage therapy treatment and confirm that I have disclosed all relevant health information.

            Client Signature: _____________________ Date: _____________
            """

        case .liabilityWaiver:
            return """
            LIABILITY WAIVER AND RELEASE

            Practice: \(practiceName)
            Therapist: \(therapistName)

            In consideration of being permitted to receive massage therapy services, I hereby:

            1. ASSUMPTION OF RISK
            I understand that massage therapy involves physical touch and manipulation of muscles and soft tissues. I acknowledge that there are inherent risks, including but not limited to temporary discomfort, bruising, or aggravation of pre-existing conditions.

            2. RELEASE OF LIABILITY
            I hereby release, waive, discharge, and covenant not to sue \(practiceName), \(therapistName), and all associated staff from any and all liability, claims, demands, or causes of action arising from my participation in massage therapy services.

            3. MEDICAL CLEARANCE
            I confirm that I have consulted with a physician regarding any medical conditions that may be affected by massage therapy, or I have chosen not to consult a physician and take full responsibility for this decision.

            4. INDEMNIFICATION
            I agree to indemnify and hold harmless \(practiceName) from any loss, liability, damage, or costs that may arise from my participation in massage therapy services.

            5. ACKNOWLEDGMENT
            I have read this waiver and fully understand its contents. I voluntarily agree to its terms.

            Client Signature: _____________________ Date: _____________
            """

        case .privacyNotice:
            return """
            NOTICE OF PRIVACY PRACTICES (HIPAA)

            Practice: \(practiceName)

            This notice describes how medical information about you may be used and disclosed and how you can get access to this information.

            YOUR RIGHTS:
            - Right to inspect and copy your health information
            - Right to request amendments to your health information
            - Right to receive an accounting of disclosures
            - Right to request restrictions on uses and disclosures
            - Right to request confidential communications
            - Right to file a complaint

            OUR RESPONSIBILITIES:
            - Maintain the privacy of your health information
            - Provide you with this notice of our legal duties and privacy practices
            - Abide by the terms of this notice
            - Notify you if we are unable to agree to a requested restriction

            PERMITTED USES AND DISCLOSURES:
            We may use and disclose your health information for:
            - Treatment purposes
            - Payment purposes
            - Healthcare operations
            - As required by law
            - Public health activities
            - In case of serious threat to health or safety

            CHANGES TO THIS NOTICE:
            We reserve the right to change this notice. Changes will be posted and available upon request.

            COMPLAINTS:
            You may file a complaint with our office or with the Secretary of Health and Human Services if you believe your privacy rights have been violated.

            ACKNOWLEDGMENT:
            I acknowledge that I have received and reviewed the Notice of Privacy Practices.

            Client Signature: _____________________ Date: _____________
            """

        case .cancellationPolicy:
            return """
            CANCELLATION AND NO-SHOW POLICY

            Practice: \(practiceName)

            We understand that schedule changes are sometimes necessary. To ensure we can accommodate all clients and maintain efficient operations, we have implemented the following policy:

            CANCELLATION POLICY:
            - 24-hour notice required for cancellations
            - Cancellations with less than 24 hours notice will be charged 50% of the service fee
            - Same-day cancellations will be charged 100% of the service fee

            NO-SHOW POLICY:
            - Failure to show for a scheduled appointment without notice will result in a charge of 100% of the service fee
            - Repeated no-shows may result in a requirement for prepayment of future appointments

            LATE ARRIVAL POLICY:
            - Please arrive 10 minutes before your scheduled appointment
            - Arriving more than 15 minutes late may result in shortened service time or rescheduling
            - You will be charged for the full appointment time

            EXCEPTIONS:
            - Emergency situations will be considered on a case-by-case basis
            - Weather emergencies or natural disasters

            RESCHEDULING:
            - We will make every effort to accommodate rescheduling requests
            - Multiple last-minute reschedules may require prepayment

            ACKNOWLEDGMENT:
            I have read, understand, and agree to comply with this cancellation policy.

            Client Signature: _____________________ Date: _____________
            """

        case .covidScreening:
            return """
            COVID-19 HEALTH SCREENING FORM

            Practice: \(practiceName)
            Date: _____________

            For the safety of all clients and staff, please answer the following questions:

            In the past 14 days, have you:
            □ Tested positive for COVID-19?
            □ Experienced fever, cough, or difficulty breathing?
            □ Experienced loss of taste or smell?
            □ Been in close contact with someone diagnosed with COVID-19?
            □ Traveled to any high-risk areas?

            SAFETY MEASURES:
            - Temperature check will be performed upon arrival
            - Hand sanitization required before and after session
            - Masks may be required based on local guidelines
            - Enhanced cleaning protocols are in effect

            I certify that the above information is accurate and complete. I understand that any false information may result in cancellation of my appointment.

            Client Signature: _____________________ Date: _____________
            """

        default:
            return """
            \(formType.rawValue.uppercased())

            Practice: \(practiceName)
            Therapist: \(therapistName)

            [Form content to be customized]

            I have read and understand this document.

            Client Signature: _____________________ Date: _____________
            """
        }
    }
}

/// Form template for creating new consent forms
struct ConsentFormTemplate: Identifiable, Codable {
    let id: UUID
    let formType: ConsentFormType
    let name: String
    let version: String
    let content: String
    let isCustom: Bool
    let createdDate: Date
    let lastModifiedDate: Date

    init(
        id: UUID = UUID(),
        formType: ConsentFormType,
        name: String,
        version: String = "1.0",
        content: String,
        isCustom: Bool = false,
        createdDate: Date = Date(),
        lastModifiedDate: Date = Date()
    ) {
        self.id = id
        self.formType = formType
        self.name = name
        self.version = version
        self.content = content
        self.isCustom = isCustom
        self.createdDate = createdDate
        self.lastModifiedDate = lastModifiedDate
    }
}

/// Signature capture data
struct Signature: Codable {
    let imageData: Data
    let timestamp: Date
    let signerName: String
    let signerType: SignerType

    enum SignerType: String, Codable {
        case client = "Client"
        case guardian = "Guardian"
        case witness = "Witness"
        case therapist = "Therapist"
    }
}

/// Form delivery method tracking
enum FormDeliveryMethod: String, Codable {
    case inPerson = "In Person"
    case email = "Email"
    case portal = "Client Portal"
    case mail = "Mail"
}

/// Form status for workflow tracking
enum FormStatus: String, Codable {
    case draft = "Draft"
    case sent = "Sent"
    case pending = "Pending Signature"
    case signed = "Signed"
    case expired = "Expired"
    case voided = "Voided"

    var color: Color {
        switch self {
        case .draft: return .gray
        case .sent: return .blue
        case .pending: return .orange
        case .signed: return .green
        case .expired: return .red
        case .voided: return .purple
        }
    }
}
