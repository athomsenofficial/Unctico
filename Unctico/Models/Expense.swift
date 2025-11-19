// Expense.swift
// Business expense tracking with categories and receipt management

import Foundation

/// Represents a business expense
struct Expense: Codable, Identifiable {
    let id: UUID
    var date: Date
    var amount: Decimal
    var category: ExpenseCategory
    var description: String
    var vendor: String
    var paymentMethod: PaymentMethod

    // Tax tracking
    var isTaxDeductible: Bool
    var taxCategory: String? // e.g., "Office Supplies", "Travel", "Meals"

    // Receipt management
    var hasReceipt: Bool
    var receiptImagePath: String? // Local file path or cloud URL
    var receiptNotes: String?

    // Recurring expense support
    var isRecurring: Bool
    var recurrencePattern: RecurrencePattern?
    var parentExpenseId: UUID? // For recurring expense series

    // Metadata
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Decimal,
        category: ExpenseCategory,
        description: String,
        vendor: String = "",
        paymentMethod: PaymentMethod = .cash
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.category = category
        self.description = description
        self.vendor = vendor
        self.paymentMethod = paymentMethod
        self.isTaxDeductible = category.isDefaultDeductible
        self.hasReceipt = false
        self.isRecurring = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Month and year for grouping
    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    /// Year for annual reports
    var year: Int {
        Calendar.current.component(.year, from: date)
    }

    /// Quarter for quarterly reports (1-4)
    var quarter: Int {
        let month = Calendar.current.component(.month, from: date)
        return (month - 1) / 3 + 1
    }

    /// Display string for lists
    var displayString: String {
        "\(description) - \(CurrencyFormatter.format(amount))"
    }
}

// MARK: - Expense Category

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    // Space & utilities
    case rent = "Rent"
    case utilities = "Utilities"
    case internet = "Internet & Phone"
    case cleaning = "Cleaning & Maintenance"

    // Supplies
    case officeSupplies = "Office Supplies"
    case massageSupplies = "Massage Supplies"
    case linens = "Linens & Laundry"
    case equipment = "Equipment"

    // Professional services
    case insurance = "Insurance"
    case licensingFees = "Licensing & Fees"
    case professionalDevelopment = "Professional Development"
    case continuing Education = "Continuing Education"

    // Marketing & business
    case marketing = "Marketing & Advertising"
    case website = "Website & Software"
    case bookkeeping = "Bookkeeping & Accounting"
    case legal = "Legal Fees"

    // Transportation
    case mileage = "Mileage"
    case parking = "Parking"
    case travel = "Travel"

    // Miscellaneous
    case meals = "Meals & Entertainment"
    case gifts = "Client Gifts"
    case donations = "Donations"
    case other = "Other"

    var id: String { rawValue }

    /// Icon for UI display
    var icon: String {
        switch self {
        case .rent: return "house.fill"
        case .utilities: return "bolt.fill"
        case .internet: return "wifi"
        case .cleaning: return "sparkles"
        case .officeSupplies: return "paperclip"
        case .massageSupplies: return "heart.text.square.fill"
        case .linens: return "bed.double.fill"
        case .equipment: return "wrench.and.screwdriver.fill"
        case .insurance: return "shield.fill"
        case .licensingFees: return "doc.text.fill"
        case .professionalDevelopment: return "graduationcap.fill"
        case .continuingEducation: return "book.fill"
        case .marketing: return "megaphone.fill"
        case .website: return "globe"
        case .bookkeeping: return "chart.bar.fill"
        case .legal: return "scales.fill"
        case .mileage: return "car.fill"
        case .parking: return "parkingsign"
        case .travel: return "airplane"
        case .meals: return "fork.knife"
        case .gifts: return "gift.fill"
        case .donations: return "heart.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    /// Color for category
    var color: String {
        switch self {
        case .rent, .utilities, .internet, .cleaning:
            return "blue"
        case .officeSupplies, .massageSupplies, .linens, .equipment:
            return "green"
        case .insurance, .licensingFees, .professionalDevelopment, .continuingEducation:
            return "purple"
        case .marketing, .website, .bookkeeping, .legal:
            return "orange"
        case .mileage, .parking, .travel:
            return "indigo"
        case .meals, .gifts, .donations, .other:
            return "gray"
        }
    }

    /// Whether this category is typically tax deductible
    var isDefaultDeductible: Bool {
        // Most business expenses are deductible, but some have limitations
        switch self {
        case .meals: return true // Usually 50% deductible
        case .gifts: return true // Limited to $25 per person
        case .donations: return false // Personal, not business
        default: return true
        }
    }

    /// Tax notes for accountant
    var taxNotes: String? {
        switch self {
        case .meals:
            return "Generally 50% deductible"
        case .gifts:
            return "Limited to $25 per person per year"
        case .mileage:
            return "Standard mileage rate or actual expenses"
        case .continuingEducation:
            return "Deductible if maintains or improves job skills"
        default:
            return nil
        }
    }
}

// MARK: - Expense Statistics

struct ExpenseStatistics {
    let totalExpenses: Int
    let totalAmount: Decimal
    let byCategory: [ExpenseCategory: Decimal]
    let taxDeductibleAmount: Decimal
    let averageExpenseAmount: Decimal
    let largestExpense: Expense?
    let mostCommonCategory: ExpenseCategory?
}

// MARK: - Preview

#Preview {
    let expense = Expense(
        amount: 45.99,
        category: .massageSupplies,
        description: "Massage oil and lotion",
        vendor: "Massage Warehouse"
    )
    return Text(expense.displayString)
}
