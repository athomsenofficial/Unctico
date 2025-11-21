import Foundation
import Combine

/// Repository for marketing automation data
@MainActor
class MarketingRepository: ObservableObject {
    static let shared = MarketingRepository()

    @Published var campaigns: [EmailCampaign] = []
    @Published var templates: [EmailTemplate] = []
    @Published var emailLogs: [EmailLog] = []
    @Published var automationRules: [AutomationRule] = []

    private let campaignsKey = "email_campaigns"
    private let templatesKey = "email_templates"
    private let emailLogsKey = "email_logs"
    private let automationRulesKey = "automation_rules"

    init() {
        loadData()
        if templates.isEmpty {
            initializeSampleData()
        }
    }

    // MARK: - Campaign Management

    func addCampaign(_ campaign: EmailCampaign) {
        campaigns.append(campaign)
        saveCampaigns()
    }

    func updateCampaign(_ campaign: EmailCampaign) {
        if let index = campaigns.firstIndex(where: { $0.id == campaign.id }) {
            var updatedCampaign = campaign
            updatedCampaign.lastModifiedDate = Date()
            campaigns[index] = updatedCampaign
            saveCampaigns()
        }
    }

    func deleteCampaign(_ campaign: EmailCampaign) {
        campaigns.removeAll { $0.id == campaign.id }
        saveCampaigns()
    }

    func getCampaign(id: UUID) -> EmailCampaign? {
        campaigns.first { $0.id == id }
    }

    func getActiveCampaigns() -> [EmailCampaign] {
        campaigns.filter { $0.isActive }
    }

    func getCampaignsByStatus(_ status: CampaignStatus) -> [EmailCampaign] {
        campaigns.filter { $0.status == status }
    }

    func getCampaignsByType(_ type: CampaignType) -> [EmailCampaign] {
        campaigns.filter { $0.campaignType == type }
    }

    func searchCampaigns(query: String) -> [EmailCampaign] {
        let lowercased = query.lowercased()
        return campaigns.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.description.lowercased().contains(lowercased) ||
            $0.tags.contains { $0.lowercased().contains(lowercased) }
        }
    }

    // MARK: - Template Management

    func addTemplate(_ template: EmailTemplate) {
        templates.append(template)
        saveTemplates()
    }

    func updateTemplate(_ template: EmailTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            var updatedTemplate = template
            updatedTemplate.lastModifiedDate = Date()
            templates[index] = updatedTemplate
            saveTemplates()
        }
    }

    func deleteTemplate(_ template: EmailTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
    }

    func getTemplate(id: UUID) -> EmailTemplate? {
        templates.first { $0.id == id }
    }

    func getTemplatesByCategory(_ category: TemplateCategory) -> [EmailTemplate] {
        templates.filter { $0.category == category }
    }

    func getDefaultTemplate(for category: TemplateCategory) -> EmailTemplate? {
        templates.first { $0.category == category && $0.isDefault }
    }

    func searchTemplates(query: String) -> [EmailTemplate] {
        let lowercased = query.lowercased()
        return templates.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.subject.lowercased().contains(lowercased)
        }
    }

    // MARK: - Email Log Management

    func addEmailLog(_ log: EmailLog) {
        emailLogs.append(log)
        saveEmailLogs()
    }

    func addEmailLogs(_ logs: [EmailLog]) {
        emailLogs.append(contentsOf: logs)
        saveEmailLogs()
    }

    func updateEmailLog(_ log: EmailLog) {
        if let index = emailLogs.firstIndex(where: { $0.id == log.id }) {
            emailLogs[index] = log
            saveEmailLogs()
        }
    }

    func getEmailLogs(campaignId: UUID) -> [EmailLog] {
        emailLogs.filter { $0.campaignId == campaignId }
    }

    func getEmailLogs(clientId: UUID) -> [EmailLog] {
        emailLogs.filter { $0.clientId == clientId }
    }

    func getRecentEmailLogs(limit: Int = 50) -> [EmailLog] {
        Array(emailLogs.sorted { $0.sentDate > $1.sentDate }.prefix(limit))
    }

    func deleteOldEmailLogs(olderThan days: Int = 90) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        emailLogs.removeAll { $0.sentDate < cutoffDate }
        saveEmailLogs()
    }

    // MARK: - Automation Rule Management

    func addAutomationRule(_ rule: AutomationRule) {
        automationRules.append(rule)
        saveAutomationRules()
    }

    func updateAutomationRule(_ rule: AutomationRule) {
        if let index = automationRules.firstIndex(where: { $0.id == rule.id }) {
            automationRules[index] = rule
            saveAutomationRules()
        }
    }

    func deleteAutomationRule(_ rule: AutomationRule) {
        automationRules.removeAll { $0.id == rule.id }
        saveAutomationRules()
    }

    func getActiveAutomationRules() -> [AutomationRule] {
        automationRules.filter { $0.isActive }
    }

    func getAutomationRules(for trigger: TriggerEvent) -> [AutomationRule] {
        automationRules.filter { $0.trigger == trigger && $0.isActive }
    }

    func incrementAutomationTrigger(ruleId: UUID) {
        if let index = automationRules.firstIndex(where: { $0.id == ruleId }) {
            automationRules[index].totalTriggered += 1
            automationRules[index].lastTriggeredDate = Date()
            saveAutomationRules()
        }
    }

    // MARK: - Combined Operations

    /// Send campaign and record results
    func sendCampaign(
        campaign: EmailCampaign,
        recipients: [Client]
    ) {
        let service = MarketingService.shared
        let (logs, metrics) = service.sendCampaign(campaign: campaign, recipients: recipients)

        // Save email logs
        addEmailLogs(logs)

        // Update campaign with metrics
        var updatedCampaign = campaign
        updatedCampaign.status = .completed
        updatedCampaign.sentDate = Date()
        updatedCampaign.completedDate = Date()

        // If A/B test, split metrics
        if let abTest = campaign.abTest {
            let (metricsA, metricsB) = service.splitABTestMetrics(logs: logs)
            var updatedTest = abTest
            updatedTest.metricsA = metricsA
            updatedTest.metricsB = metricsB
            updatedTest.endDate = Date()

            // Determine winner
            updatedTest.winner = service.determineABTestWinner(test: updatedTest)
            updatedCampaign.abTest = updatedTest

            // Overall metrics are combined
            updatedCampaign.metrics = metrics
        } else {
            updatedCampaign.metrics = metrics
        }

        updateCampaign(updatedCampaign)
    }

    /// Trigger automation for a client
    func triggerAutomation(
        client: Client,
        event: TriggerEvent,
        context: [String: Any] = [:]
    ) {
        let service = MarketingService.shared
        let rules = getAutomationRules(for: event)
        let triggerContext = TriggerContext(event: event, metadata: context)

        for rule in rules {
            if service.shouldTriggerAutomation(rule: rule, client: client, triggerContext: triggerContext) {
                // Calculate send date based on delay
                let sendDate = Calendar.current.date(byAdding: .minute, value: rule.delayMinutes, to: Date()) ?? Date()

                // Queue email
                let log = service.queueAutomationEmail(rule: rule, client: client, sendDate: sendDate)
                addEmailLog(log)

                // Increment trigger count
                incrementAutomationTrigger(ruleId: rule.id)
            }
        }
    }

    // MARK: - Statistics

    func getStatistics() -> MarketingStatistics {
        let service = MarketingService.shared
        return service.calculateMarketingStatistics(campaigns: campaigns)
    }

    func getBestPerformingCampaigns(by criteria: WinnerCriteria, limit: Int = 5) -> [EmailCampaign] {
        let service = MarketingService.shared
        return service.getBestPerformingCampaigns(campaigns: campaigns, by: criteria, limit: limit)
    }

    // MARK: - Persistence

    private func loadData() {
        if let campaignsData = UserDefaults.standard.data(forKey: campaignsKey),
           let decodedCampaigns = try? JSONDecoder().decode([EmailCampaign].self, from: campaignsData) {
            campaigns = decodedCampaigns
        }

        if let templatesData = UserDefaults.standard.data(forKey: templatesKey),
           let decodedTemplates = try? JSONDecoder().decode([EmailTemplate].self, from: templatesData) {
            templates = decodedTemplates
        }

        if let logsData = UserDefaults.standard.data(forKey: emailLogsKey),
           let decodedLogs = try? JSONDecoder().decode([EmailLog].self, from: logsData) {
            emailLogs = decodedLogs
        }

        if let rulesData = UserDefaults.standard.data(forKey: automationRulesKey),
           let decodedRules = try? JSONDecoder().decode([AutomationRule].self, from: rulesData) {
            automationRules = decodedRules
        }
    }

    private func saveCampaigns() {
        if let encoded = try? JSONEncoder().encode(campaigns) {
            UserDefaults.standard.set(encoded, forKey: campaignsKey)
        }
    }

    private func saveTemplates() {
        if let encoded = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(encoded, forKey: templatesKey)
        }
    }

    private func saveEmailLogs() {
        if let encoded = try? JSONEncoder().encode(emailLogs) {
            UserDefaults.standard.set(encoded, forKey: emailLogsKey)
        }
    }

    private func saveAutomationRules() {
        if let encoded = try? JSONEncoder().encode(automationRules) {
            UserDefaults.standard.set(encoded, forKey: automationRulesKey)
        }
    }

    // MARK: - Sample Data

    private func initializeSampleData() {
        // Create sample templates
        let welcomeTemplate = EmailTemplate(
            name: "Welcome Email",
            subject: "Welcome to {{practice_name}}, {{first_name}}!",
            previewText: "We're excited to have you as a client",
            body: """
            Hi {{first_name}},

            Welcome to our practice! We're thrilled to have you as a new client.

            We look forward to helping you feel your best. If you have any questions, please don't hesitate to reach out.

            Best regards,
            {{practice_name}}
            """,
            placeholders: ["first_name", "practice_name"],
            category: .welcome,
            isDefault: true
        )

        let birthdayTemplate = EmailTemplate(
            name: "Birthday Wishes",
            subject: "Happy Birthday, {{first_name}}! 🎉",
            previewText: "Celebrate your special day with us",
            body: """
            Happy Birthday, {{first_name}}!

            We hope you have a wonderful day! As a special gift, enjoy 20% off your next massage session when you book within the next week.

            Use code: BIRTHDAY20

            Wishing you a relaxing and rejuvenating year ahead!

            {{practice_name}}
            """,
            placeholders: ["first_name", "practice_name"],
            category: .birthday,
            isDefault: true
        )

        let reminderTemplate = EmailTemplate(
            name: "Appointment Reminder",
            subject: "Reminder: Your appointment tomorrow at {{appointment_time}}",
            previewText: "Looking forward to seeing you",
            body: """
            Hi {{first_name}},

            This is a friendly reminder about your upcoming appointment:

            Date: {{appointment_date}}
            Time: {{appointment_time}}
            Service: {{service_name}}

            Please arrive 10 minutes early to complete any necessary paperwork.

            If you need to reschedule, please let us know at least 24 hours in advance.

            See you soon!
            {{practice_name}}
            """,
            placeholders: ["first_name", "appointment_date", "appointment_time", "service_name", "practice_name"],
            category: .reminder,
            isDefault: true
        )

        let reEngagementTemplate = EmailTemplate(
            name: "We Miss You",
            subject: "We miss you, {{first_name}}!",
            previewText: "Come back and relax with us",
            body: """
            Hi {{first_name}},

            It's been a while since we've seen you, and we wanted to reach out!

            Your wellness is important to us, and we'd love to help you get back to feeling your best.

            Book your next appointment and receive 15% off any service.

            Use code: COMEBACK15

            We look forward to welcoming you back!

            {{practice_name}}
            """,
            placeholders: ["first_name", "practice_name"],
            category: .reEngagement,
            isDefault: true
        )

        let thankYouTemplate = EmailTemplate(
            name: "Thank You After Visit",
            subject: "Thank you for your visit, {{first_name}}!",
            previewText: "We hope you enjoyed your session",
            body: """
            Hi {{first_name}},

            Thank you for choosing us for your massage therapy needs. We hope you enjoyed your session and are feeling relaxed and rejuvenated.

            If you have any feedback or questions, please don't hesitate to reach out. We're always here to help!

            To maintain your wellness, consider booking your next appointment within the next 2-4 weeks.

            Thank you again!
            {{practice_name}}
            """,
            placeholders: ["first_name", "practice_name"],
            category: .thankyou,
            isDefault: true
        )

        templates = [welcomeTemplate, birthdayTemplate, reminderTemplate, reEngagementTemplate, thankYouTemplate]
        saveTemplates()

        // Create sample automation rule
        let welcomeRule = AutomationRule(
            name: "Welcome New Clients",
            description: "Send welcome email when a new client signs up",
            trigger: .newClient,
            template: welcomeTemplate,
            isActive: true,
            delayMinutes: 0
        )

        let birthdayRule = AutomationRule(
            name: "Birthday Greetings",
            description: "Send birthday wishes to clients on their birthday",
            trigger: .birthday,
            template: birthdayTemplate,
            isActive: true,
            delayMinutes: 480 // 8 AM on birthday
        )

        let reEngagementRule = AutomationRule(
            name: "Re-engage Dormant Clients",
            description: "Re-engage clients who haven't visited in 60 days",
            trigger: .inactivity60Days,
            template: reEngagementTemplate,
            isActive: true,
            delayMinutes: 0
        )

        automationRules = [welcomeRule, birthdayRule, reEngagementRule]
        saveAutomationRules()
    }
}
