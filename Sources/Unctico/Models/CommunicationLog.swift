import Foundation

/// Log of all client communications for comprehensive record-keeping
struct CommunicationLog: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    let communicationType: CommunicationType
    let direction: Direction
    let timestamp: Date
    var subject: String
    var content: String
    var attachments: [Attachment]
    var followUpRequired: Bool
    var followUpDate: Date?
    var followUpCompleted: Bool
    var tags: [String]
    let createdBy: String // Therapist name

    init(
        id: UUID = UUID(),
        clientId: UUID,
        communicationType: CommunicationType,
        direction: Direction,
        timestamp: Date = Date(),
        subject: String,
        content: String,
        attachments: [Attachment] = [],
        followUpRequired: Bool = false,
        followUpDate: Date? = nil,
        followUpCompleted: Bool = false,
        tags: [String] = [],
        createdBy: String
    ) {
        self.id = id
        self.clientId = clientId
        self.communicationType = communicationType
        self.direction = direction
        self.timestamp = timestamp
        self.subject = subject
        self.content = content
        self.attachments = attachments
        self.followUpRequired = followUpRequired
        self.followUpDate = followUpDate
        self.followUpCompleted = followUpCompleted
        self.tags = tags
        self.createdBy = createdBy
    }
}

// MARK: - Communication Types

enum CommunicationType: String, Codable, CaseIterable {
    // Direct Communication
    case phoneCall = "Phone Call"
    case videoCall = "Video Call"
    case inPerson = "In-Person Conversation"
    case voicemail = "Voicemail"

    // Digital Communication
    case email = "Email"
    case sms = "Text Message (SMS)"
    case secureMessage = "Secure Message"
    case portalMessage = "Patient Portal Message"

    // Administrative
    case appointmentReminder = "Appointment Reminder"
    case appointmentConfirmation = "Appointment Confirmation"
    case appointmentCancellation = "Appointment Cancellation"
    case appointmentRescheduling = "Appointment Rescheduling"
    case followUpCall = "Follow-Up Call"

    // Documentation
    case consentForm = "Consent Form Sent/Received"
    case treatmentPlan = "Treatment Plan Shared"
    case homeExerciseProgram = "Home Exercise Program Sent"
    case referralLetter = "Referral Letter Sent"
    case progressReport = "Progress Report Shared"
    case invoice = "Invoice Sent"
    case receipt = "Receipt Sent"

    // Incidents
    case complaint = "Client Complaint"
    case concern = "Client Concern"
    case emergencyContact = "Emergency Contact"
    case adverseEvent = "Adverse Event Report"

    var category: CommunicationCategory {
        switch self {
        case .phoneCall, .videoCall, .inPerson, .voicemail:
            return .directCommunication
        case .email, .sms, .secureMessage, .portalMessage:
            return .digitalCommunication
        case .appointmentReminder, .appointmentConfirmation, .appointmentCancellation, .appointmentRescheduling, .followUpCall:
            return .administrative
        case .consentForm, .treatmentPlan, .homeExerciseProgram, .referralLetter, .progressReport, .invoice, .receipt:
            return .documentation
        case .complaint, .concern, .emergencyContact, .adverseEvent:
            return .incidents
        }
    }

    var icon: String {
        switch self {
        case .phoneCall: return "phone.fill"
        case .videoCall: return "video.fill"
        case .inPerson: return "person.2.fill"
        case .voicemail: return "phone.arrow.down.left.fill"
        case .email: return "envelope.fill"
        case .sms: return "message.fill"
        case .secureMessage: return "lock.shield.fill"
        case .portalMessage: return "mail.stack.fill"
        case .appointmentReminder: return "bell.fill"
        case .appointmentConfirmation: return "checkmark.circle.fill"
        case .appointmentCancellation: return "xmark.circle.fill"
        case .appointmentRescheduling: return "calendar.badge.clock"
        case .followUpCall: return "phone.arrow.up.right.fill"
        case .consentForm: return "doc.text.fill"
        case .treatmentPlan: return "list.clipboard.fill"
        case .homeExerciseProgram: return "figure.flexibility"
        case .referralLetter: return "doc.badge.arrow.up.fill"
        case .progressReport: return "chart.line.uptrend.xyaxis"
        case .invoice: return "dollarsign.circle.fill"
        case .receipt: return "receipt.fill"
        case .complaint: return "exclamationmark.bubble.fill"
        case .concern: return "exclamationmark.triangle.fill"
        case .emergencyContact: return "cross.circle.fill"
        case .adverseEvent: return "exclamationmark.shield.fill"
        }
    }

    var color: String {
        switch category {
        case .directCommunication: return "blue"
        case .digitalCommunication: return "purple"
        case .administrative: return "green"
        case .documentation: return "orange"
        case .incidents: return "red"
        }
    }
}

enum CommunicationCategory: String, Codable, CaseIterable {
    case directCommunication = "Direct Communication"
    case digitalCommunication = "Digital Communication"
    case administrative = "Administrative"
    case documentation = "Documentation"
    case incidents = "Incidents & Concerns"

    var icon: String {
        switch self {
        case .directCommunication: return "bubble.left.and.bubble.right.fill"
        case .digitalCommunication: return "envelope.badge.fill"
        case .administrative: return "calendar.badge.clock"
        case .documentation: return "folder.fill"
        case .incidents: return "exclamationmark.triangle.fill"
        }
    }
}

enum Direction: String, Codable {
    case incoming = "Incoming"
    case outgoing = "Outgoing"

    var icon: String {
        switch self {
        case .incoming: return "arrow.down.circle.fill"
        case .outgoing: return "arrow.up.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .incoming: return "green"
        case .outgoing: return "blue"
        }
    }
}

// MARK: - Attachments

struct Attachment: Identifiable, Codable {
    let id: UUID
    let filename: String
    let fileType: String
    let fileSize: Int // bytes
    let fileURL: URL?
    let thumbnailURL: URL?

    init(
        id: UUID = UUID(),
        filename: String,
        fileType: String,
        fileSize: Int,
        fileURL: URL? = nil,
        thumbnailURL: URL? = nil
    ) {
        self.id = id
        self.filename = filename
        self.fileType = fileType
        self.fileSize = fileSize
        self.fileURL = fileURL
        self.thumbnailURL = thumbnailURL
    }

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }

    var icon: String {
        switch fileType.lowercased() {
        case "pdf": return "doc.fill"
        case "jpg", "jpeg", "png", "heic": return "photo.fill"
        case "doc", "docx": return "doc.text.fill"
        case "xls", "xlsx": return "tablecells.fill"
        case "mp3", "wav", "m4a": return "waveform"
        case "mp4", "mov": return "video.fill"
        default: return "doc"
        }
    }
}

// MARK: - Communication Templates

struct CommunicationTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let communicationType: CommunicationType
    let subject: String
    var body: String
    var tags: [String]
    let placeholders: [String]

    init(
        id: UUID = UUID(),
        name: String,
        communicationType: CommunicationType,
        subject: String,
        body: String,
        tags: [String] = [],
        placeholders: [String] = CommunicationTemplate.defaultPlaceholders
    ) {
        self.id = id
        self.name = name
        self.communicationType = communicationType
        self.subject = subject
        self.body = body
        self.tags = tags
        self.placeholders = placeholders
    }

    static let defaultPlaceholders = [
        "{{clientFirstName}}",
        "{{clientLastName}}",
        "{{clientFullName}}",
        "{{therapistName}}",
        "{{practiceName}}",
        "{{practicePhone}}",
        "{{practiceEmail}}",
        "{{date}}",
        "{{time}}"
    ]

    /// Replace placeholders with actual values
    func render(with data: [String: String]) -> String {
        var rendered = body
        for (key, value) in data {
            rendered = rendered.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return rendered
    }
}

// MARK: - Template Library

extension CommunicationTemplate {
    static let templateLibrary: [CommunicationTemplate] = [
        // Follow-Up Call Templates
        CommunicationTemplate(
            name: "Post-Treatment Follow-Up",
            communicationType: .followUpCall,
            subject: "Follow-Up Call",
            body: """
            Called {{clientFirstName}} to check on progress after last session.

            Client reported:
            - [Note pain levels, any changes]
            - [Note functional improvements]
            - [Note any concerns or questions]

            Recommendations given:
            - [Continue with home exercises]
            - [Ice/heat protocol]
            - [Scheduling recommendations]

            Next appointment: [Date/Time or to be scheduled]
            """,
            tags: ["follow-up", "post-treatment"]
        ),

        // Email Templates
        CommunicationTemplate(
            name: "Welcome New Client",
            communicationType: .email,
            subject: "Welcome to {{practiceName}}!",
            body: """
            Dear {{clientFirstName}},

            Welcome to {{practiceName}}! We're excited to have you as a new client and look forward to supporting you on your wellness journey.

            Before your first appointment, please:
            • Complete the attached intake forms
            • Arrive 10 minutes early for paperwork
            • Bring a list of current medications
            • Wear comfortable, loose-fitting clothing

            Our cancellation policy requires 24 hours notice to avoid charges.

            If you have any questions before your appointment, please don't hesitate to reach out!

            📞 {{practicePhone}}
            ✉️ {{practiceEmail}}

            Looking forward to meeting you!

            Best regards,
            {{therapistName}}
            {{practiceName}}
            """,
            tags: ["welcome", "new-client", "intake"]
        ),

        CommunicationTemplate(
            name: "Missed Appointment Follow-Up",
            communicationType: .email,
            subject: "We Missed You Today",
            body: """
            Hi {{clientFirstName}},

            We noticed you weren't able to make your appointment today at {{time}}. We hope everything is okay!

            Life gets busy, and we understand. If you'd like to reschedule, we have the following times available:

            [List available times]

            Please let us know if you'd like to book one of these slots, or feel free to call us at {{practicePhone}} to discuss other options.

            We're here to support your wellness goals whenever you're ready!

            Take care,
            {{therapistName}}
            {{practiceName}}
            """,
            tags: ["missed-appointment", "reschedule"]
        ),

        // SMS Templates
        CommunicationTemplate(
            name: "Quick Check-In",
            communicationType: .sms,
            subject: "Check-in",
            body: """
            Hi {{clientFirstName}}, just checking in after your session. How are you feeling today? Any soreness or concerns? - {{therapistName}}
            """,
            tags: ["check-in", "post-treatment"]
        ),

        CommunicationTemplate(
            name: "Home Exercise Reminder",
            communicationType: .sms,
            subject: "Exercise Reminder",
            body: """
            Hi {{clientFirstName}}! Friendly reminder to do your home exercises today. Just 10 minutes can make a big difference! Let me know if you have questions. - {{therapistName}}
            """,
            tags: ["home-exercise", "reminder"]
        ),

        // Documentation Templates
        CommunicationTemplate(
            name: "Treatment Plan Sent",
            communicationType: .treatmentPlan,
            subject: "Treatment Plan Shared",
            body: """
            Shared comprehensive treatment plan with {{clientFullName}} via email.

            Plan includes:
            - Treatment frequency and duration
            - Expected outcomes and timeline
            - Home care recommendations
            - Red flags to watch for
            - Follow-up schedule

            Client acknowledged receipt and understanding of plan.
            Questions addressed: [List any questions/concerns]
            """,
            tags: ["treatment-plan", "documentation"]
        ),

        CommunicationTemplate(
            name: "Referral Letter Sent",
            communicationType: .referralLetter,
            subject: "Referral Letter Sent",
            body: """
            Sent referral letter to [Provider Name] regarding {{clientFullName}}.

            Reason for referral: [Specify reason]

            Letter included:
            - Clinical findings
            - Treatment provided
            - Specific concerns
            - Request for clearance/evaluation

            Copy provided to client: [Yes/No]
            Follow-up plan: [Specify]
            """,
            tags: ["referral", "documentation"]
        ),

        // Incident Templates
        CommunicationTemplate(
            name: "Client Concern Documentation",
            communicationType: .concern,
            subject: "Client Concern",
            body: """
            Client Concern Report

            Date/Time: {{date}} {{time}}
            Client: {{clientFullName}}
            Documented by: {{therapistName}}

            Nature of Concern:
            [Describe the concern raised by client]

            Details:
            [Provide specific details of the conversation]

            Action Taken:
            [Describe how the concern was addressed]

            Resolution:
            [Outcome and any follow-up needed]

            Client Satisfaction:
            [Note client's response to resolution]

            Follow-Up Required: [Yes/No]
            Follow-Up Date: [If applicable]
            """,
            tags: ["concern", "incident", "documentation"]
        ),

        CommunicationTemplate(
            name: "Adverse Event Report",
            communicationType: .adverseEvent,
            subject: "Adverse Event",
            body: """
            ADVERSE EVENT REPORT

            Date/Time of Event: {{date}} {{time}}
            Client: {{clientFullName}}
            Reported by: {{therapistName}}

            Description of Event:
            [Detailed description of what occurred]

            Client Symptoms/Response:
            [Document client's reaction and symptoms]

            Immediate Action Taken:
            [Steps taken to address the situation]

            Medical Attention Sought: [Yes/No]
            [If yes, where and when]

            Current Client Status:
            [Client's condition at time of documentation]

            Root Cause Analysis:
            [Potential factors that contributed]

            Prevention Measures:
            [Steps to prevent recurrence]

            Follow-Up Plan:
            [Ongoing monitoring and care plan]

            Client Acknowledgment: [Yes/No]
            """,
            tags: ["adverse-event", "incident", "safety", "documentation"]
        )
    ]

    static func getTemplates(for type: CommunicationType) -> [CommunicationTemplate] {
        return templateLibrary.filter { $0.communicationType == type }
    }

    static func search(_ query: String) -> [CommunicationTemplate] {
        let lowercased = query.lowercased()
        return templateLibrary.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.body.lowercased().contains(lowercased) ||
            $0.tags.contains { $0.lowercased().contains(lowercased) }
        }
    }
}

// MARK: - Communication Statistics

struct CommunicationStatistics {
    let totalCommunications: Int
    let byType: [CommunicationType: Int]
    let byCategory: [CommunicationCategory: Int]
    let pendingFollowUps: Int
    let averageResponseTime: TimeInterval?

    static func calculate(from logs: [CommunicationLog]) -> CommunicationStatistics {
        let byType = Dictionary(grouping: logs) { $0.communicationType }
            .mapValues { $0.count }

        let byCategory = Dictionary(grouping: logs) { $0.communicationType.category }
            .mapValues { $0.count }

        let pendingFollowUps = logs.filter { $0.followUpRequired && !$0.followUpCompleted }.count

        return CommunicationStatistics(
            totalCommunications: logs.count,
            byType: byType,
            byCategory: byCategory,
            pendingFollowUps: pendingFollowUps,
            averageResponseTime: nil // TODO: Calculate based on incoming/outgoing pairs
        )
    }
}
