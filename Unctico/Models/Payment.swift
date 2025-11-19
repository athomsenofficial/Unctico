// Payment.swift
// Payment model for recording payments

import Foundation

/// Represents a payment received
struct Payment: Codable, Identifiable {

    // MARK: - Properties

    /// Unique identifier
    let id: UUID

    /// Invoice this payment is for
    let invoiceId: UUID

    /// Client who made the payment
    let clientId: UUID

    /// Payment amount
    var amount: Decimal

    /// Payment date
    var paymentDate: Date

    /// Payment method used
    var paymentMethod: PaymentMethod

    /// Payment status
    var status: PaymentStatus

    /// Reference number (e.g., check number, transaction ID)
    var referenceNumber: String?

    /// Notes about this payment
    var notes: String?

    /// When this payment was recorded
    let createdAt: Date

    /// When this payment was last updated
    var updatedAt: Date

    /// Who recorded this payment
    var recordedBy: String?

    /// Refund information (if refunded)
    var refund: Refund?

    // MARK: - Initialization

    init(invoiceId: UUID, clientId: UUID, amount: Decimal, paymentMethod: PaymentMethod, paymentDate: Date = Date()) {
        self.id = UUID()
        self.invoiceId = invoiceId
        self.clientId = clientId
        self.amount = amount
        self.paymentMethod = paymentMethod
        self.paymentDate = paymentDate
        self.status = .completed
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Is this payment refunded?
    var isRefunded: Bool {
        return refund != nil
    }

    /// Net amount (after refund if applicable)
    var netAmount: Decimal {
        if let refund = refund {
            return amount - refund.amount
        }
        return amount
    }
}

// MARK: - Payment Method

/// Method of payment
enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "Cash"
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case check = "Check"
    case bankTransfer = "Bank Transfer"
    case venmo = "Venmo"
    case paypal = "PayPal"
    case other = "Other"

    /// Icon for this payment method
    var icon: String {
        switch self {
        case .cash:
            return "dollarsign.circle.fill"
        case .creditCard, .debitCard:
            return "creditcard.fill"
        case .check:
            return "doc.text.fill"
        case .bankTransfer:
            return "building.columns.fill"
        case .venmo:
            return "iphone.and.arrow.forward"
        case .paypal:
            return "globe"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Payment Status

/// Status of a payment
enum PaymentStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case processing = "Processing"
    case completed = "Completed"
    case failed = "Failed"
    case refunded = "Refunded"

    /// Color for this status
    var color: String {
        switch self {
        case .pending:
            return "orange"
        case .processing:
            return "blue"
        case .completed:
            return "green"
        case .failed:
            return "red"
        case .refunded:
            return "purple"
        }
    }

    /// Icon for this status
    var icon: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .processing:
            return "arrow.clockwise"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .refunded:
            return "arrow.uturn.backward.circle.fill"
        }
    }
}

// MARK: - Refund

/// Refund information
struct Refund: Codable, Identifiable {

    let id: UUID

    /// Amount refunded
    var amount: Decimal

    /// Date of refund
    var refundDate: Date

    /// Reason for refund
    var reason: String?

    /// Refund method
    var refundMethod: PaymentMethod

    /// Transaction ID for the refund
    var transactionId: String?

    init(amount: Decimal, refundMethod: PaymentMethod, reason: String? = nil) {
        self.id = UUID()
        self.amount = amount
        self.refundDate = Date()
        self.refundMethod = refundMethod
        self.reason = reason
    }
}

// MARK: - Payment Card

/// Stored payment card information (for future use with Stripe/Square)
struct PaymentCard: Codable, Identifiable {

    let id: UUID

    /// Client this card belongs to
    let clientId: UUID

    /// Card type (Visa, Mastercard, etc.)
    var cardType: CardType

    /// Last 4 digits of card number
    var lastFourDigits: String

    /// Cardholder name
    var cardholderName: String

    /// Expiration month (1-12)
    var expirationMonth: Int

    /// Expiration year (4 digits)
    var expirationYear: Int

    /// Billing ZIP code
    var billingZipCode: String?

    /// Is this the default payment method?
    var isDefault: Bool

    /// Token from payment processor (Stripe, Square, etc.)
    var processorToken: String?

    /// When this card was added
    let createdAt: Date

    init(clientId: UUID, cardType: CardType, lastFourDigits: String, cardholderName: String, expirationMonth: Int, expirationYear: Int) {
        self.id = UUID()
        self.clientId = clientId
        self.cardType = cardType
        self.lastFourDigits = lastFourDigits
        self.cardholderName = cardholderName
        self.expirationMonth = expirationMonth
        self.expirationYear = expirationYear
        self.isDefault = false
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    /// Is this card expired?
    var isExpired: Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        if expirationYear < currentYear {
            return true
        } else if expirationYear == currentYear && expirationMonth < currentMonth {
            return true
        }
        return false
    }

    /// Display string (e.g., "Visa •••• 1234")
    var displayString: String {
        return "\(cardType.rawValue) •••• \(lastFourDigits)"
    }

    /// Expiration display string (e.g., "12/2025")
    var expirationDisplay: String {
        return String(format: "%02d/%d", expirationMonth, expirationYear)
    }
}

// MARK: - Card Type

/// Type of credit/debit card
enum CardType: String, Codable, CaseIterable {
    case visa = "Visa"
    case mastercard = "Mastercard"
    case americanExpress = "American Express"
    case discover = "Discover"
    case dinersClub = "Diners Club"
    case jcb = "JCB"
    case unionPay = "UnionPay"
    case unknown = "Unknown"

    /// Icon/image name for this card type
    var iconName: String {
        switch self {
        case .visa:
            return "creditcard.and.123"
        case .mastercard:
            return "creditcard.circle.fill"
        case .americanExpress:
            return "creditcard.fill"
        case .discover:
            return "creditcard"
        default:
            return "creditcard"
        }
    }
}

// MARK: - Receipt

/// Receipt for a payment
struct Receipt: Codable, Identifiable {

    let id: UUID

    /// Payment this receipt is for
    let paymentId: UUID

    /// Invoice this receipt is for
    let invoiceId: UUID

    /// Receipt number
    var receiptNumber: String

    /// Receipt date
    var receiptDate: Date

    /// Amount paid
    var amountPaid: Decimal

    /// Payment method
    var paymentMethod: PaymentMethod

    /// When this receipt was generated
    let generatedAt: Date

    /// Was this receipt emailed to the client?
    var wasEmailed: Bool

    /// When was it emailed?
    var emailedAt: Date?

    init(paymentId: UUID, invoiceId: UUID, receiptNumber: String, amountPaid: Decimal, paymentMethod: PaymentMethod) {
        self.id = UUID()
        self.paymentId = paymentId
        self.invoiceId = invoiceId
        self.receiptNumber = receiptNumber
        self.receiptDate = Date()
        self.amountPaid = amountPaid
        self.paymentMethod = paymentMethod
        self.generatedAt = Date()
        self.wasEmailed = false
    }
}
