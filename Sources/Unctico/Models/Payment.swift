import Foundation

struct Payment: Identifiable, Codable {
    let id: UUID
    var clientId: UUID
    var appointmentId: UUID?
    var amount: Double
    var method: PaymentMethod
    var status: PaymentStatus
    var date: Date
    var notes: String?
    var receiptNumber: String
    var refundedAmount: Double?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        clientId: UUID,
        appointmentId: UUID? = nil,
        amount: Double,
        method: PaymentMethod,
        status: PaymentStatus = .completed,
        date: Date = Date(),
        notes: String? = nil,
        receiptNumber: String = "",
        refundedAmount: Double? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.clientId = clientId
        self.appointmentId = appointmentId
        self.amount = amount
        self.method = method
        self.status = status
        self.date = date
        self.notes = notes
        self.receiptNumber = receiptNumber.isEmpty ? "RCP-\(Int.random(in: 10000...99999))" : receiptNumber
        self.refundedAmount = refundedAmount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var netAmount: Double {
        amount - (refundedAmount ?? 0)
    }
}

enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "Cash"
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case check = "Check"
    case venmo = "Venmo"
    case zelle = "Zelle"
    case applePay = "Apple Pay"
    case insurance = "Insurance"
    case other = "Other"
}

enum PaymentStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case processing = "Processing"
    case completed = "Completed"
    case failed = "Failed"
    case refunded = "Refunded"
    case partiallyRefunded = "Partially Refunded"
}

struct Invoice: Identifiable, Codable {
    let id: UUID
    var clientId: UUID
    var appointmentIds: [UUID]
    var invoiceNumber: String
    var issueDate: Date
    var dueDate: Date
    var subtotal: Double
    var taxRate: Double
    var taxAmount: Double
    var discount: Double
    var total: Double
    var status: InvoiceStatus
    var lineItems: [InvoiceLineItem]
    var notes: String?
    var paidAmount: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        clientId: UUID,
        appointmentIds: [UUID] = [],
        invoiceNumber: String = "",
        issueDate: Date = Date(),
        dueDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
        subtotal: Double,
        taxRate: Double = 0.0,
        discount: Double = 0.0,
        status: InvoiceStatus = .draft,
        lineItems: [InvoiceLineItem],
        notes: String? = nil,
        paidAmount: Double = 0.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.clientId = clientId
        self.appointmentIds = appointmentIds
        self.invoiceNumber = invoiceNumber.isEmpty ? "INV-\(Int.random(in: 1000...9999))" : invoiceNumber
        self.issueDate = issueDate
        self.dueDate = dueDate
        self.subtotal = subtotal
        self.taxRate = taxRate
        self.taxAmount = subtotal * taxRate
        self.discount = discount
        self.total = subtotal + (subtotal * taxRate) - discount
        self.status = status
        self.lineItems = lineItems
        self.notes = notes
        self.paidAmount = paidAmount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var balanceDue: Double {
        total - paidAmount
    }

    var isPaid: Bool {
        paidAmount >= total
    }
}

struct InvoiceLineItem: Identifiable, Codable {
    let id: UUID
    var description: String
    var quantity: Int
    var unitPrice: Double
    var total: Double

    init(
        id: UUID = UUID(),
        description: String,
        quantity: Int = 1,
        unitPrice: Double
    ) {
        self.id = id
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.total = Double(quantity) * unitPrice
    }
}

enum InvoiceStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case sent = "Sent"
    case viewed = "Viewed"
    case partiallyPaid = "Partially Paid"
    case paid = "Paid"
    case overdue = "Overdue"
    case cancelled = "Cancelled"
}
