import Foundation

/// Repository for managing digital intake forms
@MainActor
class IntakeFormRepository: ObservableObject {
    static let shared = IntakeFormRepository()

    @Published var forms: [IntakeForm] = []
    @Published var templates: [IntakeFormTemplate] = []

    private let formsKey = "unctico_intake_forms"
    private let templatesKey = "unctico_intake_templates"

    init() {
        loadData()
        createDefaultTemplates()
    }

    // MARK: - Form Management

    func createForm(from template: IntakeFormTemplate, for clientId: UUID, clientName: String) -> IntakeForm {
        let responses = template.questions.map { question in
            FormResponse(
                questionId: question.id,
                question: question.text,
                questionType: question.type,
                options: question.options,
                isRequired: question.isRequired
            )
        }

        let form = IntakeForm(
            clientId: clientId,
            clientName: clientName,
            formTemplateId: template.id,
            formName: template.name,
            status: .inProgress,
            responses: responses,
            version: template.version
        )

        forms.append(form)
        saveForms()
        return form
    }

    func updateForm(_ form: IntakeForm) {
        if let index = forms.firstIndex(where: { $0.id == form.id }) {
            forms[index] = form
            saveForms()
        }
    }

    func deleteForm(_ id: UUID) {
        forms.removeAll { $0.id == id }
        saveForms()
    }

    func completeForm(_ formId: UUID, signatureData: Data) {
        guard let index = forms.firstIndex(where: { $0.id == formId }) else { return }
        let form = forms[index]

        let completedForm = IntakeForm(
            id: form.id,
            clientId: form.clientId,
            clientName: form.clientName,
            formTemplateId: form.formTemplateId,
            formName: form.formName,
            createdDate: form.createdDate,
            completedDate: Date(),
            lastModified: Date(),
            status: .completed,
            responses: form.responses,
            signatureData: signatureData,
            signatureDate: Date(),
            version: form.version
        )

        forms[index] = completedForm
        saveForms()
    }

    func updateResponse(_ formId: UUID, questionId: UUID, answer: String) {
        guard let formIndex = forms.firstIndex(where: { $0.id == formId }) else { return }
        var form = forms[formIndex]

        guard let responseIndex = form.responses.firstIndex(where: { $0.questionId == questionId }) else { return }
        var response = form.responses[responseIndex]

        let updatedResponse = FormResponse(
            id: response.id,
            questionId: response.questionId,
            question: response.question,
            questionType: response.questionType,
            answer: answer,
            options: response.options,
            isRequired: response.isRequired,
            answeredDate: Date()
        )

        var updatedResponses = form.responses
        updatedResponses[responseIndex] = updatedResponse

        let updatedForm = IntakeForm(
            id: form.id,
            clientId: form.clientId,
            clientName: form.clientName,
            formTemplateId: form.formTemplateId,
            formName: form.formName,
            createdDate: form.createdDate,
            completedDate: form.completedDate,
            lastModified: Date(),
            status: form.status,
            responses: updatedResponses,
            signatureData: form.signatureData,
            signatureDate: form.signatureDate,
            version: form.version
        )

        forms[formIndex] = updatedForm
        saveForms()
    }

    // MARK: - Template Management

    func addTemplate(_ template: IntakeFormTemplate) {
        templates.append(template)
        saveTemplates()
    }

    func updateTemplate(_ template: IntakeFormTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            saveTemplates()
        }
    }

    func deleteTemplate(_ id: UUID) {
        templates.removeAll { $0.id == id && !$0.isDefault }
        saveTemplates()
    }

    func getDefaultTemplates() -> [IntakeFormTemplate] {
        templates.filter { $0.isDefault }
    }

    func getCustomTemplates() -> [IntakeFormTemplate] {
        templates.filter { !$0.isDefault }
    }

    func getActiveTemplates() -> [IntakeFormTemplate] {
        templates.filter { $0.isActive }
    }

    // MARK: - Query Functions

    func getForms(for clientId: UUID) -> [IntakeForm] {
        forms.filter { $0.clientId == clientId }
    }

    func getCompletedForms(for clientId: UUID) -> [IntakeForm] {
        forms.filter { $0.clientId == clientId && $0.status == .completed }
    }

    func getIncompleteForms() -> [IntakeForm] {
        forms.filter { $0.status == .inProgress || $0.status == .draft }
    }

    func getFormsByTemplate(_ templateId: UUID) -> [IntakeForm] {
        forms.filter { $0.formTemplateId == templateId }
    }

    func getRecentForms(limit: Int = 10) -> [IntakeForm] {
        Array(forms.sorted { $0.createdDate > $1.createdDate }.prefix(limit))
    }

    // MARK: - Statistics

    func getStatistics() -> IntakeFormStatistics {
        IntakeFormStatistics(
            totalForms: forms.count,
            completedForms: forms.filter { $0.status == .completed }.count,
            inProgressForms: forms.filter { $0.status == .inProgress }.count,
            draftForms: forms.filter { $0.status == .draft }.count,
            averageCompletionTime: calculateAverageCompletionTime(),
            totalTemplates: templates.count,
            activeTemplates: templates.filter { $0.isActive }.count
        )
    }

    private func calculateAverageCompletionTime() -> TimeInterval {
        let completedForms = forms.filter { $0.status == .completed && $0.completedDate != nil }
        guard !completedForms.isEmpty else { return 0 }

        let totalTime = completedForms.reduce(0.0) { sum, form in
            guard let completed = form.completedDate else { return sum }
            return sum + completed.timeIntervalSince(form.createdDate)
        }

        return totalTime / Double(completedForms.count)
    }

    func getCompletionRate() -> Double {
        guard !forms.isEmpty else { return 0 }
        let completed = forms.filter { $0.status == .completed }.count
        return Double(completed) / Double(forms.count) * 100
    }

    // MARK: - Default Templates

    private func createDefaultTemplates() {
        guard templates.isEmpty else { return }

        templates = [
            .generalMassageIntake(),
            .painAssessmentIntake(),
            .prenatalIntake()
        ]

        saveTemplates()
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: formsKey),
           let decoded = try? JSONDecoder().decode([IntakeForm].self, from: data) {
            forms = decoded
        }

        if let data = UserDefaults.standard.data(forKey: templatesKey),
           let decoded = try? JSONDecoder().decode([IntakeFormTemplate].self, from: data) {
            templates = decoded
        }
    }

    private func saveForms() {
        if let encoded = try? JSONEncoder().encode(forms) {
            UserDefaults.standard.set(encoded, forKey: formsKey)
        }
    }

    private func saveTemplates() {
        if let encoded = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(encoded, forKey: templatesKey)
        }
    }
}

// MARK: - Supporting Types

struct IntakeFormStatistics {
    let totalForms: Int
    let completedForms: Int
    let inProgressForms: Int
    let draftForms: Int
    let averageCompletionTime: TimeInterval
    let totalTemplates: Int
    let activeTemplates: Int

    var completionRate: Double {
        guard totalForms > 0 else { return 0 }
        return Double(completedForms) / Double(totalForms) * 100
    }

    var averageCompletionMinutes: Double {
        averageCompletionTime / 60
    }
}
