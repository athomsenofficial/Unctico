// Form1099.swift
// Form 1099-NEC tracking for independent contractors and payments

import Foundation

/// Represents a Form 1099-NEC for tracking contractor payments
struct Form1099: Codable, Identifiable {
    let id: UUID
    var year: Int
    var recipientType: RecipientType

    // Recipient information
    var recipientName: String
    var recipientBusinessName: String?
    var recipientTIN: String // Tax ID Number (SSN or EIN)
    var recipientAddress: Address

    // Payment information
    var nonemployeeCompensation: Decimal // Box 1
    var federalTaxWithheld: Decimal? // Box 4
    var totalPayments: Decimal { nonemployeeCompensation }

    // Tracking
    var payments: [Payment1099]
    var isFiled: Bool
    var filedDate: Date?
    var confirmationNumber: String?

    // Metadata
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        year: Int,
        recipientName: String,
        recipientTIN: String,
        recipientAddress: Address
    ) {
        self.id = id
        self.year = year
        self.recipientType = .individual
        self.recipientName = recipientName
        self.recipientTIN = recipientTIN
        self.recipientAddress = recipientAddress
        self.nonemployeeCompensation = 0
        self.payments = []
        self.isFiled = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Whether form needs to be filed (>= $600)
    var requiresFiling: Bool {
        nonemployeeCompensation >= 600
    }

    /// Display name for recipient
    var displayName: String {
        recipientBusinessName ?? recipientName
    }

    /// Status for display
    var status: Form1099Status {
        if isFiled {
            return .filed
        } else if requiresFiling {
            return .needsFiling
        } else {
            return .belowThreshold
        }
    }

    /// Add a payment to this 1099
    mutating func addPayment(_ payment: Payment1099) {
        payments.append(payment)
        nonemployeeCompensation += payment.amount
        updatedAt = Date()
    }

    /// Calculate total for a specific category
    func totalForCategory(_ category: PaymentCategory1099) -> Decimal {
        payments
            .filter { $0.category == category }
            .reduce(0) { $0 + $1.amount }
    }
}

// MARK: - Payment 1099

struct Payment1099: Codable, Identifiable {
    let id: UUID
    var date: Date
    var amount: Decimal
    var category: PaymentCategory1099
    var description: String
    var checkNumber: String?
    var invoiceNumber: String?

    init(
        id: UUID = UUID(),
        date: Date,
        amount: Decimal,
        category: PaymentCategory1099,
        description: String
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.category = category
        self.description = description
    }
}

// MARK: - Payment Category 1099

enum PaymentCategory1099: String, Codable, CaseIterable {
    case contractorServices = "Contractor Services"
    case professionalServices = "Professional Services"
    case rent = "Rent"
    case equipmentRental = "Equipment Rental"
    case referralFees = "Referral Fees"
    case commissions = "Commissions"
    case consulting = "Consulting"
    case other = "Other"
}

// MARK: - Recipient Type

enum RecipientType: String, Codable {
    case individual = "Individual"
    case soleProprietor = "Sole Proprietor"
    case singleMemberLLC = "Single-Member LLC"
    case partnership = "Partnership"
    case corporation = "Corporation"
    case estate = "Estate/Trust"
}

// MARK: - Address

struct Address: Codable {
    var street1: String
    var street2: String?
    var city: String
    var state: String
    var zipCode: String
    var country: String

    init(
        street1: String,
        city: String,
        state: String,
        zipCode: String,
        country: String = "USA"
    ) {
        self.street1 = street1
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
    }

    var fullAddress: String {
        var lines = [street1]
        if let street2 = street2 {
            lines.append(street2)
        }
        lines.append("\(city), \(state) \(zipCode)")
        if country != "USA" {
            lines.append(country)
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Form 1099 Status

enum Form1099Status: String {
    case needsFiling = "Needs Filing"
    case filed = "Filed"
    case belowThreshold = "Below Threshold"

    var color: String {
        switch self {
        case .needsFiling: return "orange"
        case .filed: return "green"
        case .belowThreshold: return "gray"
        }
    }

    var icon: String {
        switch self {
        case .needsFiling: return "exclamationmark.circle.fill"
        case .filed: return "checkmark.circle.fill"
        case .belowThreshold: return "info.circle"
        }
    }
}

// MARK: - Form 1099 Statistics

struct Form1099Statistics {
    let totalForms: Int
    let formsRequiringFiling: Int
    let formsFiled: Int
    let formsNotFiled: Int
    let totalCompensation: Decimal
    let averagePerRecipient: Decimal
}

// MARK: - Preview

#Preview {
    let form = Form1099(
        year: 2024,
        recipientName: "John Doe",
        recipientTIN: "123-45-6789",
        recipientAddress: Address(
            street1: "123 Main St",
            city: "Springfield",
            state: "IL",
            zipCode: "62701"
        )
    )
    return Text(form.displayName)
}
