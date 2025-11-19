// TherapistSchedule.swift
// Manages therapist availability and working hours

import Foundation

/// Therapist's working schedule and availability
struct TherapistSchedule: Codable, Identifiable {

    // MARK: - Properties

    let id: UUID
    let therapistId: UUID

    /// Regular working hours for each day of the week
    var weeklyHours: [DayOfWeek: WorkingHours]

    /// Days off and time off periods
    var timeOff: [TimeOffPeriod]

    /// Breaks during the day
    var breaks: [BreakPeriod]

    /// Buffer time between appointments (in minutes)
    var bufferMinutes: Int

    /// Earliest appointment time allowed
    var earliestAppointmentTime: Date?

    /// Latest appointment time allowed
    var latestAppointmentTime: Date?

    // MARK: - Metadata

    let createdAt: Date
    var updatedAt: Date

    // MARK: - Initialization

    init(therapistId: UUID) {
        self.id = UUID()
        self.therapistId = therapistId
        self.weeklyHours = [:]
        self.timeOff = []
        self.breaks = []
        self.bufferMinutes = 15 // Default 15-minute buffer
        self.createdAt = Date()
        self.updatedAt = Date()

        // Set default working hours (Monday-Friday, 9am-5pm)
        setupDefaultSchedule()
    }

    // MARK: - Public Methods

    /// Check if therapist is available at a specific date/time
    /// - Parameters:
    ///   - date: The date/time to check
    ///   - durationMinutes: Duration of the appointment
    /// - Returns: True if available, false otherwise
    func isAvailable(at date: Date, for durationMinutes: Int) -> Bool {
        let calendar = Calendar.current

        // Check if it's a day off
        if isTimeOff(date) {
            return false
        }

        // Get day of week
        guard let dayOfWeek = DayOfWeek(rawValue: calendar.component(.weekday, from: date)) else {
            return false
        }

        // Check if therapist works on this day
        guard let workingHours = weeklyHours[dayOfWeek], workingHours.isWorking else {
            return false
        }

        // Get time components
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let timeInMinutes = hour * 60 + minute

        // Check if within working hours
        let startTimeInMinutes = workingHours.startHour * 60 + workingHours.startMinute
        let endTimeInMinutes = workingHours.endHour * 60 + workingHours.endMinute

        if timeInMinutes < startTimeInMinutes || timeInMinutes >= endTimeInMinutes {
            return false
        }

        // Check if appointment would end within working hours
        let appointmentEndTime = timeInMinutes + durationMinutes
        if appointmentEndTime > endTimeInMinutes {
            return false
        }

        // Check if it conflicts with a break
        for breakPeriod in breaks {
            if breakPeriod.isActive(on: date) && breakPeriod.conflictsWith(date, duration: durationMinutes) {
                return false
            }
        }

        return true
    }

    /// Get all available time slots for a given day
    /// - Parameters:
    ///   - date: The date to get slots for
    ///   - slotDuration: Duration of each slot in minutes
    /// - Returns: Array of available start times
    func availableSlots(on date: Date, slotDuration: Int) -> [Date] {
        var slots: [Date] = []
        let calendar = Calendar.current

        guard let dayOfWeek = DayOfWeek(rawValue: calendar.component(.weekday, from: date)),
              let workingHours = weeklyHours[dayOfWeek],
              workingHours.isWorking else {
            return slots
        }

        // Create date components for the day
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)

        // Start from working hours start time
        var currentTime = calendar.date(bySettingHour: workingHours.startHour,
                                       minute: workingHours.startMinute,
                                       second: 0,
                                       of: date) ?? date

        let endTime = calendar.date(bySettingHour: workingHours.endHour,
                                   minute: workingHours.endMinute,
                                   second: 0,
                                   of: date) ?? date

        // Generate slots with buffer time
        let totalSlotDuration = slotDuration + bufferMinutes

        while currentTime < endTime {
            // Check if this slot is available
            if isAvailable(at: currentTime, for: slotDuration) {
                slots.append(currentTime)
            }

            // Move to next slot
            currentTime = calendar.date(byAdding: .minute, value: totalSlotDuration, to: currentTime) ?? currentTime
        }

        return slots
    }

    /// Check if a date is during time off
    private func isTimeOff(_ date: Date) -> Bool {
        return timeOff.contains { $0.includes(date) }
    }

    /// Set up default Monday-Friday 9am-5pm schedule
    private mutating func setupDefaultSchedule() {
        let workingDay = WorkingHours(startHour: 9, startMinute: 0, endHour: 17, endMinute: 0)

        weeklyHours[.monday] = workingDay
        weeklyHours[.tuesday] = workingDay
        weeklyHours[.wednesday] = workingDay
        weeklyHours[.thursday] = workingDay
        weeklyHours[.friday] = workingDay
        weeklyHours[.saturday] = WorkingHours(isWorking: false)
        weeklyHours[.sunday] = WorkingHours(isWorking: false)
    }
}

// MARK: - Working Hours

/// Working hours for a specific day
struct WorkingHours: Codable {

    /// Is the therapist working on this day?
    var isWorking: Bool

    /// Start hour (24-hour format)
    var startHour: Int

    /// Start minute
    var startMinute: Int

    /// End hour (24-hour format)
    var endHour: Int

    /// End minute
    var endMinute: Int

    init(startHour: Int = 9, startMinute: Int = 0, endHour: Int = 17, endMinute: Int = 0) {
        self.isWorking = true
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
    }

    init(isWorking: Bool) {
        self.isWorking = isWorking
        self.startHour = 0
        self.startMinute = 0
        self.endHour = 0
        self.endMinute = 0
    }

    /// Total working minutes for this day
    var totalMinutes: Int {
        guard isWorking else { return 0 }
        let startInMinutes = startHour * 60 + startMinute
        let endInMinutes = endHour * 60 + endMinute
        return endInMinutes - startInMinutes
    }

    /// Display string (e.g., "9:00 AM - 5:00 PM")
    var displayString: String {
        guard isWorking else { return "Closed" }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let calendar = Calendar.current
        let today = Date()

        let startDate = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: today) ?? today
        let endDate = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: today) ?? today

        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

// MARK: - Time Off Period

/// A period when the therapist is not available
struct TimeOffPeriod: Codable, Identifiable {

    let id: UUID

    /// Start date of time off
    var startDate: Date

    /// End date of time off
    var endDate: Date

    /// Reason for time off
    var reason: String?

    /// Type of time off
    var type: TimeOffType

    init(startDate: Date, endDate: Date, type: TimeOffType = .vacation) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.type = type
    }

    /// Check if a date falls within this time off period
    func includes(_ date: Date) -> Bool {
        return date >= startDate && date <= endDate
    }

    /// Number of days off
    var durationInDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1
    }
}

/// Type of time off
enum TimeOffType: String, Codable, CaseIterable {
    case vacation = "Vacation"
    case sick = "Sick Leave"
    case conference = "Conference"
    case holiday = "Holiday"
    case personal = "Personal"
    case other = "Other"
}

// MARK: - Break Period

/// A break during the day
struct BreakPeriod: Codable, Identifiable {

    let id: UUID

    /// Which days this break applies to
    var daysOfWeek: [DayOfWeek]

    /// Start hour (24-hour format)
    var startHour: Int

    /// Start minute
    var startMinute: Int

    /// Duration in minutes
    var durationMinutes: Int

    /// Description of the break
    var description: String?

    init(daysOfWeek: [DayOfWeek], startHour: Int, startMinute: Int, durationMinutes: Int) {
        self.id = UUID()
        self.daysOfWeek = daysOfWeek
        self.startHour = startHour
        self.startMinute = startMinute
        self.durationMinutes = durationMinutes
    }

    /// Check if this break is active on a given date
    func isActive(on date: Date) -> Bool {
        let calendar = Calendar.current
        guard let dayOfWeek = DayOfWeek(rawValue: calendar.component(.weekday, from: date)) else {
            return false
        }
        return daysOfWeek.contains(dayOfWeek)
    }

    /// Check if this break conflicts with an appointment at a given time
    func conflictsWith(_ appointmentStart: Date, duration: Int) -> Bool {
        let calendar = Calendar.current

        // Get the break start time on the appointment date
        let breakStart = calendar.date(bySettingHour: startHour,
                                      minute: startMinute,
                                      second: 0,
                                      of: appointmentStart) ?? appointmentStart

        let breakEnd = calendar.date(byAdding: .minute, value: durationMinutes, to: breakStart) ?? breakStart
        let appointmentEnd = calendar.date(byAdding: .minute, value: duration, to: appointmentStart) ?? appointmentStart

        // Check for overlap
        return (appointmentStart < breakEnd && appointmentEnd > breakStart)
    }
}
