import Foundation

/// Repository for managing professional licenses, certifications, and CE tracking
@MainActor
class LicenseRepository: ObservableObject {
    static let shared = LicenseRepository()

    @Published var licenses: [ProfessionalLicense] = []
    @Published var ceCredits: [ContinuingEducation] = []
    @Published var certifications: [Certification] = []
    @Published var insurancePolicies: [ProfessionalInsurance] = []
    @Published var stateRequirements: [StateCERequirements] = []

    private let licensesKey = "unctico_licenses"
    private let ceKey = "unctico_ce_credits"
    private let certificationsKey = "unctico_certifications"
    private let insuranceKey = "unctico_insurance"
    private let requirementsKey = "unctico_state_requirements"

    init() {
        loadData()
        createDefaultRequirements()
    }

    // MARK: - License Management

    func addLicense(_ license: ProfessionalLicense) {
        licenses.append(license)
        saveLicenses()
    }

    func updateLicense(_ license: ProfessionalLicense) {
        if let index = licenses.firstIndex(where: { $0.id == license.id }) {
            licenses[index] = license
            saveLicenses()
        }
    }

    func deleteLicense(_ id: UUID) {
        licenses.removeAll { $0.id == id }
        saveLicenses()
    }

    func getLicense(_ id: UUID) -> ProfessionalLicense? {
        licenses.first { $0.id == id }
    }

    // MARK: - CE Credit Management

    func addCECredit(_ credit: ContinuingEducation) {
        ceCredits.append(credit)
        saveCECredits()
    }

    func updateCECredit(_ credit: ContinuingEducation) {
        if let index = ceCredits.firstIndex(where: { $0.id == credit.id }) {
            ceCredits[index] = credit
            saveCECredits()
        }
    }

    func deleteCECredit(_ id: UUID) {
        ceCredits.removeAll { $0.id == id }
        saveCECredits()
    }

    // MARK: - Certification Management

    func addCertification(_ certification: Certification) {
        certifications.append(certification)
        saveCertifications()
    }

    func updateCertification(_ certification: Certification) {
        if let index = certifications.firstIndex(where: { $0.id == certification.id }) {
            certifications[index] = certification
            saveCertifications()
        }
    }

    func deleteCertification(_ id: UUID) {
        certifications.removeAll { $0.id == id }
        saveCertifications()
    }

    // MARK: - Insurance Management

    func addInsurance(_ insurance: ProfessionalInsurance) {
        insurancePolicies.append(insurance)
        saveInsurance()
    }

    func updateInsurance(_ insurance: ProfessionalInsurance) {
        if let index = insurancePolicies.firstIndex(where: { $0.id == insurance.id }) {
            insurancePolicies[index] = insurance
            saveInsurance()
        }
    }

    func deleteInsurance(_ id: UUID) {
        insurancePolicies.removeAll { $0.id == id }
        saveInsurance()
    }

    // MARK: - Query Functions

    func getActiveLicenses() -> [ProfessionalLicense] {
        licenses.filter { $0.status == .active && !$0.isExpired }
    }

    func getExpiredLicenses() -> [ProfessionalLicense] {
        licenses.filter { $0.isExpired }
    }

    func getLicensesNeedingRenewal() -> [ProfessionalLicense] {
        licenses.filter { $0.needsRenewalSoon || $0.criticalRenewal }
    }

    func getCriticalLicenses() -> [ProfessionalLicense] {
        licenses.filter { $0.criticalRenewal || $0.isExpired }
    }

    func getValidCECredits(from startDate: Date, to endDate: Date) -> [ContinuingEducation] {
        ceCredits.filter { credit in
            credit.completionDate >= startDate &&
            credit.completionDate <= endDate &&
            credit.isValid
        }
    }

    func getTotalCECredits(from startDate: Date, to endDate: Date) -> Double {
        getValidCECredits(from: startDate, to: endDate)
            .reduce(0) { $0 + $1.credits }
    }

    func getCECreditsByCategory(from startDate: Date, to endDate: Date) -> [CECategory: Double] {
        let validCredits = getValidCECredits(from: startDate, to: endDate)
        var creditsByCategory: [CECategory: Double] = [:]

        for credit in validCredits {
            creditsByCategory[credit.category, default: 0] += credit.credits
        }

        return creditsByCategory
    }

    func getTotalCECost(from startDate: Date, to endDate: Date) -> Double {
        getValidCECredits(from: startDate, to: endDate)
            .compactMap { $0.cost }
            .reduce(0, +)
    }

    func getExpiredCertifications() -> [Certification] {
        certifications.filter { $0.isExpired }
    }

    func getCertificationsNeedingRenewal() -> [Certification] {
        certifications.filter { $0.needsRenewal }
    }

    func getActiveInsurance() -> [ProfessionalInsurance] {
        insurancePolicies.filter { !$0.isExpired }
    }

    func getExpiredInsurance() -> [ProfessionalInsurance] {
        insurancePolicies.filter { $0.isExpired }
    }

    func getInsuranceNeedingRenewal() -> [ProfessionalInsurance] {
        insurancePolicies.filter { $0.needsRenewal }
    }

    // MARK: - Compliance Checks

    func checkCECompliance(for state: String, renewalPeriodStart: Date) -> CEComplianceStatus {
        guard let requirements = stateRequirements.first(where: { $0.state == state }) else {
            return CEComplianceStatus(
                state: state,
                isCompliant: true,
                totalCreditsEarned: 0,
                totalCreditsRequired: 0,
                ethicsCreditsEarned: 0,
                ethicsCreditsRequired: 0,
                creditsNeeded: 0,
                periodStart: renewalPeriodStart,
                periodEnd: Date()
            )
        }

        let periodEnd = Date()
        let validCredits = getValidCECredits(from: renewalPeriodStart, to: periodEnd)
        let totalCredits = validCredits.reduce(0) { $0 + $1.credits }

        let ethicsCredits = validCredits
            .filter { $0.category == .ethics }
            .reduce(0) { $0 + $1.credits }

        let totalNeeded = max(0, requirements.totalCreditsRequired - totalCredits)
        let ethicsNeeded = max(0, (requirements.ethicsCreditsRequired ?? 0) - ethicsCredits)

        let isCompliant = totalCredits >= requirements.totalCreditsRequired &&
                         ethicsCredits >= (requirements.ethicsCreditsRequired ?? 0)

        return CEComplianceStatus(
            state: state,
            isCompliant: isCompliant,
            totalCreditsEarned: totalCredits,
            totalCreditsRequired: requirements.totalCreditsRequired,
            ethicsCreditsEarned: ethicsCredits,
            ethicsCreditsRequired: requirements.ethicsCreditsRequired ?? 0,
            creditsNeeded: totalNeeded,
            periodStart: renewalPeriodStart,
            periodEnd: periodEnd
        )
    }

    func getOverallComplianceStatus() -> OverallComplianceStatus {
        let totalLicenses = licenses.count
        let activeLicenses = getActiveLicenses().count
        let expiredLicenses = getExpiredLicenses().count
        let licensesNeedingRenewal = getLicensesNeedingRenewal().count

        let totalCertifications = certifications.count
        let expiredCertifications = getExpiredCertifications().count
        let certificationsNeedingRenewal = getCertificationsNeedingRenewal().count

        let totalInsurance = insurancePolicies.count
        let expiredInsurance = getExpiredInsurance().count
        let insuranceNeedingRenewal = getInsuranceNeedingRenewal().count

        let hasActiveLiability = insurancePolicies.contains { insurance in
            (insurance.insuranceType == .liability || insurance.insuranceType == .malpractice) &&
            !insurance.isExpired
        }

        let criticalIssues = expiredLicenses + (hasActiveLiability ? 0 : 1)

        return OverallComplianceStatus(
            totalLicenses: totalLicenses,
            activeLicenses: activeLicenses,
            expiredLicenses: expiredLicenses,
            licensesNeedingRenewal: licensesNeedingRenewal,
            totalCertifications: totalCertifications,
            expiredCertifications: expiredCertifications,
            certificationsNeedingRenewal: certificationsNeedingRenewal,
            totalInsurance: totalInsurance,
            expiredInsurance: expiredInsurance,
            insuranceNeedingRenewal: insuranceNeedingRenewal,
            hasActiveLiability: hasActiveLiability,
            criticalIssues: criticalIssues
        )
    }

    // MARK: - Alerts & Notifications

    func getUpcomingDeadlines(days: Int = 90) -> [ComplianceDeadline] {
        var deadlines: [ComplianceDeadline] = []
        let cutoffDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()

        // License renewals
        for license in licenses where license.expirationDate <= cutoffDate && !license.isExpired {
            deadlines.append(ComplianceDeadline(
                id: license.id,
                type: .licenseRenewal,
                name: "\(license.licenseType.rawValue) - \(license.state)",
                dueDate: license.expirationDate,
                priority: license.alertLevel == .critical ? .critical : (license.alertLevel == .urgent ? .high : .medium)
            ))
        }

        // Certification renewals
        for cert in certifications where cert.requiresRenewal, let expiration = cert.expirationDate,
            expiration <= cutoffDate && !cert.isExpired {
            deadlines.append(ComplianceDeadline(
                id: cert.id,
                type: .certificationRenewal,
                name: cert.name,
                dueDate: expiration,
                priority: cert.needsRenewal ? .high : .medium
            ))
        }

        // Insurance renewals
        for insurance in insurancePolicies where insurance.expirationDate <= cutoffDate && !insurance.isExpired {
            deadlines.append(ComplianceDeadline(
                id: insurance.id,
                type: .insuranceRenewal,
                name: "\(insurance.insuranceType.rawValue) - \(insurance.provider)",
                dueDate: insurance.expirationDate,
                priority: insurance.insuranceType == .liability || insurance.insuranceType == .malpractice ? .critical : .medium
            ))
        }

        return deadlines.sorted { $0.dueDate < $1.dueDate }
    }

    // MARK: - Default Requirements

    private func createDefaultRequirements() {
        guard stateRequirements.isEmpty else { return }

        // Add common state requirements
        let commonStates = [
            StateCERequirements(
                state: "California",
                renewalPeriod: .biennial,
                totalCreditsRequired: 24,
                ethicsCreditsRequired: 4,
                notes: "Must include 4 hours in ethics"
            ),
            StateCERequirements(
                state: "Texas",
                renewalPeriod: .biennial,
                totalCreditsRequired: 12,
                ethicsCreditsRequired: 2,
                notes: "Must include 2 hours in ethics or professional responsibility"
            ),
            StateCERequirements(
                state: "Florida",
                renewalPeriod: .biennial,
                totalCreditsRequired: 24,
                ethicsCreditsRequired: 2,
                notes: "Must include 2 hours in medical errors and 2 hours in HIV/AIDS"
            ),
            StateCERequirements(
                state: "New York",
                renewalPeriod: .triennial,
                totalCreditsRequired: 36,
                notes: "36 hours over 3 years"
            ),
            StateCERequirements(
                state: "Washington",
                renewalPeriod: .biennial,
                totalCreditsRequired: 24,
                ethicsCreditsRequired: 4,
                notes: "Must include 4 hours in ethics"
            )
        ]

        stateRequirements = commonStates
        saveRequirements()
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: licensesKey),
           let decoded = try? JSONDecoder().decode([ProfessionalLicense].self, from: data) {
            licenses = decoded
        }

        if let data = UserDefaults.standard.data(forKey: ceKey),
           let decoded = try? JSONDecoder().decode([ContinuingEducation].self, from: data) {
            ceCredits = decoded
        }

        if let data = UserDefaults.standard.data(forKey: certificationsKey),
           let decoded = try? JSONDecoder().decode([Certification].self, from: data) {
            certifications = decoded
        }

        if let data = UserDefaults.standard.data(forKey: insuranceKey),
           let decoded = try? JSONDecoder().decode([ProfessionalInsurance].self, from: data) {
            insurancePolicies = decoded
        }

        if let data = UserDefaults.standard.data(forKey: requirementsKey),
           let decoded = try? JSONDecoder().decode([StateCERequirements].self, from: data) {
            stateRequirements = decoded
        }
    }

    private func saveLicenses() {
        if let encoded = try? JSONEncoder().encode(licenses) {
            UserDefaults.standard.set(encoded, forKey: licensesKey)
        }
    }

    private func saveCECredits() {
        if let encoded = try? JSONEncoder().encode(ceCredits) {
            UserDefaults.standard.set(encoded, forKey: ceKey)
        }
    }

    private func saveCertifications() {
        if let encoded = try? JSONEncoder().encode(certifications) {
            UserDefaults.standard.set(encoded, forKey: certificationsKey)
        }
    }

    private func saveInsurance() {
        if let encoded = try? JSONEncoder().encode(insurancePolicies) {
            UserDefaults.standard.set(encoded, forKey: insuranceKey)
        }
    }

    private func saveRequirements() {
        if let encoded = try? JSONEncoder().encode(stateRequirements) {
            UserDefaults.standard.set(encoded, forKey: requirementsKey)
        }
    }
}

// MARK: - Supporting Types

struct CEComplianceStatus {
    let state: String
    let isCompliant: Bool
    let totalCreditsEarned: Double
    let totalCreditsRequired: Double
    let ethicsCreditsEarned: Double
    let ethicsCreditsRequired: Double
    let creditsNeeded: Double
    let periodStart: Date
    let periodEnd: Date

    var progressPercentage: Double {
        guard totalCreditsRequired > 0 else { return 100 }
        return min(100, (totalCreditsEarned / totalCreditsRequired) * 100)
    }
}

struct OverallComplianceStatus {
    let totalLicenses: Int
    let activeLicenses: Int
    let expiredLicenses: Int
    let licensesNeedingRenewal: Int

    let totalCertifications: Int
    let expiredCertifications: Int
    let certificationsNeedingRenewal: Int

    let totalInsurance: Int
    let expiredInsurance: Int
    let insuranceNeedingRenewal: Int

    let hasActiveLiability: Bool
    let criticalIssues: Int

    var isFullyCompliant: Bool {
        expiredLicenses == 0 &&
        expiredInsurance == 0 &&
        hasActiveLiability
    }
}

struct ComplianceDeadline: Identifiable {
    let id: UUID
    let type: DeadlineType
    let name: String
    let dueDate: Date
    let priority: Priority

    enum DeadlineType {
        case licenseRenewal
        case certificationRenewal
        case insuranceRenewal
        case ceDeadline
    }

    enum Priority {
        case low, medium, high, critical

        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }

    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }
}

import SwiftUI
