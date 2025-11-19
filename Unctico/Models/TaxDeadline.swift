// TaxDeadline.swift
// Tax deadline tracking and reminders

import Foundation

/// Represents a tax deadline
struct TaxDeadline: Codable, Identifiable {
    let id: UUID
    var type: DeadlineType
    var dueDate: Date
    var year: Int // Tax year
    var quarter: Int? // For quarterly deadlines (1-4)
    var isCompleted: Bool
    var completedDate: Date?
    var amount: Decimal? // Estimated or actual amount paid
    var confirmationNumber: String?
    var notes: String?

    // Reminders
    var reminderSent: Bool
    var reminderDate: Date?

    // Metadata
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        type: DeadlineType,
        dueDate: Date,
        year: Int,
        quarter: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.dueDate = dueDate
        self.year = year
        self.quarter = quarter
        self.isCompleted = false
        self.reminderSent = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Days until deadline
    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }

    /// Is deadline overdue
    var isOverdue: Bool {
        !isCompleted && dueDate < Date()
    }

    /// Is deadline coming up soon (within 30 days)
    var isUpcoming: Bool {
        !isCompleted && daysUntil >= 0 && daysUntil <= 30
    }

    /// Status for display
    var status: DeadlineStatus {
        if isCompleted {
            return .completed
        } else if isOverdue {
            return .overdue
        } else if isUpcoming {
            return .upcoming
        } else {
            return .future
        }
    }

    /// Display title
    var displayTitle: String {
        if let quarter = quarter {
            return "\(type.rawValue) Q\(quarter) \(year)"
        } else {
            return "\(type.rawValue) \(year)"
        }
    }

    // MARK: - Static Helpers

    /// Generate all federal tax deadlines for a given year
    static func generateFederalDeadlines(year: Int) -> [TaxDeadline] {
        var deadlines: [TaxDeadline] = []
        let calendar = Calendar.current

        // Quarterly estimated tax deadlines
        let q1 = TaxDeadline(
            type: .estimatedTaxQ1,
            dueDate: calendar.date(from: DateComponents(year: year, month: 4, day: 15))!,
            year: year,
            quarter: 1
        )
        let q2 = TaxDeadline(
            type: .estimatedTaxQ2,
            dueDate: calendar.date(from: DateComponents(year: year, month: 6, day: 15))!,
            year: year,
            quarter: 2
        )
        let q3 = TaxDeadline(
            type: .estimatedTaxQ3,
            dueDate: calendar.date(from: DateComponents(year: year, month: 9, day: 15))!,
            year: year,
            quarter: 3
        )
        let q4 = TaxDeadline(
            type: .estimatedTaxQ4,
            dueDate: calendar.date(from: DateComponents(year: year + 1, month: 1, day: 15))!,
            year: year,
            quarter: 4
        )

        deadlines.append(contentsOf: [q1, q2, q3, q4])

        // Annual tax return deadline (April 15 of following year)
        let taxReturn = TaxDeadline(
            type: .taxReturn,
            dueDate: calendar.date(from: DateComponents(year: year + 1, month: 4, day: 15))!,
            year: year
        )
        deadlines.append(taxReturn)

        // Form 1099-NEC deadline (January 31 of following year)
        let form1099 = TaxDeadline(
            type: .form1099Filing,
            dueDate: calendar.date(from: DateComponents(year: year + 1, month: 1, day: 31))!,
            year: year
        )
        deadlines.append(form1099)

        return deadlines
    }

    /// Generate state tax deadlines (for states with income tax)
    static func generateStateDeadlines(year: Int, state: String) -> [TaxDeadline] {
        // Most states align with federal deadlines
        // This is a simplified version - would need state-specific logic
        var deadlines: [TaxDeadline] = []
        let calendar = Calendar.current

        let stateReturn = TaxDeadline(
            type: .stateReturn,
            dueDate: calendar.date(from: DateComponents(year: year + 1, month: 4, day: 15))!,
            year: year
        )
        deadlines.append(stateReturn)

        return deadlines
    }
}

// MARK: - Deadline Type

enum DeadlineType: String, Codable, CaseIterable, Identifiable {
    // Quarterly estimated taxes
    case estimatedTaxQ1 = "Estimated Tax Payment"
    case estimatedTaxQ2 = "Estimated Tax Payment"
    case estimatedTaxQ3 = "Estimated Tax Payment"
    case estimatedTaxQ4 = "Estimated Tax Payment"

    // Annual filings
    case taxReturn = "Tax Return Filing"
    case stateReturn = "State Tax Return"
    case form1099Filing = "Form 1099-NEC Filing"

    // Other deadlines
    case extensionFiling = "Extension Filing"
    case salesTax = "Sales Tax Filing"
    case businessLicense = "Business License Renewal"
    case other = "Other Deadline"

    var id: String { rawValue }

    /// Icon for UI
    var icon: String {
        switch self {
        case .estimatedTaxQ1, .estimatedTaxQ2, .estimatedTaxQ3, .estimatedTaxQ4:
            return "dollarsign.circle.fill"
        case .taxReturn, .stateReturn:
            return "doc.text.fill"
        case .form1099Filing:
            return "doc.badge.plus"
        case .extensionFiling:
            return "calendar.badge.clock"
        case .salesTax:
            return "cart.fill.badge.plus"
        case .businessLicense:
            return "person.text.rectangle.fill"
        case .other:
            return "calendar.circle.fill"
        }
    }

    /// Color for UI
    var color: String {
        switch self {
        case .estimatedTaxQ1, .estimatedTaxQ2, .estimatedTaxQ3, .estimatedTaxQ4:
            return "blue"
        case .taxReturn, .stateReturn:
            return "red"
        case .form1099Filing:
            return "orange"
        case .extensionFiling:
            return "yellow"
        case .salesTax:
            return "green"
        case .businessLicense:
            return "purple"
        case .other:
            return "gray"
        }
    }

    /// Priority level (1 = highest)
    var priority: Int {
        switch self {
        case .taxReturn: return 1
        case .estimatedTaxQ1, .estimatedTaxQ2, .estimatedTaxQ3, .estimatedTaxQ4: return 2
        case .form1099Filing: return 3
        case .stateReturn: return 4
        case .extensionFiling: return 5
        case .salesTax: return 6
        case .businessLicense: return 7
        case .other: return 8
        }
    }
}

// MARK: - Deadline Status

enum DeadlineStatus: String {
    case completed = "Completed"
    case overdue = "Overdue"
    case upcoming = "Upcoming"
    case future = "Future"

    var color: String {
        switch self {
        case .completed: return "green"
        case .overdue: return "red"
        case .upcoming: return "orange"
        case .future: return "gray"
        }
    }

    var icon: String {
        switch self {
        case .completed: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .upcoming: return "clock.fill"
        case .future: return "calendar"
        }
    }
}

// MARK: - Preview

#Preview {
    let deadline = TaxDeadline(
        type: .estimatedTaxQ1,
        dueDate: Date().addingTimeInterval(86400 * 15),
        year: 2024,
        quarter: 1
    )
    return Text(deadline.displayTitle)
}
