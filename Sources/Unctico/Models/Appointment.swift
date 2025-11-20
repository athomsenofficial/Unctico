import Foundation

struct Appointment: Identifiable, Codable {
    let id: UUID
    var clientId: UUID
    var therapistId: String?
    var serviceType: ServiceType
    var startTime: Date
    var duration: TimeInterval
    var status: AppointmentStatus
    var notes: String?
    var roomNumber: String?
    var reminderSent: Bool
    var createdAt: Date
    var updatedAt: Date

    var endTime: Date {
        startTime.addingTimeInterval(duration)
    }

    init(
        id: UUID = UUID(),
        clientId: UUID,
        therapistId: String? = nil,
        serviceType: ServiceType,
        startTime: Date,
        duration: TimeInterval,
        status: AppointmentStatus = .scheduled,
        notes: String? = nil,
        roomNumber: String? = nil,
        reminderSent: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.clientId = clientId
        self.therapistId = therapistId
        self.serviceType = serviceType
        self.startTime = startTime
        self.duration = duration
        self.status = status
        self.notes = notes
        self.roomNumber = roomNumber
        self.reminderSent = reminderSent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum ServiceType: String, Codable, CaseIterable {
    case swedish = "Swedish Massage"
    case deepTissue = "Deep Tissue"
    case sports = "Sports Massage"
    case prenatal = "Prenatal Massage"
    case hotStone = "Hot Stone Massage"
    case aromatherapy = "Aromatherapy"
    case therapeutic = "Therapeutic Massage"
    case medical = "Medical Massage"

    var duration: TimeInterval {
        switch self {
        case .swedish, .deepTissue, .sports, .therapeutic:
            return 3600 // 60 minutes
        case .prenatal, .hotStone, .aromatherapy:
            return 5400 // 90 minutes
        case .medical:
            return 1800 // 30 minutes
        }
    }
}

enum AppointmentStatus: String, Codable, CaseIterable {
    case scheduled = "Scheduled"
    case confirmed = "Confirmed"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case noShow = "No Show"
}
