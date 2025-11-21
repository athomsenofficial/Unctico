import Foundation

/// Appointment reminder system with customizable templates
struct AppointmentReminder: Identifiable, Codable {
    let id: UUID
    let appointmentId: UUID
    let clientId: UUID
    let reminderType: ReminderType
    let deliveryMethod: DeliveryMethod
    let scheduledFor: Date
    var status: ReminderStatus
    let messageContent: String
    var sentAt: Date?
    var deliveryError: String?

    init(
        id: UUID = UUID(),
        appointmentId: UUID,
        clientId: UUID,
        reminderType: ReminderType,
        deliveryMethod: DeliveryMethod,
        scheduledFor: Date,
        status: ReminderStatus = .scheduled,
        messageContent: String,
        sentAt: Date? = nil,
        deliveryError: String? = nil
    ) {
        self.id = id
        self.appointmentId = appointmentId
        self.clientId = clientId
        self.reminderType = reminderType
        self.deliveryMethod = deliveryMethod
        self.scheduledFor = scheduledFor
        self.status = status
        self.messageContent = messageContent
        self.sentAt = sentAt
        self.deliveryError = deliveryError
    }
}

// MARK: - Reminder Types

enum ReminderType: String, Codable, CaseIterable {
    case appointmentConfirmation = "Appointment Confirmation"
    case dayBefore = "Day Before Reminder"
    case dayOf = "Day Of Reminder"
    case twoHoursBefore = "2 Hours Before"
    case followUp = "Post-Appointment Follow-Up"
    case missedAppointment = "Missed Appointment"
    case rescheduling = "Rescheduling Request"
    case cancellationConfirmation = "Cancellation Confirmation"
    case waitlistNotification = "Waitlist Opening"
    case birthdayGreeting = "Birthday Greeting"
    case anniversaryGreeting = "Client Anniversary"
    case seasonalPromotion = "Seasonal Promotion"
    case packageExpiring = "Package Expiring Soon"

    var defaultTiming: TimeInterval {
        switch self {
        case .appointmentConfirmation:
            return 0 // Immediate after booking
        case .dayBefore:
            return -24 * 3600 // 24 hours before
        case .dayOf:
            return -8 * 3600 // Morning of (8 AM)
        case .twoHoursBefore:
            return -2 * 3600 // 2 hours before
        case .followUp:
            return 24 * 3600 // Next day
        case .missedAppointment:
            return 2 * 3600 // 2 hours after
        case .rescheduling:
            return 0 // Immediate
        case .cancellationConfirmation:
            return 0 // Immediate
        case .waitlistNotification:
            return 0 // Immediate
        case .birthdayGreeting:
            return 0 // On birthday
        case .anniversaryGreeting:
            return 0 // On anniversary
        case .seasonalPromotion:
            return 0 // Campaign based
        case .packageExpiring:
            return -7 * 24 * 3600 // 7 days before
        }
    }

    var icon: String {
        switch self {
        case .appointmentConfirmation: return "checkmark.circle.fill"
        case .dayBefore: return "bell.fill"
        case .dayOf: return "calendar.badge.clock"
        case .twoHoursBefore: return "clock.fill"
        case .followUp: return "arrow.turn.up.right"
        case .missedAppointment: return "exclamationmark.triangle.fill"
        case .rescheduling: return "calendar.badge.exclamationmark"
        case .cancellationConfirmation: return "xmark.circle.fill"
        case .waitlistNotification: return "list.bullet.clipboard"
        case .birthdayGreeting: return "gift.fill"
        case .anniversaryGreeting: return "star.fill"
        case .seasonalPromotion: return "tag.fill"
        case .packageExpiring: return "hourglass.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .appointmentConfirmation: return "green"
        case .dayBefore, .dayOf, .twoHoursBefore: return "blue"
        case .followUp: return "purple"
        case .missedAppointment: return "red"
        case .rescheduling: return "orange"
        case .cancellationConfirmation: return "gray"
        case .waitlistNotification: return "teal"
        case .birthdayGreeting, .anniversaryGreeting: return "pink"
        case .seasonalPromotion: return "orange"
        case .packageExpiring: return "yellow"
        }
    }
}

enum DeliveryMethod: String, Codable, CaseIterable {
    case sms = "SMS"
    case email = "Email"
    case both = "SMS & Email"
    case inApp = "In-App Notification"

    var icon: String {
        switch self {
        case .sms: return "message.fill"
        case .email: return "envelope.fill"
        case .both: return "paperplane.fill"
        case .inApp: return "bell.badge.fill"
        }
    }
}

enum ReminderStatus: String, Codable {
    case scheduled = "Scheduled"
    case sent = "Sent"
    case failed = "Failed"
    case cancelled = "Cancelled"

    var color: String {
        switch self {
        case .scheduled: return "blue"
        case .sent: return "green"
        case .failed: return "red"
        case .cancelled: return "gray"
        }
    }
}

// MARK: - Message Templates

struct ReminderTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let reminderType: ReminderType
    let deliveryMethod: DeliveryMethod
    var subject: String // For email
    var messageBody: String
    var isDefault: Bool
    var placeholders: [String] // Available merge fields

    init(
        id: UUID = UUID(),
        name: String,
        reminderType: ReminderType,
        deliveryMethod: DeliveryMethod,
        subject: String = "",
        messageBody: String,
        isDefault: Bool = false,
        placeholders: [String] = ReminderTemplate.defaultPlaceholders
    ) {
        self.id = id
        self.name = name
        self.reminderType = reminderType
        self.deliveryMethod = deliveryMethod
        self.subject = subject
        self.messageBody = messageBody
        self.isDefault = isDefault
        self.placeholders = placeholders
    }

    static let defaultPlaceholders = [
        "{{clientFirstName}}",
        "{{clientLastName}}",
        "{{clientFullName}}",
        "{{appointmentDate}}",
        "{{appointmentTime}}",
        "{{appointmentDuration}}",
        "{{therapistName}}",
        "{{practiceName}}",
        "{{practicePhone}}",
        "{{practiceEmail}}",
        "{{practiceAddress}}",
        "{{serviceType}}",
        "{{cancelationPolicyHours}}"
    ]

    /// Replace placeholders with actual values
    func render(with data: [String: String]) -> String {
        var rendered = messageBody
        for (key, value) in data {
            rendered = rendered.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return rendered
    }
}

// MARK: - Template Library

extension ReminderTemplate {
    static let templateLibrary: [ReminderTemplate] = [
        // Appointment Confirmation
        ReminderTemplate(
            name: "Standard Appointment Confirmation",
            reminderType: .appointmentConfirmation,
            deliveryMethod: .both,
            subject: "Appointment Confirmed - {{practiceName}}",
            messageBody: """
            Hi {{clientFirstName}},

            Your massage appointment is confirmed!

            📅 Date: {{appointmentDate}}
            🕐 Time: {{appointmentTime}}
            ⏱️ Duration: {{appointmentDuration}}
            👤 Therapist: {{therapistName}}

            📍 Location:
            {{practiceName}}
            {{practiceAddress}}

            Please arrive 5-10 minutes early to complete any necessary paperwork.

            If you need to reschedule or cancel, please contact us at least {{cancelationPolicyHours}} hours in advance.

            📞 {{practicePhone}}
            ✉️ {{practiceEmail}}

            We look forward to seeing you!

            Best regards,
            {{practiceName}}
            """,
            isDefault: true
        ),

        // Day Before Reminder
        ReminderTemplate(
            name: "Day Before Reminder",
            reminderType: .dayBefore,
            deliveryMethod: .sms,
            subject: "Reminder: Appointment Tomorrow",
            messageBody: """
            Hi {{clientFirstName}}! This is a friendly reminder about your massage appointment tomorrow.

            📅 {{appointmentDate}} at {{appointmentTime}}
            👤 with {{therapistName}}
            ⏱️ {{appointmentDuration}}

            Please arrive 5-10 minutes early.

            Need to reschedule? Call us at {{practicePhone}}

            See you soon!
            {{practiceName}}
            """,
            isDefault: true
        ),

        // Day Of Reminder
        ReminderTemplate(
            name: "Day Of Reminder",
            reminderType: .dayOf,
            deliveryMethod: .sms,
            subject: "Today's Appointment",
            messageBody: """
            Good morning {{clientFirstName}}!

            Your massage appointment is TODAY:
            🕐 {{appointmentTime}}
            📍 {{practiceName}}

            See you soon!
            """,
            isDefault: true
        ),

        // 2 Hours Before
        ReminderTemplate(
            name: "2 Hours Before Reminder",
            reminderType: .twoHoursBefore,
            deliveryMethod: .sms,
            subject: "Appointment in 2 Hours",
            messageBody: """
            Hi {{clientFirstName}}! Your massage appointment with {{therapistName}} is in 2 hours ({{appointmentTime}}).

            📍 {{practiceAddress}}

            Looking forward to seeing you!
            """,
            isDefault: true
        ),

        // Follow-Up
        ReminderTemplate(
            name: "Post-Appointment Follow-Up",
            reminderType: .followUp,
            deliveryMethod: .email,
            subject: "How Are You Feeling? - {{practiceName}}",
            messageBody: """
            Hi {{clientFirstName}},

            Thank you for your visit yesterday! We hope you're feeling great after your {{serviceType}} session with {{therapistName}}.

            📝 A few reminders:
            • Stay hydrated to help flush out metabolic waste
            • You may experience some soreness - this is normal
            • Apply heat or ice as recommended
            • Continue with any prescribed stretches

            ❓ How are you feeling?
            We'd love to hear about your experience. Your feedback helps us provide the best care possible.

            📅 Ready to schedule your next appointment?
            Regular sessions help maintain your progress. Reply to this email or call us at {{practicePhone}}.

            Wishing you continued wellness!

            Best regards,
            {{therapistName}}
            {{practiceName}}
            {{practicePhone}}
            """,
            isDefault: true
        ),

        // Missed Appointment
        ReminderTemplate(
            name: "Missed Appointment",
            reminderType: .missedAppointment,
            deliveryMethod: .both,
            subject: "We Missed You Today",
            messageBody: """
            Hi {{clientFirstName}},

            We noticed you missed your scheduled appointment today at {{appointmentTime}}.

            We understand that things come up! If you'd like to reschedule, we have availability:

            Please contact us at:
            📞 {{practicePhone}}
            ✉️ {{practiceEmail}}

            We look forward to seeing you soon!

            Best regards,
            {{practiceName}}
            """,
            isDefault: true
        ),

        // Rescheduling
        ReminderTemplate(
            name: "Rescheduling Confirmation",
            reminderType: .rescheduling,
            deliveryMethod: .both,
            subject: "Appointment Rescheduled",
            messageBody: """
            Hi {{clientFirstName}},

            Your appointment has been successfully rescheduled!

            📅 New Date: {{appointmentDate}}
            🕐 New Time: {{appointmentTime}}
            👤 Therapist: {{therapistName}}

            If you have any questions, please contact us at {{practicePhone}}.

            Thank you!
            {{practiceName}}
            """,
            isDefault: true
        ),

        // Cancellation Confirmation
        ReminderTemplate(
            name: "Cancellation Confirmation",
            reminderType: .cancellationConfirmation,
            deliveryMethod: .both,
            subject: "Appointment Cancelled",
            messageBody: """
            Hi {{clientFirstName}},

            Your appointment on {{appointmentDate}} at {{appointmentTime}} has been cancelled as requested.

            📅 When you're ready to rebook, we'd love to see you!

            Contact us at:
            📞 {{practicePhone}}
            ✉️ {{practiceEmail}}

            Take care!
            {{practiceName}}
            """,
            isDefault: true
        ),

        // Birthday Greeting
        ReminderTemplate(
            name: "Birthday Greeting",
            reminderType: .birthdayGreeting,
            deliveryMethod: .email,
            subject: "Happy Birthday from {{practiceName}}! 🎉",
            messageBody: """
            Happy Birthday, {{clientFirstName}}! 🎂🎉

            On your special day, we want to say thank you for being such a valued client!

            🎁 Birthday Gift:
            Enjoy 20% off your next massage session when you book within the next 30 days!

            Use code: BIRTHDAY2024

            Treat yourself to some well-deserved relaxation!

            📞 {{practicePhone}} to schedule
            ✉️ {{practiceEmail}}

            Wishing you a wonderful year ahead!

            With gratitude,
            {{practiceName}}
            """,
            isDefault: true
        ),

        // Client Anniversary
        ReminderTemplate(
            name: "Client Anniversary",
            reminderType: .anniversaryGreeting,
            deliveryMethod: .email,
            subject: "Celebrating Your Wellness Journey! ⭐",
            messageBody: """
            Hi {{clientFirstName}},

            Can you believe it's been a year since your first visit to {{practiceName}}? ⭐

            We're so grateful to have been part of your wellness journey!

            🎉 As a thank you:
            Enjoy a complimentary 30-minute upgrade on your next session!

            Valid for the next 60 days.

            📞 Call us at {{practicePhone}} to schedule

            Here's to many more years of health and wellness together!

            With appreciation,
            {{therapistName}} & Team
            {{practiceName}}
            """,
            isDefault: true
        ),

        // Package Expiring
        ReminderTemplate(
            name: "Package Expiring Soon",
            reminderType: .packageExpiring,
            deliveryMethod: .both,
            subject: "Reminder: Your Package is Expiring Soon",
            messageBody: """
            Hi {{clientFirstName}},

            This is a friendly reminder that your massage package will expire in 7 days.

            You still have sessions remaining - don't lose them!

            📅 Book your appointment today:
            📞 {{practicePhone}}
            ✉️ {{practiceEmail}}

            We have flexible scheduling options available.

            Best regards,
            {{practiceName}}
            """,
            isDefault: true
        )
    ]

    /// Get default template for reminder type
    static func getDefaultTemplate(for type: ReminderType) -> ReminderTemplate? {
        return templateLibrary.first { $0.reminderType == type && $0.isDefault }
    }

    /// Get all templates for a reminder type
    static func getTemplates(for type: ReminderType) -> [ReminderTemplate] {
        return templateLibrary.filter { $0.reminderType == type }
    }

    /// Search templates
    static func search(_ query: String) -> [ReminderTemplate] {
        let lowercased = query.lowercased()
        return templateLibrary.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.messageBody.lowercased().contains(lowercased)
        }
    }
}

// MARK: - Reminder Settings

struct ReminderSettings: Codable {
    var enabledReminderTypes: Set<ReminderType>
    var defaultDeliveryMethod: DeliveryMethod
    var sendFromNumber: String?
    var sendFromEmail: String?
    var replyToEmail: String?
    var autoConfirmNewAppointments: Bool
    var sendFollowUpAfterHours: Int
    var cancelationPolicyHours: Int

    init(
        enabledReminderTypes: Set<ReminderType> = [
            .appointmentConfirmation,
            .dayBefore,
            .followUp
        ],
        defaultDeliveryMethod: DeliveryMethod = .sms,
        sendFromNumber: String? = nil,
        sendFromEmail: String? = nil,
        replyToEmail: String? = nil,
        autoConfirmNewAppointments: Bool = true,
        sendFollowUpAfterHours: Int = 24,
        cancelationPolicyHours: Int = 24
    ) {
        self.enabledReminderTypes = enabledReminderTypes
        self.defaultDeliveryMethod = defaultDeliveryMethod
        self.sendFromNumber = sendFromNumber
        self.sendFromEmail = sendFromEmail
        self.replyToEmail = replyToEmail
        self.autoConfirmNewAppointments = autoConfirmNewAppointments
        self.sendFollowUpAfterHours = sendFollowUpAfterHours
        self.cancelationPolicyHours = cancelationPolicyHours
    }
}
