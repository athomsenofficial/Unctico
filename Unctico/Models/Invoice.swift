// Invoice.swift
// Invoice model for billing clients

import Foundation

/// Represents an invoice for services rendered
struct Invoice: Codable, Identifiable {

    // MARK: - Properties

    /// Unique identifier
    let id: UUID

    /// Invoice number (e.g., "INV-2024-001")
    var invoiceNumber: String

    /// Client this invoice is for
    let clientId: UUID

    /// Related appointment (if applicable)
    var appointmentId: UUID?

    /// Invoice date
    var invoiceDate: Date

    /// Due date for payment
    var dueDate: Date

    /// Current status of the invoice
    var status: InvoiceStatus

    /// Line items on this invoice
    var lineItems: [InvoiceLineItem]

    /// Subtotal (before tax)
    var subtotal: Decimal {
        lineItems.reduce(0) { $0 + $1.total }
    }

    /// Tax rate (as decimal, e.g., 0.08 for 8%)
    var taxRate: Decimal

    /// Tax amount
    var taxAmount: Decimal {
        subtotal * taxRate
    }

    /// Discount amount (if any)
    var discountAmount: Decimal

    /// Discount percentage (if applicable)
    var discountPercentage: Decimal?

    /// Total amount due
    var totalAmount: Decimal {
        subtotal + taxAmount - discountAmount
    }

    /// Amount already paid
    var paidAmount: Decimal

    /// Remaining balance
    var balanceRemaining: Decimal {
        totalAmount - paidAmount
    }

    // MARK: - Payment Details

    /// Associated payments
    var payments: [Payment]

    /// Payment terms (e.g., "Net 30", "Due on receipt")
    var paymentTerms: String

    /// Late fee amount (if applicable)
    var lateFeeAmount: Decimal?

    // MARK: - Notes and Metadata

    /// Notes to client
    var notes: String?

    /// Internal memo (not shown to client)
    var memo: String?

    /// When this invoice was created
    let createdAt: Date

    /// When this invoice was last updated
    var updatedAt: Date

    /// When this invoice was sent to client
    var sentAt: Date?

    /// When this invoice was paid in full
    var paidAt: Date?

    /// Who created this invoice
    var createdBy: String?

    // MARK: - Initialization

    /// Create a new invoice
    /// - Parameters:
    ///   - clientId: ID of the client
    ///   - invoiceNumber: Invoice number
    ///   - invoiceDate: Date of invoice
    ///   - dueDate: Payment due date
    init(clientId: UUID, invoiceNumber: String, invoiceDate: Date = Date(), dueDate: Date) {
        self.id = UUID()
        self.clientId = clientId
        self.invoiceNumber = invoiceNumber
        self.invoiceDate = invoiceDate
        self.dueDate = dueDate
        self.status = .draft
        self.lineItems = []
        self.taxRate = 0
        self.discountAmount = 0
        self.paidAmount = 0
        self.payments = []
        self.paymentTerms = "Due on receipt"
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Is this invoice fully paid?
    var isPaid: Bool {
        return balanceRemaining <= 0 && paidAmount > 0
    }

    /// Is this invoice partially paid?
    var isPartiallyPaid: Bool {
        return paidAmount > 0 && balanceRemaining > 0
    }

    /// Is this invoice overdue?
    var isOverdue: Bool {
        return status == .sent && dueDate < Date() && !isPaid
    }

    /// Days until due (negative if overdue)
    var daysUntilDue: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: dueDate)
        return components.day ?? 0
    }

    /// Age of invoice in days
    var ageInDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: invoiceDate, to: Date())
        return components.day ?? 0
    }

    /// Can this invoice be edited?
    var canBeEdited: Bool {
        return status == .draft
    }

    /// Can this invoice be sent?
    var canBeSent: Bool {
        return status == .draft && !lineItems.isEmpty
    }

    /// Can this invoice be voided?
    var canBeVoided: Bool {
        return status != .void && status != .paid
    }

    /// Payment completion percentage
    var paymentPercentage: Double {
        guard totalAmount > 0 else { return 0 }
        return Double(truncating: (paidAmount / totalAmount * 100) as NSDecimalNumber)
    }

    // MARK: - Methods

    /// Add a line item to the invoice
    mutating func addLineItem(_ item: InvoiceLineItem) {
        lineItems.append(item)
        updatedAt = Date()
    }

    /// Remove a line item from the invoice
    mutating func removeLineItem(at index: Int) {
        guard index < lineItems.count else { return }
        lineItems.remove(at: index)
        updatedAt = Date()
    }

    /// Apply a discount
    mutating func applyDiscount(amount: Decimal) {
        discountAmount = amount
        discountPercentage = nil
        updatedAt = Date()
    }

    /// Apply a discount percentage
    mutating func applyDiscountPercentage(_ percentage: Decimal) {
        discountPercentage = percentage
        discountAmount = subtotal * (percentage / 100)
        updatedAt = Date()
    }

    /// Record a payment
    mutating func recordPayment(_ payment: Payment) {
        payments.append(payment)
        paidAmount += payment.amount
        updatedAt = Date()

        // Update status
        if isPaid {
            status = .paid
            paidAt = Date()
        } else if isPartiallyPaid {
            status = .partiallyPaid
        }
    }

    /// Mark invoice as sent
    mutating func markAsSent() {
        status = .sent
        sentAt = Date()
        updatedAt = Date()
    }

    /// Void the invoice
    mutating func void() {
        status = .void
        updatedAt = Date()
    }
}

// MARK: - Invoice Status

/// Status of an invoice
enum InvoiceStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case sent = "Sent"
    case partiallyPaid = "Partially Paid"
    case paid = "Paid"
    case overdue = "Overdue"
    case void = "Void"

    /// Color for this status
    var color: String {
        switch self {
        case .draft:
            return "gray"
        case .sent:
            return "blue"
        case .partiallyPaid:
            return "orange"
        case .paid:
            return "green"
        case .overdue:
            return "red"
        case .void:
            return "red"
        }
    }

    /// Icon for this status
    var icon: String {
        switch self {
        case .draft:
            return "doc.text"
        case .sent:
            return "paperplane.fill"
        case .partiallyPaid:
            return "dollarsign.circle"
        case .paid:
            return "checkmark.seal.fill"
        case .overdue:
            return "exclamationmark.triangle.fill"
        case .void:
            return "xmark.circle.fill"
        }
    }
}

// MARK: - Invoice Line Item

/// A single line item on an invoice
struct InvoiceLineItem: Codable, Identifiable {

    // MARK: - Properties

    let id: UUID

    /// Description of the service/product
    var description: String

    /// Quantity
    var quantity: Decimal

    /// Unit price
    var unitPrice: Decimal

    /// Total for this line item
    var total: Decimal {
        quantity * unitPrice
    }

    /// Is this line item taxable?
    var isTaxable: Bool

    /// Category (for reporting)
    var category: String?

    // MARK: - Initialization

    init(description: String, quantity: Decimal = 1, unitPrice: Decimal, isTaxable: Bool = true) {
        self.id = UUID()
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.isTaxable = isTaxable
    }

    // MARK: - Convenience Initializers

    /// Create line item from an appointment
    static func fromAppointment(_ appointment: Appointment, price: Decimal) -> InvoiceLineItem {
        let description = "\(appointment.serviceType.rawValue) (\(appointment.durationMinutes) min)"
        return InvoiceLineItem(description: description, quantity: 1, unitPrice: price)
    }
}

// MARK: - Invoice Template

/// Template for generating invoices
struct InvoiceTemplate: Codable, Identifiable {

    let id: UUID

    /// Template name
    var name: String

    /// Default payment terms
    var defaultPaymentTerms: String

    /// Default due date offset (days from invoice date)
    var defaultDueDateOffset: Int

    /// Default tax rate
    var defaultTaxRate: Decimal

    /// Header text
    var headerText: String?

    /// Footer text
    var footerText: String?

    /// Show company logo?
    var showLogo: Bool

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.defaultPaymentTerms = "Due on receipt"
        self.defaultDueDateOffset = 0
        self.defaultTaxRate = 0
        self.showLogo = true
    }
}
