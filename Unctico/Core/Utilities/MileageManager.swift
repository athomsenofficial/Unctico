// MileageManager.swift
// Manages mileage logs for tax deductions

import Foundation
import Combine

/// Manager for mileage log operations
class MileageManager: ObservableObject {

    @Published var mileageLogs: [MileageLog] = []
    @Published var errorMessage: String?

    init() {
        // TODO: Load from Core Data
        loadMockData()
    }

    // MARK: - CRUD Operations

    /// Create a new mileage log
    func createMileageLog(
        date: Date,
        startLocation: String,
        endLocation: String,
        purpose: MileagePurpose,
        businessPurpose: String,
        miles: Double,
        isRoundTrip: Bool = false
    ) -> MileageLog? {
        var log = MileageLog(
            date: date,
            startLocation: startLocation,
            endLocation: endLocation,
            purpose: purpose,
            businessPurpose: businessPurpose,
            miles: miles
        )

        log.isRoundTrip = isRoundTrip
        mileageLogs.append(log)

        // TODO: Save to Core Data
        return log
    }

    /// Update mileage log
    func updateMileageLog(_ log: MileageLog) {
        if let index = mileageLogs.firstIndex(where: { $0.id == log.id }) {
            var updated = log
            updated.updatedAt = Date()
            mileageLogs[index] = updated
            // TODO: Update in Core Data
        }
    }

    /// Delete mileage log
    func deleteMileageLog(_ log: MileageLog) {
        mileageLogs.removeAll { $0.id == log.id }
        // TODO: Delete from Core Data
    }

    // MARK: - Query Methods

    /// Get all mileage logs
    func allLogs(sortedBy sortOrder: MileageSortOrder = .dateDescending) -> [MileageLog] {
        sortLogs(mileageLogs, by: sortOrder)
    }

    /// Get logs by date range
    func logs(from startDate: Date, to endDate: Date) -> [MileageLog] {
        mileageLogs.filter { $0.date >= startDate && $0.date <= endDate }
    }

    /// Get logs by year
    func logs(year: Int) -> [MileageLog] {
        mileageLogs.filter { $0.year == year }
    }

    /// Get logs by purpose
    func logs(purpose: MileagePurpose) -> [MileageLog] {
        mileageLogs.filter { $0.purpose == purpose }
    }

    /// Get deductible logs only
    func deductibleLogs(year: Int? = nil) -> [MileageLog] {
        var filtered = mileageLogs.filter { $0.purpose.isDeductible }
        if let year = year {
            filtered = filtered.filter { $0.year == year }
        }
        return filtered
    }

    // MARK: - Reporting

    /// Calculate total deduction for date range
    func totalDeduction(from startDate: Date, to endDate: Date) -> Decimal {
        logs(from: startDate, to: endDate)
            .reduce(0) { $0 + $1.totalDeduction }
    }

    /// Calculate total deduction for year
    func totalDeduction(year: Int) -> Decimal {
        deductibleLogs(year: year)
            .reduce(0) { $0 + $1.totalDeduction }
    }

    /// Calculate total miles for year
    func totalMiles(year: Int) -> Double {
        logs(year: year)
            .reduce(0) { $0 + $1.totalMiles }
    }

    /// Get statistics
    func getStatistics(from startDate: Date? = nil, to endDate: Date? = nil) -> MileageStatistics {
        var filtered = mileageLogs

        if let startDate = startDate, let endDate = endDate {
            filtered = logs(from: startDate, to: endDate)
        }

        let totalMiles = filtered.reduce(0.0) { $0 + $1.totalMiles }
        let totalDeduction = filtered.reduce(Decimal(0)) { $0 + $1.totalDeduction }

        var byPurpose: [MileagePurpose: Double] = [:]
        for log in filtered {
            byPurpose[log.purpose, default: 0] += log.totalMiles
        }

        let longest = filtered.max(by: { $0.totalMiles < $1.totalMiles })

        return MileageStatistics(
            totalTrips: filtered.count,
            totalMiles: totalMiles,
            totalDeduction: totalDeduction,
            byPurpose: byPurpose,
            averageMilesPerTrip: filtered.isEmpty ? 0 : totalMiles / Double(filtered.count),
            longestTrip: longest
        )
    }

    // MARK: - Helper Methods

    private func sortLogs(_ logs: [MileageLog], by sortOrder: MileageSortOrder) -> [MileageLog] {
        switch sortOrder {
        case .dateDescending:
            return logs.sorted { $0.date > $1.date }
        case .dateAscending:
            return logs.sorted { $0.date < $1.date }
        case .milesDescending:
            return logs.sorted { $0.totalMiles > $1.totalMiles }
        case .deductionDescending:
            return logs.sorted { $0.totalDeduction > $1.totalDeduction }
        }
    }

    // MARK: - Mock Data

    private func loadMockData() {
        mileageLogs = [
            MileageLog(
                date: Date().addingTimeInterval(-86400 * 5),
                startLocation: "Home",
                endLocation: "Client - 123 Main St",
                purpose: .clientVisit,
                businessPurpose: "60-minute massage appointment",
                miles: 12.5
            ),
            MileageLog(
                date: Date().addingTimeInterval(-86400 * 3),
                startLocation: "Home",
                endLocation: "Massage Supply Store",
                purpose: .supplyPickup,
                businessPurpose: "Purchase massage oils and linens",
                miles: 8.2
            )
        ]
    }
}

// MARK: - Sort Order

enum MileageSortOrder {
    case dateDescending
    case dateAscending
    case milesDescending
    case deductionDescending
}
