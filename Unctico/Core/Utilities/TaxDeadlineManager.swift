// TaxDeadlineManager.swift
// Manages tax deadlines and sends reminders

import Foundation
import Combine

/// Manager for tax deadline tracking
class TaxDeadlineManager: ObservableObject {

    @Published var deadlines: [TaxDeadline] = []
    @Published var errorMessage: String?

    init() {
        // TODO: Load from Core Data
        loadDeadlines()
    }

    // MARK: - CRUD Operations

    /// Create deadline
    func createDeadline(_ deadline: TaxDeadline) {
        deadlines.append(deadline)
        // TODO: Save to Core Data
    }

    /// Update deadline
    func updateDeadline(_ deadline: TaxDeadline) {
        if let index = deadlines.firstIndex(where: { $0.id == deadline.id }) {
            var updated = deadline
            updated.updatedAt = Date()
            deadlines[index] = updated
            // TODO: Update in Core Data
        }
    }

    /// Mark deadline as completed
    func completeDeadline(_ deadline: TaxDeadline, amount: Decimal?, confirmationNumber: String? = nil) {
        if let index = deadlines.firstIndex(where: { $0.id == deadline.id }) {
            var updated = deadline
            updated.isCompleted = true
            updated.completedDate = Date()
            updated.amount = amount
            updated.confirmationNumber = confirmationNumber
            updated.updatedAt = Date()
            deadlines[index] = updated
            // TODO: Update in Core Data
        }
    }

    /// Delete deadline
    func deleteDeadline(_ deadline: TaxDeadline) {
        deadlines.removeAll { $0.id == deadline.id }
        // TODO: Delete from Core Data
    }

    /// Generate federal deadlines for year
    func generateDeadlinesForYear(_ year: Int) {
        let federal = TaxDeadline.generateFederalDeadlines(year: year)
        for deadline in federal {
            if !deadlines.contains(where: { $0.type == deadline.type && $0.year == deadline.year && $0.quarter == deadline.quarter }) {
                deadlines.append(deadline)
            }
        }
        // TODO: Save to Core Data
    }

    // MARK: - Query Methods

    /// Get all deadlines
    func allDeadlines(sortedBy sortOrder: DeadlineSortOrder = .dueDateAscending) -> [TaxDeadline] {
        sortDeadlines(deadlines, by: sortOrder)
    }

    /// Get upcoming deadlines (not completed, due in next 90 days)
    func upcomingDeadlines() -> [TaxDeadline] {
        let ninetyDaysFromNow = Calendar.current.date(byAdding: .day, value: 90, to: Date())!
        return deadlines.filter {
            !$0.isCompleted && $0.dueDate <= ninetyDaysFromNow && $0.dueDate >= Date()
        }.sorted { $0.dueDate < $1.dueDate }
    }

    /// Get overdue deadlines
    func overdueDeadlines() -> [TaxDeadline] {
        deadlines.filter { $0.isOverdue }.sorted { $0.dueDate < $1.dueDate }
    }

    /// Get completed deadlines
    func completedDeadlines(year: Int? = nil) -> [TaxDeadline] {
        var filtered = deadlines.filter { $0.isCompleted }
        if let year = year {
            filtered = filtered.filter { $0.year == year }
        }
        return filtered.sorted { ($0.completedDate ?? Date()) > ($1.completedDate ?? Date()) }
    }

    /// Get deadlines by year
    func deadlines(year: Int) -> [TaxDeadline] {
        deadlines.filter { $0.year == year }
    }

    /// Get deadlines by type
    func deadlines(type: DeadlineType) -> [TaxDeadline] {
        deadlines.filter { $0.type == type }
    }

    // MARK: - Reminders

    /// Check for deadlines needing reminders (within 30 days)
    func deadlinesNeedingReminders() -> [TaxDeadline] {
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        return deadlines.filter {
            !$0.isCompleted &&
            !$0.reminderSent &&
            $0.dueDate <= thirtyDaysFromNow &&
            $0.dueDate >= Date()
        }
    }

    /// Send reminders for upcoming deadlines
    func sendReminders() {
        let needingReminders = deadlinesNeedingReminders()

        for deadline in needingReminders {
            // TODO: Send notification/email
            if let index = deadlines.firstIndex(where: { $0.id == deadline.id }) {
                var updated = deadline
                updated.reminderSent = true
                updated.reminderDate = Date()
                deadlines[index] = updated
                // TODO: Update in Core Data
            }
        }
    }

    // MARK: - Statistics

    /// Get deadline statistics for year
    func getStatistics(year: Int) -> DeadlineStatistics {
        let yearDeadlines = deadlines(year: year)

        let total = yearDeadlines.count
        let completed = yearDeadlines.filter { $0.isCompleted }.count
        let overdue = yearDeadlines.filter { $0.isOverdue }.count
        let upcoming = yearDeadlines.filter { $0.isUpcoming }.count

        let totalPaid = yearDeadlines
            .filter { $0.isCompleted }
            .compactMap { $0.amount }
            .reduce(0, +)

        return DeadlineStatistics(
            total: total,
            completed: completed,
            overdue: overdue,
            upcoming: upcoming,
            totalPaid: totalPaid
        )
    }

    // MARK: - Helper Methods

    private func sortDeadlines(_ deadlines: [TaxDeadline], by sortOrder: DeadlineSortOrder) -> [TaxDeadline] {
        switch sortOrder {
        case .dueDateAscending:
            return deadlines.sorted { $0.dueDate < $1.dueDate }
        case .dueDateDescending:
            return deadlines.sorted { $0.dueDate > $1.dueDate }
        case .priority:
            return deadlines.sorted { $0.type.priority < $1.type.priority }
        }
    }

    private func loadDeadlines() {
        // Generate current year deadlines
        let currentYear = Calendar.current.component(.year, from: Date())
        generateDeadlinesForYear(currentYear)
    }
}

// MARK: - Supporting Types

struct DeadlineStatistics {
    let total: Int
    let completed: Int
    let overdue: Int
    let upcoming: Int
    let totalPaid: Decimal
}

enum DeadlineSortOrder {
    case dueDateAscending
    case dueDateDescending
    case priority
}
