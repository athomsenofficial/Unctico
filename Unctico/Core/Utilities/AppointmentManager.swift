// AppointmentManager.swift
// Manages appointment booking, conflicts, and scheduling logic

import Foundation
import SwiftUI

/// Manages all appointment operations
/// Use this for booking, cancelling, rescheduling appointments
class AppointmentManager: ObservableObject {

    // MARK: - Published Properties

    /// All appointments (in-memory for now, will connect to Core Data)
    @Published var appointments: [Appointment] = []

    /// Therapist schedule
    @Published var schedule: TherapistSchedule?

    /// Is loading?
    @Published var isLoading: Bool = false

    /// Error message
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let databaseManager: DatabaseManager

    // MARK: - Initialization

    init(databaseManager: DatabaseManager = DatabaseManager()) {
        self.databaseManager = databaseManager
        loadAppointments()
    }

    // MARK: - Public Methods

    /// Load all appointments from database
    func loadAppointments() {
        // TODO: Load from Core Data
        // For now, using in-memory array
    }

    /// Book a new appointment
    /// - Parameters:
    ///   - clientId: Client ID
    ///   - startDateTime: When the appointment starts
    ///   - durationMinutes: How long the appointment is
    ///   - serviceType: Type of service
    /// - Returns: The created appointment, or nil if booking failed
    func bookAppointment(
        clientId: UUID,
        startDateTime: Date,
        durationMinutes: Int,
        serviceType: ServiceType
    ) -> Appointment? {

        // Check for conflicts
        if hasConflict(at: startDateTime, duration: durationMinutes) {
            errorMessage = "This time slot conflicts with another appointment"
            return nil
        }

        // Check therapist availability
        if let schedule = schedule {
            if !schedule.isAvailable(at: startDateTime, for: durationMinutes) {
                errorMessage = "Therapist is not available at this time"
                return nil
            }
        }

        // Create the appointment
        var appointment = Appointment(
            clientId: clientId,
            startDateTime: startDateTime,
            durationMinutes: durationMinutes,
            serviceType: serviceType
        )

        // Add to appointments list
        appointments.append(appointment)

        // TODO: Save to Core Data
        errorMessage = nil
        return appointment
    }

    /// Check if there's a conflict at a specific time
    /// - Parameters:
    ///   - date: The start time to check
    ///   - duration: Duration in minutes
    ///   - excludeAppointmentId: Appointment ID to exclude (for rescheduling)
    /// - Returns: True if there's a conflict
    func hasConflict(at date: Date, duration: Int, excludeAppointmentId: UUID? = nil) -> Bool {
        let endDate = Calendar.current.date(byAdding: .minute, value: duration, to: date) ?? date

        for appointment in appointments {
            // Skip the excluded appointment (used when rescheduling)
            if let excludeId = excludeAppointmentId, appointment.id == excludeId {
                continue
            }

            // Skip cancelled or no-show appointments
            if appointment.status == .cancelled || appointment.status == .noShow {
                continue
            }

            // Check for overlap
            if date < appointment.endDateTime && endDate > appointment.startDateTime {
                return true
            }
        }

        return false
    }

    /// Get appointments for a specific date
    /// - Parameter date: The date to get appointments for
    /// - Returns: Array of appointments on that date
    func appointments(on date: Date) -> [Appointment] {
        let calendar = Calendar.current

        return appointments.filter { appointment in
            calendar.isDate(appointment.startDateTime, inSameDayAs: date)
        }.sorted { $0.startDateTime < $1.startDateTime }
    }

    /// Get appointments for a date range
    /// - Parameters:
    ///   - startDate: Start of range
    ///   - endDate: End of range
    /// - Returns: Array of appointments in the range
    func appointments(from startDate: Date, to endDate: Date) -> [Appointment] {
        return appointments.filter { appointment in
            appointment.startDateTime >= startDate && appointment.startDateTime <= endDate
        }.sorted { $0.startDateTime < $1.startDateTime }
    }

    /// Get upcoming appointments
    /// - Parameter limit: Maximum number of appointments to return
    /// - Returns: Array of upcoming appointments
    func upcomingAppointments(limit: Int = 10) -> [Appointment] {
        return appointments
            .filter { $0.isUpcoming }
            .sorted { $0.startDateTime < $1.startDateTime }
            .prefix(limit)
            .map { $0 }
    }

    /// Get appointments that need reminders sent
    /// - Returns: Array of appointments needing reminders
    func appointmentsNeedingReminders() -> [Appointment] {
        return appointments.filter { $0.shouldSendReminder }
    }

    /// Cancel an appointment
    /// - Parameters:
    ///   - appointmentId: ID of appointment to cancel
    ///   - reason: Reason for cancellation
    func cancelAppointment(_ appointmentId: UUID, reason: String? = nil) {
        guard let index = appointments.firstIndex(where: { $0.id == appointmentId }) else {
            errorMessage = "Appointment not found"
            return
        }

        appointments[index].status = .cancelled
        appointments[index].cancellationReason = reason
        appointments[index].cancelledAt = Date()
        appointments[index].updatedAt = Date()

        // TODO: Save to Core Data
        errorMessage = nil
    }

    /// Reschedule an appointment
    /// - Parameters:
    ///   - appointmentId: ID of appointment to reschedule
    ///   - newStartDateTime: New start time
    func rescheduleAppointment(_ appointmentId: UUID, to newStartDateTime: Date) -> Bool {
        guard let index = appointments.firstIndex(where: { $0.id == appointmentId }) else {
            errorMessage = "Appointment not found"
            return false
        }

        let appointment = appointments[index]

        // Check for conflicts (excluding this appointment)
        if hasConflict(at: newStartDateTime, duration: appointment.durationMinutes, excludeAppointmentId: appointmentId) {
            errorMessage = "New time slot conflicts with another appointment"
            return false
        }

        // Update the appointment
        appointments[index].startDateTime = newStartDateTime
        appointments[index].updatedAt = Date()
        appointments[index].reminderSent = false // Reset reminder
        appointments[index].reminderSentAt = nil

        // TODO: Save to Core Data
        errorMessage = nil
        return true
    }

    /// Confirm an appointment
    /// - Parameter appointmentId: ID of appointment to confirm
    func confirmAppointment(_ appointmentId: UUID) {
        guard let index = appointments.firstIndex(where: { $0.id == appointmentId }) else {
            return
        }

        appointments[index].isConfirmed = true
        appointments[index].confirmedAt = Date()
        appointments[index].status = .confirmed
        appointments[index].updatedAt = Date()

        // TODO: Save to Core Data
    }

    /// Mark appointment as in progress
    /// - Parameter appointmentId: ID of appointment
    func startAppointment(_ appointmentId: UUID) {
        guard let index = appointments.firstIndex(where: { $0.id == appointmentId }) else {
            return
        }

        appointments[index].status = .inProgress
        appointments[index].updatedAt = Date()

        // TODO: Save to Core Data
    }

    /// Complete an appointment
    /// - Parameters:
    ///   - appointmentId: ID of appointment
    ///   - clientShowedUp: Did the client show up?
    func completeAppointment(_ appointmentId: UUID, clientShowedUp: Bool = true) {
        guard let index = appointments.firstIndex(where: { $0.id == appointmentId }) else {
            return
        }

        if clientShowedUp {
            appointments[index].status = .completed
            appointments[index].clientShowedUp = true
        } else {
            appointments[index].status = .noShow
            appointments[index].clientShowedUp = false
        }

        appointments[index].updatedAt = Date()

        // TODO: Save to Core Data
    }

    /// Create recurring appointments
    /// - Parameters:
    ///   - clientId: Client ID
    ///   - firstAppointment: Details of the first appointment
    ///   - pattern: Recurrence pattern
    /// - Returns: Array of created appointments
    func createRecurringAppointments(
        clientId: UUID,
        firstAppointment: Appointment,
        pattern: RecurrencePattern
    ) -> [Appointment] {

        var createdAppointments: [Appointment] = []
        var currentDate = firstAppointment.startDateTime

        // Create the parent appointment
        var parentAppointment = firstAppointment
        parentAppointment.isRecurring = true
        parentAppointment.recurrencePattern = pattern
        appointments.append(parentAppointment)
        createdAppointments.append(parentAppointment)

        // Determine how many occurrences to create
        var occurrencesCreated = 0
        let maxOccurrences: Int

        switch pattern.endType {
        case .never:
            maxOccurrences = 52 // Create 1 year worth by default
        case .afterOccurrences:
            maxOccurrences = pattern.occurrenceCount ?? 1
        case .onDate:
            maxOccurrences = 100 // Will stop when reaching end date
        }

        // Create subsequent appointments
        while occurrencesCreated < maxOccurrences - 1 {
            guard let nextDate = pattern.nextOccurrence(after: currentDate) else {
                break
            }

            // Check if we've passed the end date
            if pattern.endType == .onDate, let endDate = pattern.endDate, nextDate > endDate {
                break
            }

            // Check for conflicts
            if !hasConflict(at: nextDate, duration: firstAppointment.durationMinutes) {
                var newAppointment = Appointment(
                    clientId: clientId,
                    startDateTime: nextDate,
                    durationMinutes: firstAppointment.durationMinutes,
                    serviceType: firstAppointment.serviceType
                )
                newAppointment.parentAppointmentId = parentAppointment.id
                newAppointment.isRecurring = true
                newAppointment.recurrencePattern = pattern

                appointments.append(newAppointment)
                createdAppointments.append(newAppointment)
            }

            currentDate = nextDate
            occurrencesCreated += 1
        }

        // TODO: Save to Core Data

        return createdAppointments
    }

    /// Get available time slots for a specific day
    /// - Parameters:
    ///   - date: The date to check
    ///   - duration: Appointment duration in minutes
    /// - Returns: Array of available start times
    func availableTimeSlots(on date: Date, duration: Int) -> [Date] {
        guard let schedule = schedule else {
            return []
        }

        // Get all possible slots from the schedule
        let allSlots = schedule.availableSlots(on: date, slotDuration: duration)

        // Filter out slots that have conflicts
        return allSlots.filter { !hasConflict(at: $0, duration: duration) }
    }

    /// Get statistics for a date range
    /// - Parameters:
    ///   - startDate: Start of range
    ///   - endDate: End of range
    /// - Returns: Statistics summary
    func statistics(from startDate: Date, to endDate: Date) -> AppointmentStatistics {
        let rangeAppointments = appointments(from: startDate, to: endDate)

        let totalAppointments = rangeAppointments.count
        let completedAppointments = rangeAppointments.filter { $0.status == .completed }.count
        let cancelledAppointments = rangeAppointments.filter { $0.status == .cancelled }.count
        let noShowAppointments = rangeAppointments.filter { $0.status == .noShow }.count
        let upcomingAppointments = rangeAppointments.filter { $0.isUpcoming }.count

        let totalRevenue = rangeAppointments
            .filter { $0.status == .completed && $0.isPaid }
            .compactMap { $0.price }
            .reduce(0, +)

        return AppointmentStatistics(
            totalAppointments: totalAppointments,
            completedAppointments: completedAppointments,
            cancelledAppointments: cancelledAppointments,
            noShowAppointments: noShowAppointments,
            upcomingAppointments: upcomingAppointments,
            totalRevenue: totalRevenue
        )
    }
}

// MARK: - Appointment Statistics

/// Statistics for appointments in a time period
struct AppointmentStatistics {
    let totalAppointments: Int
    let completedAppointments: Int
    let cancelledAppointments: Int
    let noShowAppointments: Int
    let upcomingAppointments: Int
    let totalRevenue: Decimal

    /// Completion rate as a percentage
    var completionRate: Double {
        guard totalAppointments > 0 else { return 0 }
        return Double(completedAppointments) / Double(totalAppointments) * 100
    }

    /// Cancellation rate as a percentage
    var cancellationRate: Double {
        guard totalAppointments > 0 else { return 0 }
        return Double(cancelledAppointments) / Double(totalAppointments) * 100
    }

    /// No-show rate as a percentage
    var noShowRate: Double {
        guard totalAppointments > 0 else { return 0 }
        return Double(noShowAppointments) / Double(totalAppointments) * 100
    }
}
