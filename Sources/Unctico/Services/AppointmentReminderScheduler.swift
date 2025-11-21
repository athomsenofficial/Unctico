import SwiftUI
import Combine

/// Automated appointment reminder scheduler
@MainActor
class AppointmentReminderScheduler: ObservableObject {
    static let shared = AppointmentReminderScheduler()

    @Published var scheduledReminders: [ScheduledReminder] = []
    @Published var isEnabled = true

    private let remindersKey = "unctico_scheduled_reminders"
    private var timer: Timer?

    init() {
        loadReminders()
        startScheduler()
    }

    // MARK: - Scheduler

    func startScheduler() {
        // Check every hour for reminders to send
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.processReminders()
            }
        }

        // Also process immediately
        Task {
            await processReminders()
        }
    }

    func stopScheduler() {
        timer?.invalidate()
        timer = nil
    }

    /// Process pending reminders and send those that are due
    func processReminders() async {
        guard isEnabled else { return }

        let now = Date()
        let dueReminders = scheduledReminders.filter { reminder in
            reminder.status == .pending && reminder.sendDate <= now
        }

        for var reminder in dueReminders {
            do {
                // Create and send the message
                let message = createReminderMessage(for: reminder)
                let sent = try await CommunicationService.shared.sendMessage(message)

                // Update reminder status
                reminder.status = .sent
                reminder.sentDate = Date()
                reminder.messageId = sent.id

                updateReminder(reminder)

                AuditLogger.shared.log(
                    event: .notificationSent,
                    details: "Appointment reminder sent to \(reminder.clientName)"
                )
            } catch {
                reminder.status = .failed
                reminder.errorMessage = error.localizedDescription
                updateReminder(reminder)

                AuditLogger.shared.log(
                    event: .error,
                    details: "Failed to send reminder: \(error.localizedDescription)"
                )
            }
        }
    }

    // MARK: - Reminder Management

    /// Schedule a reminder for an appointment
    func scheduleReminder(
        appointmentId: UUID,
        clientId: UUID,
        clientName: String,
        appointmentDate: Date,
        appointmentTime: String,
        therapistName: String,
        recipientContact: String,
        channel: CommunicationChannel,
        sendBefore: ReminderTiming
    ) {
        let sendDate = calculateSendDate(appointmentDate: appointmentDate, timing: sendBefore)

        let reminder = ScheduledReminder(
            appointmentId: appointmentId,
            clientId: clientId,
            clientName: clientName,
            appointmentDate: appointmentDate,
            appointmentTime: appointmentTime,
            therapistName: therapistName,
            recipientContact: recipientContact,
            channel: channel,
            sendDate: sendDate,
            timing: sendBefore
        )

        scheduledReminders.append(reminder)
        saveReminders()

        AuditLogger.shared.log(
            event: .userAction,
            details: "Appointment reminder scheduled for \(clientName)"
        )
    }

    /// Schedule automated reminders for an appointment
    func scheduleAutomaticReminders(
        appointmentId: UUID,
        clientId: UUID,
        clientName: String,
        appointmentDate: Date,
        appointmentTime: String,
        therapistName: String,
        recipientEmail: String?,
        recipientPhone: String?,
        preferences: NotificationPreferences
    ) {
        // Schedule email reminders
        if let email = recipientEmail, preferences.emailEnabled {
            for timing in preferences.emailReminders {
                scheduleReminder(
                    appointmentId: appointmentId,
                    clientId: clientId,
                    clientName: clientName,
                    appointmentDate: appointmentDate,
                    appointmentTime: appointmentTime,
                    therapistName: therapistName,
                    recipientContact: email,
                    channel: .email,
                    sendBefore: timing
                )
            }
        }

        // Schedule SMS reminders
        if let phone = recipientPhone, preferences.smsEnabled {
            for timing in preferences.smsReminders {
                scheduleReminder(
                    appointmentId: appointmentId,
                    clientId: clientId,
                    clientName: clientName,
                    appointmentDate: appointmentDate,
                    appointmentTime: appointmentTime,
                    therapistName: therapistName,
                    recipientContact: phone,
                    channel: .sms,
                    sendBefore: timing
                )
            }
        }
    }

    func cancelReminders(for appointmentId: UUID) {
        scheduledReminders.removeAll { $0.appointmentId == appointmentId }
        saveReminders()
    }

    func updateReminder(_ reminder: ScheduledReminder) {
        if let index = scheduledReminders.firstIndex(where: { $0.id == reminder.id }) {
            scheduledReminders[index] = reminder
            saveReminders()
        }
    }

    // MARK: - Helper Methods

    private func calculateSendDate(appointmentDate: Date, timing: ReminderTiming) -> Date {
        switch timing {
        case .oneHourBefore:
            return appointmentDate.addingTimeInterval(-3600)
        case .fourHoursBefore:
            return appointmentDate.addingTimeInterval(-14400)
        case .oneDayBefore:
            return appointmentDate.addingTimeInterval(-86400)
        case .twoDaysBefore:
            return appointmentDate.addingTimeInterval(-172800)
        case .oneWeekBefore:
            return appointmentDate.addingTimeInterval(-604800)
        case .custom(let seconds):
            return appointmentDate.addingTimeInterval(-Double(seconds))
        }
    }

    private func createReminderMessage(for reminder: ScheduledReminder) -> CommunicationMessage {
        return CommunicationService.shared.createAppointmentReminder(
            clientId: reminder.clientId,
            clientName: reminder.clientName,
            recipientContact: reminder.recipientContact,
            appointmentDate: reminder.appointmentDate,
            appointmentTime: reminder.appointmentTime,
            therapistName: reminder.therapistName,
            channel: reminder.channel
        )
    }

    // MARK: - Persistence

    private func loadReminders() {
        if let data = UserDefaults.standard.data(forKey: remindersKey),
           let decoded = try? JSONDecoder().decode([ScheduledReminder].self, from: data) {
            scheduledReminders = decoded
        }
    }

    private func saveReminders() {
        if let encoded = try? JSONEncoder().encode(scheduledReminders) {
            UserDefaults.standard.set(encoded, forKey: remindersKey)
        }
    }
}

// MARK: - Models

struct ScheduledReminder: Identifiable, Codable {
    let id: UUID
    let appointmentId: UUID
    let clientId: UUID
    let clientName: String
    let appointmentDate: Date
    let appointmentTime: String
    let therapistName: String
    let recipientContact: String
    let channel: CommunicationChannel
    let sendDate: Date
    let timing: ReminderTiming
    var status: ReminderStatus
    var sentDate: Date?
    var messageId: UUID?
    var errorMessage: String?

    init(
        id: UUID = UUID(),
        appointmentId: UUID,
        clientId: UUID,
        clientName: String,
        appointmentDate: Date,
        appointmentTime: String,
        therapistName: String,
        recipientContact: String,
        channel: CommunicationChannel,
        sendDate: Date,
        timing: ReminderTiming,
        status: ReminderStatus = .pending
    ) {
        self.id = id
        self.appointmentId = appointmentId
        self.clientId = clientId
        self.clientName = clientName
        self.appointmentDate = appointmentDate
        self.appointmentTime = appointmentTime
        self.therapistName = therapistName
        self.recipientContact = recipientContact
        self.channel = channel
        self.sendDate = sendDate
        self.timing = timing
        self.status = status
    }
}

enum ReminderTiming: Codable, Equatable, Hashable {
    case oneHourBefore
    case fourHoursBefore
    case oneDayBefore
    case twoDaysBefore
    case oneWeekBefore
    case custom(seconds: Int)

    var displayName: String {
        switch self {
        case .oneHourBefore: return "1 hour before"
        case .fourHoursBefore: return "4 hours before"
        case .oneDayBefore: return "1 day before"
        case .twoDaysBefore: return "2 days before"
        case .oneWeekBefore: return "1 week before"
        case .custom(let seconds):
            let hours = seconds / 3600
            let days = hours / 24
            if days > 0 {
                return "\(days) day\(days > 1 ? "s" : "") before"
            } else {
                return "\(hours) hour\(hours > 1 ? "s" : "") before"
            }
        }
    }
}

enum ReminderStatus: String, Codable {
    case pending = "Pending"
    case sent = "Sent"
    case failed = "Failed"
    case cancelled = "Cancelled"

    var color: Color {
        switch self {
        case .pending: return .orange
        case .sent: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
}

struct NotificationPreferences: Codable {
    var emailEnabled: Bool = true
    var smsEnabled: Bool = true
    var pushEnabled: Bool = false

    var emailReminders: [ReminderTiming] = [.oneDayBefore]
    var smsReminders: [ReminderTiming] = [.oneDayBefore]

    var appointmentReminders: Bool = true
    var appointmentConfirmations: Bool = true
    var followUpMessages: Bool = true
    var promotionalMessages: Bool = false
    var birthdayGreetings: Bool = true

    init(
        emailEnabled: Bool = true,
        smsEnabled: Bool = true,
        pushEnabled: Bool = false,
        emailReminders: [ReminderTiming] = [.oneDayBefore],
        smsReminders: [ReminderTiming] = [.oneDayBefore],
        appointmentReminders: Bool = true,
        appointmentConfirmations: Bool = true,
        followUpMessages: Bool = true,
        promotionalMessages: Bool = false,
        birthdayGreetings: Bool = true
    ) {
        self.emailEnabled = emailEnabled
        self.smsEnabled = smsEnabled
        self.pushEnabled = pushEnabled
        self.emailReminders = emailReminders
        self.smsReminders = smsReminders
        self.appointmentReminders = appointmentReminders
        self.appointmentConfirmations = appointmentConfirmations
        self.followUpMessages = followUpMessages
        self.promotionalMessages = promotionalMessages
        self.birthdayGreetings = birthdayGreetings
    }
}

// MARK: - Bulk Campaign Support

struct MarketingCampaign: Identifiable, Codable {
    let id: UUID
    let name: String
    let channel: CommunicationChannel
    let messageType: MessageType
    let subject: String?
    let content: String
    let targetAudience: AudienceFilter
    let scheduledDate: Date?
    let status: CampaignStatus
    let createdDate: Date
    var sentCount: Int
    var openCount: Int
    var clickCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        channel: CommunicationChannel,
        messageType: MessageType,
        subject: String? = nil,
        content: String,
        targetAudience: AudienceFilter,
        scheduledDate: Date? = nil,
        status: CampaignStatus = .draft,
        createdDate: Date = Date(),
        sentCount: Int = 0,
        openCount: Int = 0,
        clickCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.channel = channel
        self.messageType = messageType
        self.subject = subject
        self.content = content
        self.targetAudience = targetAudience
        self.scheduledDate = scheduledDate
        self.status = status
        self.createdDate = createdDate
        self.sentCount = sentCount
        self.openCount = openCount
        self.clickCount = clickCount
    }

    var openRate: Double {
        guard sentCount > 0 else { return 0 }
        return Double(openCount) / Double(sentCount) * 100
    }

    var clickRate: Double {
        guard sentCount > 0 else { return 0 }
        return Double(clickCount) / Double(sentCount) * 100
    }
}

enum CampaignStatus: String, Codable {
    case draft = "Draft"
    case scheduled = "Scheduled"
    case sending = "Sending"
    case sent = "Sent"
    case paused = "Paused"
    case cancelled = "Cancelled"

    var color: Color {
        switch self {
        case .draft: return .gray
        case .scheduled: return .blue
        case .sending: return .orange
        case .sent: return .green
        case .paused: return .yellow
        case .cancelled: return .red
        }
    }
}

enum AudienceFilter: Codable {
    case all
    case lastVisit(daysAgo: Int)
    case neverVisited
    case birthday(month: Int)
    case custom(criteria: String)

    var description: String {
        switch self {
        case .all:
            return "All clients"
        case .lastVisit(let days):
            return "Clients who visited in last \(days) days"
        case .neverVisited:
            return "Clients who never visited"
        case .birthday(let month):
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            let date = Calendar.current.date(from: DateComponents(month: month)) ?? Date()
            return "Clients with birthdays in \(formatter.string(from: date))"
        case .custom(let criteria):
            return criteria
        }
    }
}

enum ReviewPlatform: String, Codable {
    case google = "Google"
    case yelp = "Yelp"
    case facebook = "Facebook"
    case custom = "Custom"
}
