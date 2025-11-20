import Combine
import Foundation

class InsuranceBillingService: ObservableObject {
    static let shared = InsuranceBillingService()

    @Published var claims: [InsuranceClaim] = []
    @Published var insuranceProviders: [InsuranceProvider] = []

    private init() {
        loadDefaultProviders()
    }

    // MARK: - Claim Creation

    func createClaim(
        for clientId: UUID,
        insuranceProviderId: UUID,
        appointments: [Appointment],
        diagnosisCodes: [String],
        procedureCodes: [ProcedureCode]
    ) -> InsuranceClaim {
        let totalBilled = procedureCodes.reduce(0) { $0 + ($1.chargeAmount * Double($1.units)) }

        return InsuranceClaim(
            clientId: clientId,
            insuranceProviderId: insuranceProviderId,
            appointmentIds: appointments.map { $0.id },
            dateOfService: appointments.first?.startTime ?? Date(),
            totalBilled: totalBilled,
            diagnosisCodes: diagnosisCodes,
            procedureCodes: procedureCodes
        )
    }

    // MARK: - CMS-1500 Form Generation

    func generateCMS1500Form(claim: InsuranceClaim, client: Client, provider: InsuranceProvider) -> CMS1500Form {
        return CMS1500Form(
            claim: claim,
            client: client,
            provider: provider
        )
    }

    // MARK: - Eligibility Verification

    func verifyEligibility(
        clientId: UUID,
        insuranceProviderId: UUID,
        completion: @escaping (Result<EligibilityResponse, Error>) -> Void
    ) {
        // Simulate API call to insurance verification service
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let response = EligibilityResponse(
                isActive: Bool.random(),
                coverageDetails: "Benefits available for massage therapy with medical necessity",
                deductible: 500.00,
                deductibleMet: Double.random(in: 0...500),
                copay: 25.00,
                coinsurance: 0.2,
                outOfPocketMax: 3000.00,
                outOfPocketMet: Double.random(in: 0...3000)
            )
            completion(.success(response))
        }
    }

    // MARK: - Claim Submission

    func submitClaim(
        _ claim: InsuranceClaim,
        completion: @escaping (Result<InsuranceClaim, Error>) -> Void
    ) {
        var updatedClaim = claim
        updatedClaim.status = .submitted
        updatedClaim.dateSubmitted = Date()

        // Simulate electronic submission
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Simulate 80% acceptance rate
            if Double.random(in: 0...1) < 0.8 {
                updatedClaim.status = .inReview
                completion(.success(updatedClaim))
            } else {
                updatedClaim.status = .denied
                updatedClaim.denialReason = "Invalid diagnosis code or missing documentation"
                completion(.failure(ClaimError.submissionFailed))
            }
        }
    }

    // MARK: - ERA Processing (Electronic Remittance Advice)

    func processERA(_ eraData: ERAData) -> [InsuranceClaim] {
        var updatedClaims: [InsuranceClaim] = []

        for payment in eraData.payments {
            if var claim = claims.first(where: { $0.claimNumber == payment.claimNumber }) {
                claim.status = payment.paidAmount > 0 ? .paid : .denied
                claim.paidAmount = payment.paidAmount
                claim.allowedAmount = payment.allowedAmount
                claim.adjustments = payment.adjustments
                claim.patientResponsibility = payment.patientResponsibility

                updatedClaims.append(claim)
            }
        }

        return updatedClaims
    }

    // MARK: - Denial Management

    func createAppeal(
        for claim: InsuranceClaim,
        appealReason: String,
        supportingDocuments: [String]
    ) -> Appeal {
        return Appeal(
            claimId: claim.id,
            appealReason: appealReason,
            supportingDocuments: supportingDocuments,
            dateSubmitted: Date()
        )
    }

    // MARK: - Common Procedure Codes for Massage

    func getCommonProcedureCodes() -> [ProcedureCode] {
        return [
            ProcedureCode(code: "97124", description: "Massage Therapy (15 min)", chargeAmount: 30.00),
            ProcedureCode(code: "97140", description: "Manual Therapy (15 min)", chargeAmount: 35.00),
            ProcedureCode(code: "97112", description: "Neuromuscular Reeducation (15 min)", chargeAmount: 32.00),
            ProcedureCode(code: "97110", description: "Therapeutic Exercise (15 min)", chargeAmount: 28.00)
        ]
    }

    // MARK: - Common Diagnosis Codes

    func getCommonDiagnosisCodes() -> [DiagnosisCode] {
        return [
            DiagnosisCode(code: "M79.1", description: "Myalgia (Muscle Pain)"),
            DiagnosisCode(code: "M54.5", description: "Low Back Pain"),
            DiagnosisCode(code: "M54.2", description: "Cervicalgia (Neck Pain)"),
            DiagnosisCode(code: "M25.50", description: "Joint Pain, Unspecified"),
            DiagnosisCode(code: "M79.7", description: "Fibromyalgia")
        ]
    }

    // MARK: - Default Providers

    private func loadDefaultProviders() {
        insuranceProviders = [
            InsuranceProvider(name: "Blue Cross Blue Shield", payerId: "BCBS001", isPreferred: true),
            InsuranceProvider(name: "Aetna", payerId: "AETNA001"),
            InsuranceProvider(name: "UnitedHealthcare", payerId: "UHC001"),
            InsuranceProvider(name: "Cigna", payerId: "CIGNA001"),
            InsuranceProvider(name: "Humana", payerId: "HUMANA001")
        ]
    }
}

// MARK: - Supporting Models

struct CMS1500Form {
    let claim: InsuranceClaim
    let client: Client
    let provider: InsuranceProvider

    // Form fields for CMS-1500
    var box1: String { "Medicare" } // Insurance type
    var box2: String { client.fullName }
    var box3: String { client.dateOfBirth?.formatted(date: .numeric, time: .omitted) ?? "" }
    var box11: String { "Insurance Policy Number" }
    var box24: [ProcedureCode] { claim.procedureCodes }

    func generatePDF() -> Data? {
        // Implementation would generate actual CMS-1500 PDF
        return nil
    }
}

struct EligibilityResponse {
    var isActive: Bool
    var coverageDetails: String
    var deductible: Double
    var deductibleMet: Double
    var copay: Double
    var coinsurance: Double
    var outOfPocketMax: Double
    var outOfPocketMet: Double

    var remainingDeductible: Double {
        max(0, deductible - deductibleMet)
    }

    var remainingOutOfPocket: Double {
        max(0, outOfPocketMax - outOfPocketMet)
    }
}

struct ERAData {
    var payments: [ERAPayment]
    var checkNumber: String
    var checkDate: Date
    var totalAmount: Double
}

struct ERAPayment {
    var claimNumber: String
    var allowedAmount: Double
    var paidAmount: Double
    var patientResponsibility: Double
    var adjustments: [ClaimAdjustment]
}

struct Appeal: Identifiable {
    let id: UUID
    var claimId: UUID
    var appealReason: String
    var supportingDocuments: [String]
    var dateSubmitted: Date
    var status: AppealStatus
    var resolution: String?

    init(
        id: UUID = UUID(),
        claimId: UUID,
        appealReason: String,
        supportingDocuments: [String],
        dateSubmitted: Date,
        status: AppealStatus = .submitted,
        resolution: String? = nil
    ) {
        self.id = id
        self.claimId = claimId
        self.appealReason = appealReason
        self.supportingDocuments = supportingDocuments
        self.dateSubmitted = dateSubmitted
        self.status = status
        self.resolution = resolution
    }

    enum AppealStatus: String, Codable {
        case draft = "Draft"
        case submitted = "Submitted"
        case underReview = "Under Review"
        case approved = "Approved"
        case denied = "Denied"
    }
}

struct DiagnosisCode {
    var code: String
    var description: String
}

enum ClaimError: Error {
    case submissionFailed
    case invalidData
    case networkError

    var localizedDescription: String {
        switch self {
        case .submissionFailed: return "Claim submission failed"
        case .invalidData: return "Invalid claim data"
        case .networkError: return "Network connection error"
        }
    }
}
