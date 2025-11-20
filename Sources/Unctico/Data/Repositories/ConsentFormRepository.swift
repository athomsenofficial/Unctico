import Foundation
import SwiftUI

/// Repository for managing digital consent forms
@MainActor
class ConsentFormRepository: ObservableObject {
    static let shared = ConsentFormRepository()

    @Published var forms: [ConsentForm] = []
    @Published var templates: [ConsentFormTemplate] = []

    private let storageKey = "unctico_consent_forms"
    private let templatesKey = "unctico_consent_templates"

    init() {
        loadForms()
        loadTemplates()
        createDefaultTemplatesIfNeeded()
    }

    // MARK: - Form Management

    /// Create a new consent form from a template
    func createForm(
        for clientId: UUID,
        clientName: String,
        formType: ConsentFormType,
        customContent: String? = nil
    ) -> ConsentForm {
        let content = customContent ?? formType.getDefaultTemplate(
            practiceName: "Your Practice",
            therapistName: "Licensed Therapist"
        )

        var expirationDate: Date? = nil
        if let period = formType.expirationPeriod {
            expirationDate = Calendar.current.date(byAdding: period, to: Date())
        }

        let form = ConsentForm(
            clientId: clientId,
            clientName: clientName,
            formType: formType,
            content: content,
            expirationDate: expirationDate
        )

        forms.append(form)
        saveForms()
        return form
    }

    /// Sign a consent form
    func signForm(
        _ formId: UUID,
        signatureData: Data,
        witnessName: String? = nil,
        witnessSignature: Data? = nil
    ) {
        guard let index = forms.firstIndex(where: { $0.id == formId }) else { return }

        var form = forms[index]
        let updatedForm = ConsentForm(
            id: form.id,
            clientId: form.clientId,
            clientName: form.clientName,
            formType: form.formType,
            version: form.version,
            content: form.content,
            signatureData: signatureData,
            signatureDate: Date(),
            isSigned: true,
            witnessName: witnessName,
            witnessSignature: witnessSignature,
            createdDate: form.createdDate,
            lastModifiedDate: Date(),
            expirationDate: form.expirationDate,
            isActive: form.isActive
        )

        forms[index] = updatedForm
        saveForms()
    }

    /// Update form content
    func updateForm(_ form: ConsentForm) {
        if let index = forms.firstIndex(where: { $0.id == form.id }) {
            forms[index] = form
            saveForms()
        }
    }

    /// Void a form
    func voidForm(_ formId: UUID) {
        guard let index = forms.firstIndex(where: { $0.id == formId }) else { return }
        var form = forms[index]
        let updatedForm = ConsentForm(
            id: form.id,
            clientId: form.clientId,
            clientName: form.clientName,
            formType: form.formType,
            version: form.version,
            content: form.content,
            signatureData: form.signatureData,
            signatureDate: form.signatureDate,
            isSigned: form.isSigned,
            witnessName: form.witnessName,
            witnessSignature: form.witnessSignature,
            createdDate: form.createdDate,
            lastModifiedDate: Date(),
            expirationDate: form.expirationDate,
            isActive: false
        )
        forms[index] = updatedForm
        saveForms()
    }

    /// Delete a form
    func deleteForm(_ formId: UUID) {
        forms.removeAll { $0.id == formId }
        saveForms()
    }

    // MARK: - Query Functions

    /// Get all forms for a client
    func getForms(for clientId: UUID) -> [ConsentForm] {
        forms.filter { $0.clientId == clientId }
    }

    /// Get forms by type
    func getForms(ofType type: ConsentFormType) -> [ConsentForm] {
        forms.filter { $0.formType == type }
    }

    /// Get signed forms
    func getSignedForms() -> [ConsentForm] {
        forms.filter { $0.isSigned }
    }

    /// Get unsigned forms
    func getUnsignedForms() -> [ConsentForm] {
        forms.filter { !$0.isSigned }
    }

    /// Get expired forms
    func getExpiredForms() -> [ConsentForm] {
        forms.filter { $0.isExpired }
    }

    /// Get forms needing renewal
    func getFormsNeedingRenewal() -> [ConsentForm] {
        forms.filter { $0.needsRenewal && !$0.isExpired }
    }

    /// Check if client has required forms
    func hasRequiredForms(for clientId: UUID) -> Bool {
        let clientForms = getForms(for: clientId)
        let requiredTypes: [ConsentFormType] = [
            .informedConsent,
            .privacyNotice,
            .liabilityWaiver
        ]

        for requiredType in requiredTypes {
            let hasForms = clientForms.contains { form in
                form.formType == requiredType &&
                form.isSigned &&
                !form.isExpired &&
                form.isActive
            }
            if !hasForms {
                return false
            }
        }

        return true
    }

    /// Get missing required forms for a client
    func getMissingRequiredForms(for clientId: UUID) -> [ConsentFormType] {
        let clientForms = getForms(for: clientId)
        let requiredTypes: [ConsentFormType] = [
            .informedConsent,
            .privacyNotice,
            .liabilityWaiver
        ]

        return requiredTypes.filter { requiredType in
            !clientForms.contains { form in
                form.formType == requiredType &&
                form.isSigned &&
                !form.isExpired &&
                form.isActive
            }
        }
    }

    // MARK: - Template Management

    /// Create default templates
    private func createDefaultTemplatesIfNeeded() {
        guard templates.isEmpty else { return }

        for formType in ConsentFormType.allCases {
            let template = ConsentFormTemplate(
                formType: formType,
                name: formType.rawValue,
                content: formType.getDefaultTemplate(
                    practiceName: "[Practice Name]",
                    therapistName: "[Therapist Name]"
                )
            )
            templates.append(template)
        }

        saveTemplates()
    }

    /// Create custom template
    func createCustomTemplate(
        formType: ConsentFormType,
        name: String,
        content: String
    ) {
        let template = ConsentFormTemplate(
            formType: formType,
            name: name,
            content: content,
            isCustom: true
        )
        templates.append(template)
        saveTemplates()
    }

    /// Update template
    func updateTemplate(_ template: ConsentFormTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            saveTemplates()
        }
    }

    /// Delete custom template
    func deleteTemplate(_ templateId: UUID) {
        templates.removeAll { $0.id == templateId && $0.isCustom }
        saveTemplates()
    }

    /// Get template by type
    func getTemplate(for formType: ConsentFormType) -> ConsentFormTemplate? {
        templates.first { $0.formType == formType && !$0.isCustom }
    }

    /// Get all custom templates
    func getCustomTemplates() -> [ConsentFormTemplate] {
        templates.filter { $0.isCustom }
    }

    // MARK: - PDF Export

    /// Generate PDF of signed form
    func generatePDF(for formId: UUID) -> Data? {
        guard let form = forms.first(where: { $0.id == formId }),
              form.isSigned else { return nil }

        // In production, implement actual PDF generation
        // For now, return a placeholder
        return Data()
    }

    /// Export all forms for a client
    func exportClientForms(clientId: UUID) -> Data? {
        let clientForms = getForms(for: clientId).filter { $0.isSigned }

        guard !clientForms.isEmpty else { return nil }

        // In production, implement PDF compilation
        return Data()
    }

    // MARK: - Statistics

    /// Get form statistics
    func getStatistics() -> FormStatistics {
        FormStatistics(
            totalForms: forms.count,
            signedForms: forms.filter { $0.isSigned }.count,
            unsignedForms: forms.filter { !$0.isSigned }.count,
            expiredForms: forms.filter { $0.isExpired }.count,
            formsNeedingRenewal: forms.filter { $0.needsRenewal }.count,
            formsByType: Dictionary(grouping: forms, by: { $0.formType })
                .mapValues { $0.count }
        )
    }

    // MARK: - Compliance Checks

    /// Check overall consent compliance
    func getComplianceStatus() -> ConsentComplianceStatus {
        let totalClients = Set(forms.map { $0.clientId }).count

        var clientsWithAllForms = 0
        var clientsMissingForms = 0
        var clientsWithExpiredForms = 0

        for clientId in Set(forms.map { $0.clientId }) {
            if hasRequiredForms(for: clientId) {
                clientsWithAllForms += 1
            } else {
                clientsMissingForms += 1
            }

            let clientForms = getForms(for: clientId)
            if clientForms.contains(where: { $0.isExpired }) {
                clientsWithExpiredForms += 1
            }
        }

        return ConsentComplianceStatus(
            totalClients: totalClients,
            clientsCompliant: clientsWithAllForms,
            clientsNonCompliant: clientsMissingForms,
            clientsWithExpiredForms: clientsWithExpiredForms,
            totalFormsExpired: forms.filter { $0.isExpired }.count,
            totalFormsNeedingRenewal: forms.filter { $0.needsRenewal }.count
        )
    }

    // MARK: - Persistence

    private func loadForms() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ConsentForm].self, from: data) {
            forms = decoded
        }
    }

    private func saveForms() {
        if let encoded = try? JSONEncoder().encode(forms) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadTemplates() {
        if let data = UserDefaults.standard.data(forKey: templatesKey),
           let decoded = try? JSONDecoder().decode([ConsentFormTemplate].self, from: data) {
            templates = decoded
        }
    }

    private func saveTemplates() {
        if let encoded = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(encoded, forKey: templatesKey)
        }
    }
}

// MARK: - Supporting Types

struct FormStatistics {
    let totalForms: Int
    let signedForms: Int
    let unsignedForms: Int
    let expiredForms: Int
    let formsNeedingRenewal: Int
    let formsByType: [ConsentFormType: Int]
}

struct ConsentComplianceStatus {
    let totalClients: Int
    let clientsCompliant: Int
    let clientsNonCompliant: Int
    let clientsWithExpiredForms: Int
    let totalFormsExpired: Int
    let totalFormsNeedingRenewal: Int

    var compliancePercentage: Double {
        guard totalClients > 0 else { return 0 }
        return Double(clientsCompliant) / Double(totalClients) * 100
    }

    var isFullyCompliant: Bool {
        clientsNonCompliant == 0 && totalFormsExpired == 0
    }
}
