// Appointment.swift
// Represents a scheduled massage therapy appointment

import Foundation

/// Represents a scheduled appointment between therapist and client
struct Appointment: Codable, Identifiable {

    // MARK: - Properties

    /// Unique identifier
    let id: UUID

    /// Client this appointment is for
    let clientId: UUID

    /// Therapist providing the service (for multi-therapist practices)
    var therapistId: UUID?

    /// Start date and time of appointment
    var startDateTime: Date

    /// Duration in minutes
    var durationMinutes: Int

    /// Type of service being provided
    var serviceType: ServiceType

    /// Current status of the appointment
    var status: AppointmentStatus

    /// Room or location (for practices with multiple rooms)
    var room: String?

    /// Notes about this specific appointment
    var notes: String?

    /// Price for this appointment
    var price: Decimal?

    // MARK: - Recurrence

    /// Is this a recurring appointment?
    var isRecurring: Bool

    /// Recurrence pattern (if recurring)
    var recurrencePattern: RecurrencePattern?

    /// Parent appointment ID (if this is part of a recurring series)
    var parentAppointmentId: UUID?

    // MARK: - Reminders

    /// Has reminder been sent?
    var reminderSent: Bool

    /// When was the reminder sent?
    var reminderSentAt: Date?

    /// Has client confirmed the appointment?
    var isConfirmed: Bool

    /// When was the appointment confirmed?
    var confirmedAt: Date?

    // MARK: - Completion

    /// Did client show up?
    var clientShowedUp: Bool?

    /// Is there a SOAP note for this appointment?
    var soapNoteId: UUID?

    /// Payment received for this appointment?
    var isPaid: Bool

    /// Invoice ID (if invoiced)
    var invoiceId: UUID?

    // MARK: - Metadata

    /// When this appointment was created
    let createdAt: Date

    /// When this appointment was last updated
    var updatedAt: Date

    /// Who created this appointment
    var createdBy: String?

    /// Cancellation reason (if cancelled)
    var cancellationReason: String?

    /// When was it cancelled
    var cancelledAt: Date?

    // MARK: - Initialization

    /// Create a new appointment
    /// - Parameters:
    ///   - clientId: ID of the client
    ///   - startDateTime: When the appointment starts
    ///   - durationMinutes: How long the appointment is
    ///   - serviceType: Type of massage service
    init(clientId: UUID, startDateTime: Date, durationMinutes: Int, serviceType: ServiceType) {
        self.id = UUID()
        self.clientId = clientId
        self.startDateTime = startDateTime
        self.durationMinutes = durationMinutes
        self.serviceType = serviceType
        self.status = .scheduled
        self.isRecurring = false
        self.reminderSent = false
        self.isConfirmed = false
        self.isPaid = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// End date and time of appointment
    var endDateTime: Date {
        return Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startDateTime) ?? startDateTime
    }

    /// Is this appointment in the past?
    var isPast: Bool {
        return endDateTime < Date()
    }

    /// Is this appointment today?
    var isToday: Bool {
        return Calendar.current.isDateInToday(startDateTime)
    }

    /// Is this appointment upcoming (future)?
    var isUpcoming: Bool {
        return startDateTime > Date()
    }

    /// Time until appointment (if upcoming)
    var timeUntilAppointment: TimeInterval? {
        guard isUpcoming else { return nil }
        return startDateTime.timeIntervalSinceNow
    }

    /// Should send reminder? (24 hours before, if not sent yet)
    var shouldSendReminder: Bool {
        guard !reminderSent, isUpcoming else { return false }

        let twentyFourHoursBefore = Calendar.current.date(byAdding: .hour, value: -24, to: startDateTime) ?? startDateTime
        return Date() >= twentyFourHoursBefore
    }

    /// Can this appointment be cancelled? (not already cancelled/completed)
    var canBeCancelled: Bool {
        return status != .cancelled && status != .completed && status != .noShow
    }

    /// Can this appointment be rescheduled?
    var canBeRescheduled: Bool {
        return canBeCancelled && isUpcoming
    }

    /// Display time range (e.g., "2:00 PM - 3:00 PM")
    var timeRangeDisplay: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: startDateTime)
        let end = formatter.string(from: endDateTime)
        return "\(start) - \(end)"
    }
}

// MARK: - Appointment Status

/// Status of an appointment
enum AppointmentStatus: String, Codable, CaseIterable {
    case scheduled = "Scheduled"
    case confirmed = "Confirmed"
    case checkedIn = "Checked In"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case noShow = "No Show"
    case rescheduled = "Rescheduled"

    /// Color for this status
    var color: String {
        switch self {
        case .scheduled:
            return "blue"
        case .confirmed:
            return "green"
        case .checkedIn:
            return "purple"
        case .inProgress:
            return "orange"
        case .completed:
            return "green"
        case .cancelled:
            return "red"
        case .noShow:
            return "red"
        case .rescheduled:
            return "yellow"
        }
    }

    /// Icon for this status
    var icon: String {
        switch self {
        case .scheduled:
            return "calendar"
        case .confirmed:
            return "checkmark.circle.fill"
        case .checkedIn:
            return "person.badge.clock.fill"
        case .inProgress:
            return "timer"
        case .completed:
            return "checkmark.seal.fill"
        case .cancelled:
            return "xmark.circle.fill"
        case .noShow:
            return "exclamationmark.triangle.fill"
        case .rescheduled:
            return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - Recurrence Pattern

/// Pattern for recurring appointments
struct RecurrencePattern: Codable {

    /// How often does it recur?
    var frequency: RecurrenceFrequency

    /// Every X weeks/months (e.g., every 2 weeks)
    var interval: Int

    /// Which days of the week (for weekly recurrence)
    var daysOfWeek: [DayOfWeek]?

    /// When does the recurrence end?
    var endType: RecurrenceEndType

    /// End date (if endType is .onDate)
    var endDate: Date?

    /// Number of occurrences (if endType is .afterOccurrences)
    var occurrenceCount: Int?

    init(frequency: RecurrenceFrequency, interval: Int = 1) {
        self.frequency = frequency
        self.interval = interval
        self.endType = .never
    }

    /// Get the next occurrence date after a given date
    func nextOccurrence(after date: Date) -> Date? {
        let calendar = Calendar.current

        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: interval, to: date)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: interval, to: date)
        case .biWeekly:
            return calendar.date(byAdding: .weekOfYear, value: 2 * interval, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: interval, to: date)
        case .custom:
            // Custom logic would go here
            return nil
        }
    }
}

/// How often an appointment recurs
enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biWeekly = "Every 2 Weeks"
    case monthly = "Monthly"
    case custom = "Custom"
}

/// Days of the week
enum DayOfWeek: Int, Codable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    var shortName: String {
        return String(name.prefix(3))
    }
}

/// When a recurrence should end
enum RecurrenceEndType: String, Codable {
    case never = "Never"
    case onDate = "On Date"
    case afterOccurrences = "After Occurrences"
}
