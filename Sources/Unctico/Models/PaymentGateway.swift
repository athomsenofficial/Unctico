import Foundation
import SwiftUI

/// Payment gateway integration models for Stripe and Square
enum PaymentGateway: String, Codable, CaseIterable {
    case stripe = "Stripe"
    case square = "Square"
    case paypal = "PayPal"
    case manual = "Manual (Cash/Check)"

    var icon: String {
        switch self {
        case .stripe: return "creditcard.fill"
        case .square: return "square.fill"
        case .paypal: return "dollarsign.circle.fill"
        case .manual: return "banknote.fill"
        }
    }

    var color: Color {
        switch self {
        case .stripe: return .purple
        case .square: return .blue
        case .paypal: return .cyan
        case .manual: return .green
        }
    }
}

/// Payment transaction model
struct PaymentTransaction: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    let clientName: String
    let appointmentId: UUID?
    let amount: Double
    let currency: String
    let gateway: PaymentGateway
    let transactionDate: Date
    let status: TransactionStatus
    let paymentMethod: PaymentMethod
    let transactionId: String? // Gateway transaction ID
    let receiptNumber: String
    let description: String
    let notes: String
    let metadata: [String: String]

    // Refund information
    let refundedAmount: Double?
    let refundDate: Date?
    let refundReason: String?

    // Card information (last 4 digits only for security)
    let cardLast4: String?
    let cardBrand: CardBrand?

    // Processing fees
    let processingFee: Double?
    let netAmount: Double?

    init(
        id: UUID = UUID(),
        clientId: UUID,
        clientName: String,
        appointmentId: UUID? = nil,
        amount: Double,
        currency: String = "USD",
        gateway: PaymentGateway,
        transactionDate: Date = Date(),
        status: TransactionStatus = .pending,
        paymentMethod: PaymentMethod,
        transactionId: String? = nil,
        receiptNumber: String = "",
        description: String,
        notes: String = "",
        metadata: [String: String] = [:],
        refundedAmount: Double? = nil,
        refundDate: Date? = nil,
        refundReason: String? = nil,
        cardLast4: String? = nil,
        cardBrand: CardBrand? = nil,
        processingFee: Double? = nil,
        netAmount: Double? = nil
    ) {
        self.id = id
        self.clientId = clientId
        self.clientName = clientName
        self.appointmentId = appointmentId
        self.amount = amount
        self.currency = currency
        self.gateway = gateway
        self.transactionDate = transactionDate
        self.status = status
        self.paymentMethod = paymentMethod
        self.transactionId = transactionId
        self.receiptNumber = receiptNumber.isEmpty ? "RCT-\(id.uuidString.prefix(8).uppercased())" : receiptNumber
        self.description = description
        self.notes = notes
        self.metadata = metadata
        self.refundedAmount = refundedAmount
        self.refundDate = refundDate
        self.refundReason = refundReason
        self.cardLast4 = cardLast4
        self.cardBrand = cardBrand
        self.processingFee = processingFee
        self.netAmount = netAmount ?? amount
    }

    var isRefunded: Bool {
        refundedAmount != nil && refundedAmount! > 0
    }

    var refundPercentage: Double {
        guard let refunded = refundedAmount, amount > 0 else { return 0 }
        return (refunded / amount) * 100
    }
}

enum TransactionStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case processing = "Processing"
    case completed = "Completed"
    case failed = "Failed"
    case refunded = "Refunded"
    case partialRefund = "Partially Refunded"
    case disputed = "Disputed"
    case cancelled = "Cancelled"

    var color: Color {
        switch self {
        case .pending, .processing: return .orange
        case .completed: return .green
        case .failed, .disputed, .cancelled: return .red
        case .refunded, .partialRefund: return .purple
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .processing: return "arrow.clockwise"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .refunded, .partialRefund: return "arrow.uturn.backward.circle.fill"
        case .disputed: return "exclamationmark.triangle.fill"
        case .cancelled: return "slash.circle.fill"
        }
    }
}

enum PaymentMethod: String, Codable, CaseIterable {
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case cash = "Cash"
    case check = "Check"
    case ach = "ACH/Bank Transfer"
    case applePay = "Apple Pay"
    case googlePay = "Google Pay"
    case giftCard = "Gift Card"
    case other = "Other"

    var icon: String {
        switch self {
        case .creditCard, .debitCard: return "creditcard.fill"
        case .cash: return "dollarsign.circle.fill"
        case .check: return "doc.text.fill"
        case .ach: return "building.columns.fill"
        case .applePay: return "apple.logo"
        case .googlePay: return "g.circle.fill"
        case .giftCard: return "gift.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum CardBrand: String, Codable {
    case visa = "Visa"
    case mastercard = "Mastercard"
    case amex = "American Express"
    case discover = "Discover"
    case jcb = "JCB"
    case dinersClub = "Diners Club"
    case unionPay = "UnionPay"
    case unknown = "Unknown"

    var icon: String {
        switch self {
        case .visa: return "creditcard.fill"
        case .mastercard: return "creditcard.fill"
        case .amex: return "creditcard.fill"
        case .discover: return "creditcard.fill"
        default: return "creditcard"
        }
    }
}

/// Payment intent for processing payments
struct PaymentIntent {
    let amount: Double
    let currency: String
    let clientId: UUID
    let clientName: String
    let clientEmail: String?
    let description: String
    let metadata: [String: String]
    let appointmentId: UUID?

    init(
        amount: Double,
        currency: String = "USD",
        clientId: UUID,
        clientName: String,
        clientEmail: String? = nil,
        description: String,
        metadata: [String: String] = [:],
        appointmentId: UUID? = nil
    ) {
        self.amount = amount
        self.currency = currency
        self.clientId = clientId
        self.clientName = clientName
        self.clientEmail = clientEmail
        self.description = description
        self.metadata = metadata
        self.appointmentId = appointmentId
    }
}

/// Refund request
struct RefundRequest {
    let transactionId: UUID
    let amount: Double // Refund amount (can be partial)
    let reason: RefundReason
    let notes: String

    init(transactionId: UUID, amount: Double, reason: RefundReason, notes: String = "") {
        self.transactionId = transactionId
        self.amount = amount
        self.reason = reason
        self.notes = notes
    }
}

enum RefundReason: String, Codable, CaseIterable {
    case duplicate = "Duplicate Payment"
    case fraudulent = "Fraudulent"
    case requestedByCustomer = "Requested by Customer"
    case serviceNotProvided = "Service Not Provided"
    case clientCancellation = "Client Cancellation"
    case billingError = "Billing Error"
    case other = "Other"
}

/// Receipt information
struct Receipt: Identifiable, Codable {
    let id: UUID
    let receiptNumber: String
    let transactionId: UUID
    let issueDate: Date
    let clientName: String
    let clientEmail: String?
    let businessInfo: ReceiptBusinessInfo
    let lineItems: [LineItem]
    let subtotal: Double
    let tax: Double
    let tip: Double
    let discount: Double
    let total: Double
    let paymentMethod: PaymentMethod
    let cardLast4: String?
    let notes: String

    init(
        id: UUID = UUID(),
        receiptNumber: String,
        transactionId: UUID,
        issueDate: Date = Date(),
        clientName: String,
        clientEmail: String? = nil,
        businessInfo: ReceiptBusinessInfo,
        lineItems: [LineItem],
        subtotal: Double,
        tax: Double = 0,
        tip: Double = 0,
        discount: Double = 0,
        total: Double,
        paymentMethod: PaymentMethod,
        cardLast4: String? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.receiptNumber = receiptNumber
        self.transactionId = transactionId
        self.issueDate = issueDate
        self.clientName = clientName
        self.clientEmail = clientEmail
        self.businessInfo = businessInfo
        self.lineItems = lineItems
        self.subtotal = subtotal
        self.tax = tax
        self.tip = tip
        self.discount = discount
        self.total = total
        self.paymentMethod = paymentMethod
        self.cardLast4 = cardLast4
        self.notes = notes
    }
}

struct ReceiptBusinessInfo: Codable {
    let name: String
    let address: String
    let phone: String
    let email: String
    let taxId: String?
    let licenseNumber: String?

    init(name: String, address: String, phone: String, email: String, taxId: String? = nil, licenseNumber: String? = nil) {
        self.name = name
        self.address = address
        self.phone = phone
        self.email = email
        self.taxId = taxId
        self.licenseNumber = licenseNumber
    }
}

struct LineItem: Identifiable, Codable {
    let id: UUID
    let description: String
    let quantity: Int
    let unitPrice: Double
    let total: Double

    init(id: UUID = UUID(), description: String, quantity: Int = 1, unitPrice: Double) {
        self.id = id
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.total = Double(quantity) * unitPrice
    }
}

/// Payment gateway configuration
struct PaymentGatewayConfig: Codable {
    let gateway: PaymentGateway
    let isEnabled: Bool
    let apiKey: String // Encrypted in production
    let secretKey: String // Encrypted in production
    let webhookSecret: String?
    let testMode: Bool
    let supportedCurrencies: [String]
    let processingFeePercentage: Double
    let processingFeeFixed: Double

    init(
        gateway: PaymentGateway,
        isEnabled: Bool = false,
        apiKey: String = "",
        secretKey: String = "",
        webhookSecret: String? = nil,
        testMode: Bool = true,
        supportedCurrencies: [String] = ["USD"],
        processingFeePercentage: Double = 2.9,
        processingFeeFixed: Double = 0.30
    ) {
        self.gateway = gateway
        self.isEnabled = isEnabled
        self.apiKey = apiKey
        self.secretKey = secretKey
        self.webhookSecret = webhookSecret
        self.testMode = testMode
        self.supportedCurrencies = supportedCurrencies
        self.processingFeePercentage = processingFeePercentage
        self.processingFeeFixed = processingFeeFixed
    }

    func calculateProcessingFee(for amount: Double) -> Double {
        (amount * processingFeePercentage / 100) + processingFeeFixed
    }

    func calculateNetAmount(for amount: Double) -> Double {
        amount - calculateProcessingFee(for: amount)
    }
}

/// Payment dispute/chargeback
struct PaymentDispute: Identifiable, Codable {
    let id: UUID
    let transactionId: UUID
    let amount: Double
    let reason: DisputeReason
    let status: DisputeStatus
    let openedDate: Date
    let dueDate: Date?
    let resolvedDate: Date?
    let evidence: [DisputeEvidence]
    let notes: String

    init(
        id: UUID = UUID(),
        transactionId: UUID,
        amount: Double,
        reason: DisputeReason,
        status: DisputeStatus = .open,
        openedDate: Date = Date(),
        dueDate: Date? = nil,
        resolvedDate: Date? = nil,
        evidence: [DisputeEvidence] = [],
        notes: String = ""
    ) {
        self.id = id
        self.transactionId = transactionId
        self.amount = amount
        self.reason = reason
        self.status = status
        self.openedDate = openedDate
        self.dueDate = dueDate
        self.resolvedDate = resolvedDate
        self.evidence = evidence
        self.notes = notes
    }
}

enum DisputeReason: String, Codable {
    case fraudulent = "Fraudulent"
    case unrecognized = "Unrecognized"
    case duplicate = "Duplicate"
    case productNotReceived = "Product Not Received"
    case productUnacceptable = "Product Unacceptable"
    case other = "Other"
}

enum DisputeStatus: String, Codable {
    case open = "Open"
    case underReview = "Under Review"
    case won = "Won"
    case lost = "Lost"
    case closed = "Closed"
}

struct DisputeEvidence: Identifiable, Codable {
    let id: UUID
    let type: EvidenceType
    let description: String
    let documentPath: String?
    let uploadedDate: Date

    init(id: UUID = UUID(), type: EvidenceType, description: String, documentPath: String? = nil, uploadedDate: Date = Date()) {
        self.id = id
        self.type = type
        self.description = description
        self.documentPath = documentPath
        self.uploadedDate = uploadedDate
    }
}

enum EvidenceType: String, Codable {
    case receipt = "Receipt"
    case signedAgreement = "Signed Agreement"
    case communicationLog = "Communication Log"
    case serviceConfirmation = "Service Confirmation"
    case appointmentRecord = "Appointment Record"
    case other = "Other"
}

/// Payment link for online payments
struct PaymentLink: Identifiable, Codable {
    let id: UUID
    let linkId: String
    let amount: Double
    let description: String
    let clientId: UUID
    let clientEmail: String?
    let expiresAt: Date?
    let createdAt: Date
    let isActive: Bool
    let paymentStatus: LinkPaymentStatus
    let completedAt: Date?

    init(
        id: UUID = UUID(),
        linkId: String = UUID().uuidString,
        amount: Double,
        description: String,
        clientId: UUID,
        clientEmail: String? = nil,
        expiresAt: Date? = nil,
        createdAt: Date = Date(),
        isActive: Bool = true,
        paymentStatus: LinkPaymentStatus = .pending,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.linkId = linkId
        self.amount = amount
        self.description = description
        self.clientId = clientId
        self.clientEmail = clientEmail
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.isActive = isActive
        self.paymentStatus = paymentStatus
        self.completedAt = completedAt
    }

    var isExpired: Bool {
        guard let expiration = expiresAt else { return false }
        return Date() > expiration
    }

    var url: String {
        "https://payment.unctico.app/\(linkId)"
    }
}

enum LinkPaymentStatus: String, Codable {
    case pending = "Pending"
    case paid = "Paid"
    case expired = "Expired"
    case cancelled = "Cancelled"
}
