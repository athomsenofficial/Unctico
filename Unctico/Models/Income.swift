// Income.swift
// Business income tracking with automatic appointment linking

import Foundation

/// Represents business income
struct Income: Codable, Identifiable {
    let id: UUID
    var date: Date
    var amount: Decimal
    var category: IncomeCategory
    var description: String
    var source: String // Client name or source description

    // Linking
    var clientId: UUID?
    var appointmentId: UUID?
    var invoiceId: UUID?

    // Payment tracking
    var paymentMethod: PaymentMethod
    var isAutomatic: Bool // True if generated from appointment/invoice

    // Tax tracking
    var isTaxable: Bool
    var taxCategory: String? // For tax reporting

    // Metadata
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Decimal,
        category: IncomeCategory,
        description: String,
        source: String = "",
        paymentMethod: PaymentMethod = .cash,
        isAutomatic: Bool = false
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.category = category
        self.description = description
        self.source = source
        self.paymentMethod = paymentMethod
        self.isAutomatic = isAutomatic
        self.isTaxable = category.isDefaultTaxable
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

    /// Source type for grouping
    var sourceType: String {
        if appointmentId != nil {
            return "Appointment"
        } else if invoiceId != nil {
            return "Invoice"
        } else {
            return "Manual Entry"
        }
    }
}

// MARK: - Income Category

enum IncomeCategory: String, Codable, CaseIterable, Identifiable {
    // Service income
    case massageServices = "Massage Services"
    case therapeuticMassage = "Therapeutic Massage"
    case deepTissue = "Deep Tissue"
    case prenatalMassage = "Prenatal Massage"
    case sportsMassage = "Sports Massage"
    case specialtyServices = "Specialty Services"

    // Product sales
    case productSales = "Product Sales"
    case giftCertificates = "Gift Certificates"
    case retailProducts = "Retail Products"

    // Additional income
    case tips = "Tips"
    case cancellationFees = "Cancellation Fees"
    case noShowFees = "No-Show Fees"
    case workshops = "Workshops & Classes"
    case consultations = "Consultations"

    // Other
    case other = "Other Income"

    var id: String { rawValue }

    /// Icon for UI display
    var icon: String {
        switch self {
        case .massageServices, .therapeuticMassage, .deepTissue,
             .prenatalMassage, .sportsMassage, .specialtyServices:
            return "hands.sparkles.fill"
        case .productSales, .retailProducts:
            return "cart.fill"
        case .giftCertificates:
            return "gift.fill"
        case .tips:
            return "dollarsign.circle.fill"
        case .cancellationFees, .noShowFees:
            return "xmark.circle.fill"
        case .workshops:
            return "person.3.fill"
        case .consultations:
            return "bubble.left.and.bubble.right.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }

    /// Color for category
    var color: String {
        switch self {
        case .massageServices, .therapeuticMassage, .deepTissue,
             .prenatalMassage, .sportsMassage, .specialtyServices:
            return "green"
        case .productSales, .giftCertificates, .retailProducts:
            return "blue"
        case .tips:
            return "purple"
        case .cancellationFees, .noShowFees:
            return "orange"
        case .workshops, .consultations:
            return "indigo"
        case .other:
            return "gray"
        }
    }

    /// Whether this category is typically taxable
    var isDefaultTaxable: Bool {
        // Most income is taxable
        switch self {
        case .tips: return true // Tips are taxable income
        default: return true
        }
    }

    /// Tax notes for accountant
    var taxNotes: String? {
        switch self {
        case .tips:
            return "Report all tips as taxable income"
        case .giftCertificates:
            return "Income recognized when redeemed, not when sold"
        case .cancellationFees, .noShowFees:
            return "Taxable as business income"
        default:
            return nil
        }
    }
}

// MARK: - Income Statistics

struct IncomeStatistics {
    let totalIncome: Int
    let totalAmount: Decimal
    let byCategory: [IncomeCategory: Decimal]
    let byPaymentMethod: [PaymentMethod: Decimal]
    let automaticIncomeAmount: Decimal
    let manualIncomeAmount: Decimal
    let averageIncomeAmount: Decimal
    let largestIncome: Income?
    let mostCommonCategory: IncomeCategory?
}

// MARK: - Preview

#Preview {
    let income = Income(
        amount: 120.00,
        category: .therapeuticMassage,
        description: "60-minute therapeutic massage",
        source: "John Doe"
    )
    return Text(income.displayString)
}
