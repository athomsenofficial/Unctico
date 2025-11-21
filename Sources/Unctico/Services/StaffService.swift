import Foundation

/// Service for team and staff management
@MainActor
class StaffService: ObservableObject {
    static let shared = StaffService()

    @Published var activeStaffAlerts: [StaffAlert] = []

    init() {
        // Initialize service
    }

    // MARK: - Performance Tracking

    /// Calculate performance metrics for a staff member
    func calculatePerformanceMetrics(
        staffId: UUID,
        period: DateRange,
        appointments: [Appointment],
        clients: [Client]
    ) -> PerformanceMetrics {
        // Filter appointments for this staff member
        let staffAppointments = appointments.filter { $0.therapistId == staffId && period.contains($0.dateTime) }

        let totalAppointments = staffAppointments.count
        let totalRevenue = staffAppointments.reduce(0) { $0 + $1.totalAmount }

        // Calculate ratings
        let ratingsCount = staffAppointments.filter { $0.clientRating != nil }.count
        let averageRating = ratingsCount > 0
            ? staffAppointments.compactMap { $0.clientRating }.reduce(0, +) / Double(ratingsCount)
            : 0.0

        // Calculate status counts
        let completedCount = staffAppointments.filter { $0.status == .completed }.count
        let cancelledCount = staffAppointments.filter { $0.status == .cancelled }.count
        let noShowCount = staffAppointments.filter { $0.status == .noShow }.count

        let cancellationRate = totalAppointments > 0 ? Double(cancelledCount) / Double(totalAppointments) * 100 : 0
        let noShowRate = totalAppointments > 0 ? Double(noShowCount) / Double(totalAppointments) * 100 : 0

        // Calculate client metrics
        let uniqueClientIds = Set(staffAppointments.map { $0.clientId })
        let newClientsInPeriod = clients.filter { client in
            guard let firstVisit = client.firstVisitDate,
                  period.contains(firstVisit) else { return false }
            return uniqueClientIds.contains(client.id)
        }.count

        let repeatClients = uniqueClientIds.count - newClientsInPeriod

        // Calculate rebooking rate (clients who booked again after their first visit)
        let clientVisitCounts = Dictionary(grouping: staffAppointments, by: { $0.clientId })
            .mapValues { $0.count }
        let rebookedClients = clientVisitCounts.filter { $0.value > 1 }.count
        let rebookingRate = uniqueClientIds.count > 0
            ? Double(rebookedClients) / Double(uniqueClientIds.count) * 100
            : 0

        // Calculate average service duration
        let totalDuration = staffAppointments.reduce(0.0) { $0 + $1.duration }
        let averageDuration = totalAppointments > 0 ? totalDuration / Double(totalAppointments) : 0

        // Client retention (simplified - clients who visited in both halves of period)
        let midPoint = period.start.addingTimeInterval(period.end.timeIntervalSince(period.start) / 2)
        let firstHalfClients = Set(staffAppointments.filter { $0.dateTime < midPoint }.map { $0.clientId })
        let secondHalfClients = Set(staffAppointments.filter { $0.dateTime >= midPoint }.map { $0.clientId })
        let retainedClients = firstHalfClients.intersection(secondHalfClients).count
        let clientRetentionRate = firstHalfClients.count > 0
            ? Double(retainedClients) / Double(firstHalfClients.count) * 100
            : 0

        return PerformanceMetrics(
            period: period,
            totalAppointments: totalAppointments,
            totalRevenue: totalRevenue,
            averageRating: averageRating,
            clientRetentionRate: clientRetentionRate,
            rebookingRate: rebookingRate,
            cancellationRate: cancellationRate,
            noShowRate: noShowRate,
            averageServiceDuration: averageDuration,
            newClients: newClientsInPeriod,
            repeatClients: repeatClients
        )
    }

    // MARK: - Commission Calculation

    /// Calculate commission for a staff member based on their compensation structure
    func calculateCommission(
        staff: StaffMember,
        period: DateRange,
        appointments: [Appointment]
    ) -> CommissionResult {
        let staffAppointments = appointments.filter {
            $0.therapistId == staff.id && period.contains($0.dateTime) && $0.status == .completed
        }

        let totalRevenue = staffAppointments.reduce(0) { $0 + $1.totalAmount }
        let totalAppointments = staffAppointments.count

        var commissionAmount: Double = 0
        var basePayAmount: Double = 0
        var effectiveRate: Double = 0

        switch staff.compensation.type {
        case .commission:
            if let rate = staff.compensation.commissionRate {
                commissionAmount = totalRevenue * (rate / 100)
                effectiveRate = rate
            }

        case .hourlyPlusCommission:
            // Calculate hours worked from appointments
            let hoursWorked = staffAppointments.reduce(0.0) { $0 + ($1.duration / 3600) }
            basePayAmount = hoursWorked * staff.compensation.baseRate

            if let rate = staff.compensation.commissionRate {
                commissionAmount = totalRevenue * (rate / 100)
                effectiveRate = rate
            }

        case .hourly:
            let hoursWorked = staffAppointments.reduce(0.0) { $0 + ($1.duration / 3600) }
            basePayAmount = hoursWorked * staff.compensation.baseRate

        case .salary:
            // Salary is typically paid monthly, not based on appointments
            basePayAmount = staff.compensation.baseRate

        case .perService:
            basePayAmount = Double(totalAppointments) * staff.compensation.baseRate
        }

        // Apply tiered commission if applicable
        if let structure = staff.compensation.commissionStructure {
            let basis = structure.basedOn == .revenue ? totalRevenue : Double(totalAppointments)
            let applicableTier = structure.tiers
                .sorted { $0.threshold < $1.threshold }
                .last { basis >= $0.threshold }

            if let tier = applicableTier {
                effectiveRate = tier.rate
                commissionAmount = totalRevenue * (tier.rate / 100)
            }
        }

        let totalPay = basePayAmount + commissionAmount

        return CommissionResult(
            period: period,
            staffId: staff.id,
            staffName: staff.fullName,
            totalRevenue: totalRevenue,
            totalAppointments: totalAppointments,
            basePay: basePayAmount,
            commissionAmount: commissionAmount,
            totalPay: totalPay,
            effectiveCommissionRate: effectiveRate
        )
    }

    // MARK: - Schedule Management

    /// Check for schedule conflicts when assigning an appointment
    func checkScheduleConflict(
        staffId: UUID,
        startTime: Date,
        endTime: Date,
        existingAppointments: [Appointment],
        excludingAppointmentId: UUID? = nil
    ) -> ScheduleConflict? {
        let staffAppointments = existingAppointments.filter { appointment in
            appointment.therapistId == staffId &&
            appointment.status != .cancelled &&
            appointment.status != .noShow &&
            (excludingAppointmentId == nil || appointment.id != excludingAppointmentId)
        }

        for appointment in staffAppointments {
            let appointmentEnd = appointment.dateTime.addingTimeInterval(appointment.duration)

            // Check for overlap
            if startTime < appointmentEnd && endTime > appointment.dateTime {
                return ScheduleConflict(
                    staffId: staffId,
                    requestedStart: startTime,
                    requestedEnd: endTime,
                    conflictingAppointment: appointment
                )
            }
        }

        return nil
    }

    /// Find available time slots for a staff member on a given date
    func findAvailableSlots(
        staffId: UUID,
        date: Date,
        serviceDuration: TimeInterval,
        staff: StaffMember,
        existingAppointments: [Appointment],
        scheduleEntry: StaffScheduleEntry?
    ) -> [TimeSlot] {
        var availableSlots: [TimeSlot] = []

        // Get the schedule for this date
        guard let schedule = scheduleEntry, schedule.isAvailable else {
            return availableSlots
        }

        let calendar = Calendar.current
        var currentTime = schedule.startTime
        let endTime = schedule.endTime

        // Sort appointments by time
        let dayAppointments = existingAppointments
            .filter {
                $0.therapistId == staffId &&
                calendar.isDate($0.dateTime, inSameDayAs: date) &&
                $0.status != .cancelled &&
                $0.status != .noShow
            }
            .sorted { $0.dateTime < $1.dateTime }

        while currentTime.addingTimeInterval(serviceDuration) <= endTime {
            let slotEnd = currentTime.addingTimeInterval(serviceDuration)

            // Check if this slot conflicts with break
            let conflictsWithBreak: Bool = {
                if let breakStart = schedule.breakStart, let breakEnd = schedule.breakEnd {
                    return currentTime < breakEnd && slotEnd > breakStart
                }
                return false
            }()

            // Check if this slot conflicts with existing appointments
            let conflictsWithAppointment = dayAppointments.contains { appointment in
                let appointmentEnd = appointment.dateTime.addingTimeInterval(appointment.duration)
                return currentTime < appointmentEnd && slotEnd > appointment.dateTime
            }

            if !conflictsWithBreak && !conflictsWithAppointment {
                availableSlots.append(TimeSlot(start: currentTime, end: slotEnd))
            }

            // Move to next slot (15-minute intervals)
            currentTime = currentTime.addingTimeInterval(15 * 60)
        }

        return availableSlots
    }

    // MARK: - Time Off Management

    /// Check if time off request conflicts with existing appointments
    func checkTimeOffConflicts(
        request: TimeOffRequest,
        existingAppointments: [Appointment]
    ) -> [Appointment] {
        let conflictingAppointments = existingAppointments.filter { appointment in
            appointment.therapistId == request.staffId &&
            appointment.status != .cancelled &&
            appointment.dateTime >= request.startDate &&
            appointment.dateTime <= request.endDate
        }

        return conflictingAppointments
    }

    /// Approve time off request
    func approveTimeOffRequest(
        request: TimeOffRequest,
        reviewedBy: UUID,
        notes: String = ""
    ) -> TimeOffRequest {
        var updatedRequest = request
        updatedRequest.status = .approved
        updatedRequest.reviewedBy = reviewedBy
        updatedRequest.reviewedDate = Date()
        updatedRequest.reviewNotes = notes

        return updatedRequest
    }

    /// Deny time off request
    func denyTimeOffRequest(
        request: TimeOffRequest,
        reviewedBy: UUID,
        reason: String
    ) -> TimeOffRequest {
        var updatedRequest = request
        updatedRequest.status = .denied
        updatedRequest.reviewedBy = reviewedBy
        updatedRequest.reviewedDate = Date()
        updatedRequest.reviewNotes = reason

        return updatedRequest
    }

    // MARK: - Staff Alerts

    /// Generate alerts for staff management issues
    func generateStaffAlerts(
        staff: [StaffMember],
        timeOffRequests: [TimeOffRequest],
        performanceMetrics: [UUID: PerformanceMetrics]
    ) -> [StaffAlert] {
        var alerts: [StaffAlert] = []

        for member in staff where member.isActive {
            // License expiration alerts
            if member.isLicenseExpired {
                alerts.append(StaffAlert(
                    staffId: member.id,
                    staffName: member.fullName,
                    type: .licenseExpired,
                    severity: .critical,
                    message: "\(member.fullName)'s license has expired",
                    recommendedAction: "Update license information or deactivate staff member"
                ))
            } else if member.isLicenseExpiringSoon {
                alerts.append(StaffAlert(
                    staffId: member.id,
                    staffName: member.fullName,
                    type: .licenseExpiring,
                    severity: .warning,
                    message: "\(member.fullName)'s license expires soon",
                    recommendedAction: "Remind staff member to renew license"
                ))
            }

            // Certification expiration alerts
            for cert in member.certifications {
                if cert.isExpired {
                    alerts.append(StaffAlert(
                        staffId: member.id,
                        staffName: member.fullName,
                        type: .certificationExpired,
                        severity: .warning,
                        message: "\(member.fullName)'s \(cert.name) certification has expired",
                        recommendedAction: "Update or remove expired certification"
                    ))
                } else if cert.isExpiringSoon {
                    alerts.append(StaffAlert(
                        staffId: member.id,
                        staffName: member.fullName,
                        type: .certificationExpiring,
                        severity: .info,
                        message: "\(member.fullName)'s \(cert.name) expires in 30 days",
                        recommendedAction: "Remind staff member to renew certification"
                    ))
                }
            }

            // Performance alerts
            if let metrics = performanceMetrics[member.id] {
                if metrics.cancellationRate > 20 {
                    alerts.append(StaffAlert(
                        staffId: member.id,
                        staffName: member.fullName,
                        type: .highCancellationRate,
                        severity: .warning,
                        message: "\(member.fullName) has a \(String(format: "%.1f", metrics.cancellationRate))% cancellation rate",
                        recommendedAction: "Review schedule management and client communication"
                    ))
                }

                if metrics.noShowRate > 10 {
                    alerts.append(StaffAlert(
                        staffId: member.id,
                        staffName: member.fullName,
                        type: .highNoShowRate,
                        severity: .warning,
                        message: "\(member.fullName) has a \(String(format: "%.1f", metrics.noShowRate))% no-show rate",
                        recommendedAction: "Implement reminder system and review booking policies"
                    ))
                }

                if metrics.averageRating > 0 && metrics.averageRating < 3.5 {
                    alerts.append(StaffAlert(
                        staffId: member.id,
                        staffName: member.fullName,
                        type: .lowPerformanceRating,
                        severity: .warning,
                        message: "\(member.fullName) has a low average rating (\(String(format: "%.1f", metrics.averageRating)) stars)",
                        recommendedAction: "Schedule performance review and provide additional training"
                    ))
                }
            }
        }

        // Pending time off requests
        let pendingRequests = timeOffRequests.filter { $0.isPending }
        if !pendingRequests.isEmpty {
            alerts.append(StaffAlert(
                staffId: UUID(), // General alert
                staffName: "Team",
                type: .pendingTimeOffRequests,
                severity: .info,
                message: "\(pendingRequests.count) pending time-off request(s) need review",
                recommendedAction: "Review and approve/deny pending requests"
            ))
        }

        activeStaffAlerts = alerts
        return alerts
    }

    // MARK: - Team Statistics

    /// Calculate team-wide statistics
    func calculateTeamStatistics(
        staff: [StaffMember],
        timeOffRequests: [TimeOffRequest],
        scheduleEntries: [StaffScheduleEntry],
        performanceMetrics: [UUID: PerformanceMetrics]
    ) -> TeamStatistics {
        let totalStaff = staff.count
        let activeStaff = staff.filter { $0.isActive }.count

        let therapistCount = staff.filter { $0.isActive && $0.role.canProvideServices }.count
        let supportStaffCount = activeStaff - therapistCount

        let pendingTimeOffRequests = timeOffRequests.filter { $0.isPending }.count

        let expiringLicenses = staff.filter { $0.isActive && ($0.isLicenseExpired || $0.isLicenseExpiringSoon) }.count

        let totalHoursScheduled = scheduleEntries.reduce(0.0) { $0 + $1.totalHours }

        let ratings = performanceMetrics.values.compactMap { $0.averageRating > 0 ? $0.averageRating : nil }
        let averagePerformanceRating = ratings.isEmpty ? 0 : ratings.reduce(0, +) / Double(ratings.count)

        let totalTeamRevenue = performanceMetrics.values.reduce(0) { $0 + $1.totalRevenue }

        return TeamStatistics(
            totalStaff: totalStaff,
            activeStaff: activeStaff,
            therapistCount: therapistCount,
            supportStaffCount: supportStaffCount,
            pendingTimeOffRequests: pendingTimeOffRequests,
            expiringLicenses: expiringLicenses,
            totalHoursScheduled: totalHoursScheduled,
            averagePerformanceRating: averagePerformanceRating,
            totalTeamRevenue: totalTeamRevenue
        )
    }
}

// MARK: - Supporting Types

struct CommissionResult {
    let period: DateRange
    let staffId: UUID
    let staffName: String
    let totalRevenue: Double
    let totalAppointments: Int
    let basePay: Double
    let commissionAmount: Double
    let totalPay: Double
    let effectiveCommissionRate: Double
}

struct ScheduleConflict {
    let staffId: UUID
    let requestedStart: Date
    let requestedEnd: Date
    let conflictingAppointment: Appointment
}

struct TimeSlot {
    let start: Date
    let end: Date

    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}

struct StaffAlert: Identifiable {
    let id = UUID()
    let staffId: UUID
    let staffName: String
    let type: AlertType
    let severity: AlertSeverity
    let message: String
    let recommendedAction: String

    enum AlertType {
        case licenseExpired
        case licenseExpiring
        case certificationExpired
        case certificationExpiring
        case highCancellationRate
        case highNoShowRate
        case lowPerformanceRating
        case pendingTimeOffRequests
    }

    enum AlertSeverity {
        case critical
        case warning
        case info
    }
}
