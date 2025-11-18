// Appointment.swift
// Model for scheduling appointments
// QA Note: Represents a scheduled massage session

import Foundation

/// Appointment for a massage session
struct Appointment: Identifiable, Codable {

    // MARK: - Basic Information

    let id: UUID
    var clientId: UUID
    var therapistId: UUID
    var startTime: Date
    var endTime: Date
    var duration: Int  // in minutes

    // MARK: - Service Details

    var serviceType: ServiceType
    var roomId: UUID?
    var status: AppointmentStatus

    // MARK: - Notes

    var notes: String
    var clientNotes: String  // Notes from client
    var internalNotes: String  // Private staff notes

    // MARK: - Reminders

    var reminderSent: Bool
    var reminderDate: Date?

    // MARK: - Financial

    var price: Decimal
    var paid: Bool
    var paymentMethod: PaymentMethod?

    // MARK: - Computed Properties

    /// Is this appointment in the future?
    var isFuture: Bool {
        startTime > Date()
    }

    /// Is this appointment today?
    var isToday: Bool {
        Calendar.current.isDateInToday(startTime)
    }

    /// Is this appointment happening right now?
    var isNow: Bool {
        let now = Date()
        return now >= startTime && now <= endTime
    }

    init(
        id: UUID = UUID(),
        clientId: UUID,
        therapistId: UUID,
        startTime: Date,
        duration: Int = 60,
        serviceType: ServiceType,
        price: Decimal = 0
    ) {
        self.id = id
        self.clientId = clientId
        self.therapistId = therapistId
        self.startTime = startTime
        self.duration = duration
        self.endTime = Calendar.current.date(byAdding: .minute, value: duration, to: startTime) ?? startTime
        self.serviceType = serviceType
        self.status = .scheduled
        self.notes = ""
        self.clientNotes = ""
        self.internalNotes = ""
        self.reminderSent = false
        self.price = price
        self.paid = false
    }
}

/// Type of massage service
enum ServiceType: String, Codable, CaseIterable {
    case swedish60 = "Swedish Massage (60 min)"
    case swedish90 = "Swedish Massage (90 min)"
    case deepTissue60 = "Deep Tissue (60 min)"
    case deepTissue90 = "Deep Tissue (90 min)"
    case sports60 = "Sports Massage (60 min)"
    case prenatal60 = "Prenatal Massage (60 min)"
    case hotStone75 = "Hot Stone (75 min)"
    case couples90 = "Couples Massage (90 min)"
    case custom = "Custom Session"

    /// Default duration for this service type
    var defaultDuration: Int {
        switch self {
        case .swedish60, .deepTissue60, .sports60, .prenatal60:
            return 60
        case .hotStone75:
            return 75
        case .swedish90, .deepTissue90, .couples90:
            return 90
        case .custom:
            return 60
        }
    }
}

/// Status of the appointment
enum AppointmentStatus: String, Codable, CaseIterable {
    case scheduled = "Scheduled"
    case confirmed = "Confirmed"
    case checkedIn = "Checked In"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case noShow = "No Show"
    case rescheduled = "Rescheduled"

    /// Color to display for this status
    var color: String {
        switch self {
        case .scheduled:
            return "blue"
        case .confirmed:
            return "green"
        case .checkedIn, .inProgress:
            return "purple"
        case .completed:
            return "gray"
        case .cancelled, .noShow:
            return "red"
        case .rescheduled:
            return "orange"
        }
    }
}

/// How payment was made
enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "Cash"
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case check = "Check"
    case venmo = "Venmo"
    case zelle = "Zelle"
    case insurance = "Insurance"
    case giftCertificate = "Gift Certificate"
    case package = "Package/Membership"
}
