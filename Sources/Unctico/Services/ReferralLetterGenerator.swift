import Foundation

/// Service for generating professional referral letters to healthcare providers
@MainActor
class ReferralLetterGenerator: ObservableObject {
    static let shared = ReferralLetterGenerator()

    private init() {}

    /// Generate a referral letter for a client
    func generateReferralLetter(
        client: Client,
        provider: HealthcareProvider,
        reason: ReferralReason,
        findings: ClinicalFindings,
        therapistInfo: TherapistInfo
    ) -> String {
        let date = Date().formatted(date: .long, time: .omitted)

        return """
        \(date)

        \(provider.name), \(provider.credentials)
        \(provider.practiceName)
        \(provider.address)
        \(provider.city), \(provider.state) \(provider.zipCode)

        Re: \(client.firstName) \(client.lastName)
        DOB: \(formatDate(client.dateOfBirth))

        Dear Dr. \(provider.lastName),

        \(generateOpeningParagraph(reason: reason, client: client))

        CLINICAL PRESENTATION:
        \(findings.presentation)

        SUBJECTIVE FINDINGS:
        \(findings.subjective)

        OBJECTIVE FINDINGS:
        \(findings.objective)

        ASSESSMENT:
        \(findings.assessment)

        TREATMENT PROVIDED:
        \(findings.treatmentProvided)

        REASON FOR REFERRAL:
        \(reason.description)

        SPECIFIC CONCERNS:
        \(findings.specificConcerns)

        \(generateClosingParagraph(reason: reason))

        Please feel free to contact me if you need any additional information regarding this client's care.

        Sincerely,

        \(therapistInfo.name), \(therapistInfo.credentials)
        \(therapistInfo.licenseType) #\(therapistInfo.licenseNumber)
        \(therapistInfo.practiceName)
        Phone: \(therapistInfo.phone)
        Email: \(therapistInfo.email)
        """
    }

    private func generateOpeningParagraph(reason: ReferralReason, client: Client) -> String {
        switch reason {
        case .medicalClearance:
            return "I am writing to request medical clearance for \(client.firstName) \(client.lastName) to receive massage therapy treatment. The client has presented with conditions that require your evaluation before proceeding with treatment."

        case .redFlags:
            return "I am referring \(client.firstName) \(client.lastName) to you for evaluation of symptoms that warrant immediate medical attention. The client presented with red flag symptoms during assessment that are beyond the scope of massage therapy practice."

        case .lackOfProgress:
            return "I am referring \(client.firstName) \(client.lastName) for further evaluation. The client has been under my care for massage therapy, but has shown minimal improvement despite appropriate treatment. I believe further medical evaluation is warranted to rule out underlying conditions."

        case .additionalCare:
            return "I am writing regarding our mutual client, \(client.firstName) \(client.lastName), who is currently receiving massage therapy treatment at my practice. I believe the client would benefit from complementary care from your specialty to optimize treatment outcomes."

        case .diagnostic:
            return "I am referring \(client.firstName) \(client.lastName) for diagnostic evaluation. The client has presented with symptoms that require medical imaging or diagnostic testing to determine the appropriate course of treatment."

        case .contraindication:
            return "I am referring \(client.firstName) \(client.lastName) for evaluation of a condition that may contraindicate massage therapy. I want to ensure it is safe to proceed with treatment and seek your guidance on any modifications that may be necessary."

        case .postSurgical:
            return "I am writing regarding \(client.firstName) \(client.lastName), who has requested post-surgical massage therapy. I would like to coordinate care and obtain your clearance and recommendations before beginning treatment."

        case .chronicCondition:
            return "I am writing regarding \(client.firstName) \(client.lastName), who has presented with a chronic condition that requires ongoing medical management. I would like to coordinate our treatment approaches to best serve the client's needs."
        }
    }

    private func generateClosingParagraph(reason: ReferralReason) -> String {
        switch reason {
        case .medicalClearance:
            return "I await your clearance before proceeding with treatment. Please indicate any precautions or modifications you recommend for massage therapy."

        case .redFlags:
            return "I recommend prompt evaluation given the nature of the symptoms presented. I have advised the client to follow up with you as soon as possible."

        case .lackOfProgress:
            return "I will continue supportive care pending your evaluation and recommendations. Please advise if there are specific treatment modifications you would recommend."

        case .additionalCare:
            return "I believe coordinated care would be beneficial for this client's recovery. I am happy to communicate with your office regarding treatment progress and any adjustments needed."

        case .diagnostic:
            return "Once diagnostic findings are available, I would appreciate your guidance on treatment modifications or contraindications to consider."

        case .contraindication:
            return "I will hold treatment pending your evaluation and recommendations. Please advise if massage therapy is appropriate and any modifications that should be implemented."

        case .postSurgical:
            return "I await your clearance and specific guidelines for post-surgical massage therapy. I will defer treatment until I receive your recommendations."

        case .chronicCondition:
            return "I look forward to collaborating with you on this client's care. Please let me know of any changes to the treatment plan that should be communicated."
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Models

struct HealthcareProvider: Codable {
    let name: String
    let lastName: String
    let credentials: String // MD, DO, DC, PT, etc.
    let practiceName: String
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let phone: String?
    let fax: String?
    let email: String?
    let specialty: String?

    init(
        name: String,
        lastName: String,
        credentials: String,
        practiceName: String,
        address: String,
        city: String,
        state: String,
        zipCode: String,
        phone: String? = nil,
        fax: String? = nil,
        email: String? = nil,
        specialty: String? = nil
    ) {
        self.name = name
        self.lastName = lastName
        self.credentials = credentials
        self.practiceName = practiceName
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.phone = phone
        self.fax = fax
        self.email = email
        self.specialty = specialty
    }
}

enum ReferralReason: String, Codable, CaseIterable {
    case medicalClearance = "Medical Clearance Required"
    case redFlags = "Red Flag Symptoms"
    case lackOfProgress = "Lack of Progress"
    case additionalCare = "Complementary Care Needed"
    case diagnostic = "Diagnostic Evaluation Needed"
    case contraindication = "Potential Contraindication"
    case postSurgical = "Post-Surgical Clearance"
    case chronicCondition = "Chronic Condition Management"

    var description: String {
        switch self {
        case .medicalClearance:
            return "The client requires medical clearance before massage therapy can be safely provided."
        case .redFlags:
            return "The client presents with symptoms that require immediate medical evaluation."
        case .lackOfProgress:
            return "The client has not responded adequately to massage therapy treatment, suggesting an underlying condition may require medical intervention."
        case .additionalCare:
            return "Coordinated multidisciplinary care would optimize treatment outcomes for this client."
        case .diagnostic:
            return "Diagnostic imaging or testing is needed to determine the appropriate treatment approach."
        case .contraindication:
            return "A condition has been identified that may contraindicate massage therapy treatment."
        case .postSurgical:
            return "Physician clearance and guidance are requested for post-surgical massage therapy."
        case .chronicCondition:
            return "The client has a chronic condition requiring ongoing medical management and care coordination."
        }
    }

    var icon: String {
        switch self {
        case .medicalClearance: return "checkmark.shield"
        case .redFlags: return "exclamationmark.triangle.fill"
        case .lackOfProgress: return "chart.line.downtrend.xyaxis"
        case .additionalCare: return "person.2.fill"
        case .diagnostic: return "cross.case.fill"
        case .contraindication: return "hand.raised.fill"
        case .postSurgical: return "cross.fill"
        case .chronicCondition: return "heart.text.square.fill"
        }
    }
}

struct ClinicalFindings: Codable {
    let presentation: String
    let subjective: String
    let objective: String
    let assessment: String
    let treatmentProvided: String
    let specificConcerns: String

    init(
        presentation: String = "",
        subjective: String = "",
        objective: String = "",
        assessment: String = "",
        treatmentProvided: String = "",
        specificConcerns: String = ""
    ) {
        self.presentation = presentation
        self.subjective = subjective
        self.objective = objective
        self.assessment = assessment
        self.treatmentProvided = treatmentProvided
        self.specificConcerns = specificConcerns
    }
}

struct TherapistInfo: Codable {
    let name: String
    let credentials: String // LMT, CMT, RMT, etc.
    let licenseType: String
    let licenseNumber: String
    let practiceName: String
    let phone: String
    let email: String
    let address: String?

    init(
        name: String,
        credentials: String,
        licenseType: String,
        licenseNumber: String,
        practiceName: String,
        phone: String,
        email: String,
        address: String? = nil
    ) {
        self.name = name
        self.credentials = credentials
        self.licenseType = licenseType
        self.licenseNumber = licenseNumber
        self.practiceName = practiceName
        self.phone = phone
        self.email = email
        self.address = address
    }
}

// Client extension for referral letters
extension Client {
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
