import Foundation

/// Service for processing payments through various gateways
@MainActor
class PaymentGatewayService: ObservableObject {
    static let shared = PaymentGatewayService()

    @Published var configurations: [PaymentGateway: PaymentGatewayConfig] = [:]
    @Published var activeGateway: PaymentGateway = .manual

    private let configKey = "unctico_payment_gateway_configs"

    init() {
        loadConfigurations()
        initializeDefaultConfigs()
    }

    // MARK: - Configuration Management

    func updateConfiguration(_ config: PaymentGatewayConfig) {
        configurations[config.gateway] = config
        saveConfigurations()
    }

    func getConfiguration(for gateway: PaymentGateway) -> PaymentGatewayConfig? {
        configurations[gateway]
    }

    func setActiveGateway(_ gateway: PaymentGateway) {
        activeGateway = gateway
    }

    private func initializeDefaultConfigs() {
        if configurations.isEmpty {
            configurations = [
                .stripe: PaymentGatewayConfig(
                    gateway: .stripe,
                    supportedCurrencies: ["USD", "EUR", "GBP", "CAD"],
                    processingFeePercentage: 2.9,
                    processingFeeFixed: 0.30
                ),
                .square: PaymentGatewayConfig(
                    gateway: .square,
                    supportedCurrencies: ["USD", "CAD", "GBP", "AUD"],
                    processingFeePercentage: 2.6,
                    processingFeeFixed: 0.10
                ),
                .paypal: PaymentGatewayConfig(
                    gateway: .paypal,
                    supportedCurrencies: ["USD", "EUR", "GBP"],
                    processingFeePercentage: 2.89,
                    processingFeeFixed: 0.49
                ),
                .manual: PaymentGatewayConfig(
                    gateway: .manual,
                    isEnabled: true,
                    testMode: false,
                    processingFeePercentage: 0,
                    processingFeeFixed: 0
                )
            ]
            saveConfigurations()
        }
    }

    // MARK: - Payment Processing

    /// Process a payment through the active gateway
    func processPayment(intent: PaymentIntent) async throws -> PaymentTransaction {
        guard let config = configurations[activeGateway], config.isEnabled else {
            throw PaymentError.gatewayNotConfigured
        }

        // Simulate payment processing
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay

        let processingFee = config.calculateProcessingFee(for: intent.amount)
        let netAmount = config.calculateNetAmount(for: intent.amount)

        let transaction = PaymentTransaction(
            clientId: intent.clientId,
            clientName: intent.clientName,
            appointmentId: intent.appointmentId,
            amount: intent.amount,
            currency: intent.currency,
            gateway: activeGateway,
            status: .completed,
            paymentMethod: .creditCard,
            transactionId: "txn_\(UUID().uuidString.prefix(16))",
            description: intent.description,
            metadata: intent.metadata,
            processingFee: processingFee,
            netAmount: netAmount
        )

        return transaction
    }

    /// Process Stripe payment (would use Stripe SDK in production)
    private func processStripePayment(intent: PaymentIntent, config: PaymentGatewayConfig) async throws -> PaymentTransaction {
        // In production, this would use the Stripe SDK
        // Example:
        // let stripeIntent = try await stripe.createPaymentIntent(
        //     amount: Int(intent.amount * 100),
        //     currency: intent.currency,
        //     metadata: intent.metadata
        // )

        // Simulate API call
        try await Task.sleep(nanoseconds: 1_500_000_000)

        return PaymentTransaction(
            clientId: intent.clientId,
            clientName: intent.clientName,
            appointmentId: intent.appointmentId,
            amount: intent.amount,
            currency: intent.currency,
            gateway: .stripe,
            status: .completed,
            paymentMethod: .creditCard,
            transactionId: "pi_\(UUID().uuidString.prefix(16))",
            description: intent.description,
            cardLast4: "4242",
            cardBrand: .visa,
            processingFee: config.calculateProcessingFee(for: intent.amount),
            netAmount: config.calculateNetAmount(for: intent.amount)
        )
    }

    /// Process Square payment (would use Square SDK in production)
    private func processSquarePayment(intent: PaymentIntent, config: PaymentGatewayConfig) async throws -> PaymentTransaction {
        // In production, this would use the Square SDK
        // Example:
        // let payment = try await square.createPayment(
        //     amount: Money(amount: Int(intent.amount * 100), currency: .usd),
        //     sourceId: sourceId
        // )

        // Simulate API call
        try await Task.sleep(nanoseconds: 1_500_000_000)

        return PaymentTransaction(
            clientId: intent.clientId,
            clientName: intent.clientName,
            appointmentId: intent.appointmentId,
            amount: intent.amount,
            currency: intent.currency,
            gateway: .square,
            status: .completed,
            paymentMethod: .creditCard,
            transactionId: "sqr_\(UUID().uuidString.prefix(16))",
            description: intent.description,
            cardLast4: "1234",
            cardBrand: .mastercard,
            processingFee: config.calculateProcessingFee(for: intent.amount),
            netAmount: config.calculateNetAmount(for: intent.amount)
        )
    }

    /// Process manual payment (cash, check)
    func processManualPayment(intent: PaymentIntent, paymentMethod: PaymentMethod, checkNumber: String? = nil) -> PaymentTransaction {
        var metadata = intent.metadata
        if let checkNum = checkNumber {
            metadata["check_number"] = checkNum
        }

        return PaymentTransaction(
            clientId: intent.clientId,
            clientName: intent.clientName,
            appointmentId: intent.appointmentId,
            amount: intent.amount,
            currency: intent.currency,
            gateway: .manual,
            status: .completed,
            paymentMethod: paymentMethod,
            description: intent.description,
            metadata: metadata,
            processingFee: 0,
            netAmount: intent.amount
        )
    }

    // MARK: - Refund Processing

    /// Process a refund
    func processRefund(request: RefundRequest, transaction: PaymentTransaction) async throws -> PaymentTransaction {
        guard transaction.status == .completed else {
            throw PaymentError.cannotRefundTransaction
        }

        guard request.amount <= transaction.amount else {
            throw PaymentError.refundAmountExceedsOriginal
        }

        // Simulate refund processing
        try await Task.sleep(nanoseconds: 1_500_000_000)

        let refundedTotal = (transaction.refundedAmount ?? 0) + request.amount
        let newStatus: TransactionStatus = refundedTotal >= transaction.amount ? .refunded : .partialRefund

        return PaymentTransaction(
            id: transaction.id,
            clientId: transaction.clientId,
            clientName: transaction.clientName,
            appointmentId: transaction.appointmentId,
            amount: transaction.amount,
            currency: transaction.currency,
            gateway: transaction.gateway,
            transactionDate: transaction.transactionDate,
            status: newStatus,
            paymentMethod: transaction.paymentMethod,
            transactionId: transaction.transactionId,
            receiptNumber: transaction.receiptNumber,
            description: transaction.description,
            notes: transaction.notes,
            metadata: transaction.metadata,
            refundedAmount: refundedTotal,
            refundDate: Date(),
            refundReason: request.reason.rawValue + (request.notes.isEmpty ? "" : ": \(request.notes)"),
            cardLast4: transaction.cardLast4,
            cardBrand: transaction.cardBrand,
            processingFee: transaction.processingFee,
            netAmount: transaction.netAmount
        )
    }

    // MARK: - Payment Links

    /// Create a payment link for online payment
    func createPaymentLink(
        amount: Double,
        description: String,
        clientId: UUID,
        clientEmail: String?,
        expiresInDays: Int = 7
    ) -> PaymentLink {
        let expirationDate = Calendar.current.date(byAdding: .day, value: expiresInDays, to: Date())

        return PaymentLink(
            amount: amount,
            description: description,
            clientId: clientId,
            clientEmail: clientEmail,
            expiresAt: expirationDate
        )
    }

    /// Mark payment link as paid
    func markPaymentLinkAsPaid(_ link: PaymentLink, transaction: PaymentTransaction) -> PaymentLink {
        PaymentLink(
            id: link.id,
            linkId: link.linkId,
            amount: link.amount,
            description: link.description,
            clientId: link.clientId,
            clientEmail: link.clientEmail,
            expiresAt: link.expiresAt,
            createdAt: link.createdAt,
            isActive: false,
            paymentStatus: .paid,
            completedAt: Date()
        )
    }

    // MARK: - Receipt Generation

    /// Generate a receipt for a transaction
    func generateReceipt(
        for transaction: PaymentTransaction,
        businessInfo: ReceiptBusinessInfo,
        lineItems: [LineItem],
        tax: Double = 0,
        tip: Double = 0,
        discount: Double = 0,
        clientEmail: String? = nil
    ) -> Receipt {
        let subtotal = lineItems.reduce(0) { $0 + $1.total }
        let total = subtotal + tax + tip - discount

        return Receipt(
            receiptNumber: transaction.receiptNumber,
            transactionId: transaction.id,
            clientName: transaction.clientName,
            clientEmail: clientEmail,
            businessInfo: businessInfo,
            lineItems: lineItems,
            subtotal: subtotal,
            tax: tax,
            tip: tip,
            discount: discount,
            total: total,
            paymentMethod: transaction.paymentMethod,
            cardLast4: transaction.cardLast4
        )
    }

    /// Generate PDF receipt (placeholder - would use actual PDF generation)
    func generateReceiptPDF(receipt: Receipt) -> Data {
        // In production, this would generate an actual PDF
        // Using libraries like PDFKit
        let receiptText = """
        RECEIPT

        Receipt #: \(receipt.receiptNumber)
        Date: \(receipt.issueDate)

        \(receipt.businessInfo.name)
        \(receipt.businessInfo.address)
        \(receipt.businessInfo.phone)
        \(receipt.businessInfo.email)

        Bill To:
        \(receipt.clientName)
        \(receipt.clientEmail ?? "")

        Items:
        \(receipt.lineItems.map { "- \($0.description): $\(String(format: "%.2f", $0.total))" }.joined(separator: "\n"))

        Subtotal: $\(String(format: "%.2f", receipt.subtotal))
        Tax: $\(String(format: "%.2f", receipt.tax))
        Tip: $\(String(format: "%.2f", receipt.tip))
        Discount: -$\(String(format: "%.2f", receipt.discount))

        TOTAL: $\(String(format: "%.2f", receipt.total))

        Payment Method: \(receipt.paymentMethod.rawValue)
        \(receipt.cardLast4 != nil ? "Card ending in \(receipt.cardLast4!)" : "")

        Thank you for your business!
        """

        return receiptText.data(using: .utf8) ?? Data()
    }

    // MARK: - Validation

    func validatePaymentAmount(_ amount: Double) throws {
        guard amount > 0 else {
            throw PaymentError.invalidAmount
        }

        guard amount <= 999999.99 else {
            throw PaymentError.amountTooLarge
        }
    }

    func validateGatewayConfig(_ gateway: PaymentGateway) throws {
        guard let config = configurations[gateway] else {
            throw PaymentError.gatewayNotConfigured
        }

        guard config.isEnabled else {
            throw PaymentError.gatewayDisabled
        }

        if gateway != .manual {
            guard !config.apiKey.isEmpty && !config.secretKey.isEmpty else {
                throw PaymentError.missingCredentials
            }
        }
    }

    // MARK: - Webhooks (for production)

    /// Handle webhook from payment gateway
    func handleWebhook(gateway: PaymentGateway, payload: Data, signature: String) async throws {
        guard let config = configurations[gateway] else {
            throw PaymentError.gatewayNotConfigured
        }

        // In production, verify webhook signature
        // For Stripe: Stripe.verifyWebhookSignature(payload, signature, config.webhookSecret)
        // For Square: Square.verifyWebhookSignature(payload, signature, config.webhookSecret)

        // Process webhook event
        // This would handle events like:
        // - payment_intent.succeeded
        // - payment_intent.failed
        // - charge.refunded
        // - charge.disputed
    }

    // MARK: - Persistence

    private func loadConfigurations() {
        if let data = UserDefaults.standard.data(forKey: configKey),
           let decoded = try? JSONDecoder().decode([PaymentGateway: PaymentGatewayConfig].self, from: data) {
            configurations = decoded
        }
    }

    private func saveConfigurations() {
        if let encoded = try? JSONEncoder().encode(configurations) {
            UserDefaults.standard.set(encoded, forKey: configKey)
        }
    }
}

// MARK: - Error Types

enum PaymentError: LocalizedError {
    case gatewayNotConfigured
    case gatewayDisabled
    case missingCredentials
    case invalidAmount
    case amountTooLarge
    case cannotRefundTransaction
    case refundAmountExceedsOriginal
    case networkError
    case processingError(String)

    var errorDescription: String? {
        switch self {
        case .gatewayNotConfigured:
            return "Payment gateway is not configured"
        case .gatewayDisabled:
            return "Payment gateway is disabled"
        case .missingCredentials:
            return "Payment gateway credentials are missing"
        case .invalidAmount:
            return "Payment amount must be greater than 0"
        case .amountTooLarge:
            return "Payment amount exceeds maximum allowed"
        case .cannotRefundTransaction:
            return "This transaction cannot be refunded"
        case .refundAmountExceedsOriginal:
            return "Refund amount exceeds original transaction amount"
        case .networkError:
            return "Network error occurred"
        case .processingError(let message):
            return "Payment processing error: \(message)"
        }
    }
}
