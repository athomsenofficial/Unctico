import Foundation
import Combine

class InsuranceClaimRepository: ObservableObject {
    static let shared = InsuranceClaimRepository()

    @Published var claims: [InsuranceClaim] = []
    @Published var providers: [InsuranceProvider] = []

    private let claimsStorageKey = "insurance_claims"
    private let providersStorageKey = "insurance_providers"
    private let storage = LocalStorageManager.shared

    private init() {
        loadClaims()
        loadProviders()
    }

    // MARK: - Claims Management

    func addClaim(_ claim: InsuranceClaim) {
        claims.append(claim)
        saveClaims()
        print("✅ Insurance claim added: \(claim.claimNumber)")
    }

    func updateClaim(_ claim: InsuranceClaim) {
        if let index = claims.firstIndex(where: { $0.id == claim.id }) {
            var updatedClaim = claim
            updatedClaim.updatedAt = Date()
            claims[index] = updatedClaim
            saveClaims()
            print("✅ Insurance claim updated: \(claim.claimNumber)")
        }
    }

    func deleteClaim(_ claim: InsuranceClaim) {
        claims.removeAll { $0.id == claim.id }
        saveClaims()
        print("✅ Insurance claim deleted: \(claim.claimNumber)")
    }

    func getClaim(id: UUID) -> InsuranceClaim? {
        return claims.first { $0.id == id }
    }

    func getClaimsForClient(clientId: UUID) -> [InsuranceClaim] {
        return claims.filter { $0.clientId == clientId }
    }

    func getClaimsByStatus(_ status: ClaimStatus) -> [InsuranceClaim] {
        return claims.filter { $0.status == status }
    }

    func getClaimsInDateRange(_ dateRange: ClosedRange<Date>) -> [InsuranceClaim] {
        return claims.filter { dateRange.contains($0.dateOfService) }
    }

    // MARK: - Providers Management

    func addProvider(_ provider: InsuranceProvider) {
        providers.append(provider)
        saveProviders()
        print("✅ Insurance provider added: \(provider.name)")
    }

    func updateProvider(_ provider: InsuranceProvider) {
        if let index = providers.firstIndex(where: { $0.id == provider.id }) {
            var updatedProvider = provider
            updatedProvider.updatedAt = Date()
            providers[index] = updatedProvider
            saveProviders()
            print("✅ Insurance provider updated: \(provider.name)")
        }
    }

    func deleteProvider(_ provider: InsuranceProvider) {
        providers.removeAll { $0.id == provider.id }
        saveProviders()
        print("✅ Insurance provider deleted: \(provider.name)")
    }

    func getProvider(id: UUID) -> InsuranceProvider? {
        return providers.first { $0.id == id }
    }

    func getPreferredProviders() -> [InsuranceProvider] {
        return providers.filter { $0.isPreferred }
    }

    // MARK: - Analytics & Reporting

    func getTotalBilledAmount() -> Double {
        return claims.reduce(0) { $0 + $1.totalBilled }
    }

    func getTotalPaidAmount() -> Double {
        return claims.reduce(0) { $0 + ($1.paidAmount ?? 0) }
    }

    func getTotalOutstandingBalance() -> Double {
        return claims.reduce(0) { $0 + $1.outstandingBalance }
    }

    func getClaimsByStatusCount() -> [ClaimStatus: Int] {
        var statusCounts: [ClaimStatus: Int] = [:]
        for status in ClaimStatus.allCases {
            statusCounts[status] = claims.filter { $0.status == status }.count
        }
        return statusCounts
    }

    func getDenialRate() -> Double {
        guard !claims.isEmpty else { return 0 }
        let deniedCount = claims.filter { $0.status == .denied }.count
        return Double(deniedCount) / Double(claims.count)
    }

    func getAveragePaymentTime() -> TimeInterval {
        let paidClaims = claims.filter { $0.status == .paid && $0.dateSubmitted != nil }
        guard !paidClaims.isEmpty else { return 0 }

        let totalTime = paidClaims.reduce(0.0) { total, claim in
            guard let submitted = claim.dateSubmitted else { return total }
            return total + claim.updatedAt.timeIntervalSince(submitted)
        }

        return totalTime / Double(paidClaims.count)
    }

    // MARK: - Claim Status Management

    func submitClaim(_ claim: InsuranceClaim) {
        var updated = claim
        updated.status = .submitted
        updated.dateSubmitted = Date()
        updateClaim(updated)
    }

    func approveClaim(_ claim: InsuranceClaim, allowedAmount: Double, paidAmount: Double, patientResponsibility: Double) {
        var updated = claim
        updated.status = .paid
        updated.allowedAmount = allowedAmount
        updated.paidAmount = paidAmount
        updated.patientResponsibility = patientResponsibility
        updateClaim(updated)
    }

    func denyClaim(_ claim: InsuranceClaim, reason: String) {
        var updated = claim
        updated.status = .denied
        updated.denialReason = reason
        updateClaim(updated)
    }

    func appealClaim(_ claim: InsuranceClaim) {
        var updated = claim
        updated.status = .appealed
        updateClaim(updated)
    }

    // MARK: - Data Persistence

    private func loadClaims() {
        do {
            if let loaded = try? storage.load(key: claimsStorageKey, as: [InsuranceClaim].self) {
                self.claims = loaded
                print("✅ Loaded \(claims.count) insurance claims from storage")
            }
        }
    }

    private func saveClaims() {
        do {
            try storage.save(claims, key: claimsStorageKey)
        } catch {
            print("❌ Failed to save insurance claims: \(error)")
        }
    }

    private func loadProviders() {
        do {
            if let loaded = try? storage.load(key: providersStorageKey, as: [InsuranceProvider].self) {
                self.providers = loaded
                print("✅ Loaded \(providers.count) insurance providers from storage")
            } else {
                // Load default providers
                loadDefaultProviders()
            }
        }
    }

    private func saveProviders() {
        do {
            try storage.save(providers, key: providersStorageKey)
        } catch {
            print("❌ Failed to save insurance providers: \(error)")
        }
    }

    private func loadDefaultProviders() {
        let defaultProviders = [
            InsuranceProvider(
                name: "Blue Cross Blue Shield",
                payerId: "BCBS",
                phone: "1-800-555-0100",
                isPreferred: true
            ),
            InsuranceProvider(
                name: "United Healthcare",
                payerId: "UHC",
                phone: "1-800-555-0200",
                isPreferred: true
            ),
            InsuranceProvider(
                name: "Aetna",
                payerId: "AETNA",
                phone: "1-800-555-0300",
                isPreferred: false
            ),
            InsuranceProvider(
                name: "Cigna",
                payerId: "CIGNA",
                phone: "1-800-555-0400",
                isPreferred: false
            ),
            InsuranceProvider(
                name: "Humana",
                payerId: "HUMANA",
                phone: "1-800-555-0500",
                isPreferred: false
            )
        ]

        providers = defaultProviders
        saveProviders()
        print("✅ Loaded \(providers.count) default insurance providers")
    }

    // MARK: - Search & Filter

    func searchClaims(query: String) -> [InsuranceClaim] {
        guard !query.isEmpty else { return claims }

        return claims.filter { claim in
            claim.claimNumber.localizedCaseInsensitiveContains(query) ||
            (claim.authorizationNumber?.localizedCaseInsensitiveContains(query) ?? false) ||
            (claim.denialReason?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    func searchProviders(query: String) -> [InsuranceProvider] {
        guard !query.isEmpty else { return providers }

        return providers.filter { provider in
            provider.name.localizedCaseInsensitiveContains(query) ||
            provider.payerId.localizedCaseInsensitiveContains(query)
        }
    }
}
