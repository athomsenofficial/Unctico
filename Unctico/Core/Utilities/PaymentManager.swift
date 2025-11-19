// PaymentManager.swift
// Manages payment processing and recording

import Foundation
import SwiftUI

/// Manages all payment operations
/// Use this for processing payments, refunds, and managing payment methods
class PaymentManager: ObservableObject {

    // MARK: - Published Properties

    /// All payments (in-memory for now, will connect to Core Data)
    @Published var payments: [Payment] = []

    /// Stored payment cards
    @Published var savedCards: [PaymentCard] = []

    /// Is loading?
    @Published var isLoading: Bool = false

    /// Error message
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let databaseManager: DatabaseManager
    private let invoiceManager: InvoiceManager
    private var nextReceiptNumber: Int = 1

    // MARK: - Initialization

    init(databaseManager: DatabaseManager = DatabaseManager(), invoiceManager: InvoiceManager) {
        self.databaseManager = databaseManager
        self.invoiceManager = invoiceManager
        loadPayments()
        loadSavedCards()
    }

    // MARK: - Public Methods

    /// Load all payments from database
    func loadPayments() {
        // TODO: Load from Core Data
        // For now, using in-memory array
    }

    /// Load saved payment cards
    func loadSavedCards() {
        // TODO: Load from Core Data
        // For now, using in-memory array
    }

    /// Record a payment
    /// - Parameters:
    ///   - invoiceId: Invoice being paid
    ///   - clientId: Client making payment
    ///   - amount: Amount being paid
    ///   - paymentMethod: Method of payment
    ///   - referenceNumber: Optional reference (check #, transaction ID)
    /// - Returns: The created payment, or nil if failed
    func recordPayment(
        for invoiceId: UUID,
        clientId: UUID,
        amount: Decimal,
        paymentMethod: PaymentMethod,
        referenceNumber: String? = nil
    ) -> Payment? {

        // Validate amount
        guard amount > 0 else {
            errorMessage = "Payment amount must be greater than zero"
            return nil
        }

        // Get the invoice
        guard let invoiceIndex = invoiceManager.invoices.firstIndex(where: { $0.id == invoiceId }) else {
            errorMessage = "Invoice not found"
            return nil
        }

        var invoice = invoiceManager.invoices[invoiceIndex]

        // Check if payment amount exceeds balance
        if amount > invoice.balanceRemaining {
            errorMessage = "Payment amount exceeds invoice balance (\(CurrencyFormatter.format(invoice.balanceRemaining)))"
            return nil
        }

        // Create the payment
        var payment = Payment(
            invoiceId: invoiceId,
            clientId: clientId,
            amount: amount,
            paymentMethod: paymentMethod
        )

        payment.referenceNumber = referenceNumber
        payment.status = .completed

        // Add to payments list
        payments.append(payment)

        // Update the invoice
        invoice.recordPayment(payment)
        invoiceManager.updateInvoice(invoice)

        // TODO: Save to Core Data

        errorMessage = nil
        return payment
    }

    /// Process a credit card payment (requires Stripe/Square integration)
    /// - Parameters:
    ///   - invoiceId: Invoice being paid
    ///   - amount: Amount to charge
    ///   - cardToken: Payment processor token
    /// - Returns: The payment if successful
    func processCreditCardPayment(
        for invoiceId: UUID,
        amount: Decimal,
        cardToken: String
    ) async -> Payment? {

        // TODO: Integrate with Stripe or Square

        isLoading = true

        // Simulate API call
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        await MainActor.run {
            isLoading = false
        }

        // For now, just record it as a completed payment
        guard let invoice = invoiceManager.invoices.first(where: { $0.id == invoiceId }) else {
            await MainActor.run {
                errorMessage = "Invoice not found"
            }
            return nil
        }

        // In production, this would call Stripe/Square API:
        // let result = try await stripeAPI.createCharge(amount: amount, token: cardToken)
        // if result.success {
        //     return recordPayment(...)
        // }

        let payment = recordPayment(
            for: invoiceId,
            clientId: invoice.clientId,
            amount: amount,
            paymentMethod: .creditCard,
            referenceNumber: "DEMO-\(UUID().uuidString.prefix(8))"
        )

        return payment
    }

    /// Issue a refund
    /// - Parameters:
    ///   - paymentId: Payment to refund
    ///   - amount: Amount to refund (can be partial)
    ///   - reason: Reason for refund
    /// - Returns: True if successful
    func issueRefund(
        for paymentId: UUID,
        amount: Decimal,
        reason: String? = nil
    ) -> Bool {

        guard let paymentIndex = payments.firstIndex(where: { $0.id == paymentId }) else {
            errorMessage = "Payment not found"
            return false
        }

        var payment = payments[paymentIndex]

        // Validate refund amount
        guard amount > 0 && amount <= payment.amount else {
            errorMessage = "Invalid refund amount"
            return false
        }

        // Check if already refunded
        if payment.isRefunded {
            errorMessage = "Payment has already been refunded"
            return false
        }

        // Create refund
        let refund = Refund(
            amount: amount,
            refundMethod: payment.paymentMethod,
            reason: reason
        )

        payment.refund = refund
        payment.status = .refunded
        payment.updatedAt = Date()

        payments[paymentIndex] = payment

        // Update the invoice to reduce paid amount
        if let invoiceIndex = invoiceManager.invoices.firstIndex(where: { $0.id == payment.invoiceId }) {
            var invoice = invoiceManager.invoices[invoiceIndex]
            invoice.paidAmount -= amount
            invoice.updatedAt = Date()

            // Update status if no longer paid
            if invoice.paidAmount < invoice.totalAmount {
                invoice.status = invoice.paidAmount > 0 ? .partiallyPaid : .sent
            }

            invoiceManager.updateInvoice(invoice)
        }

        // TODO: Save to Core Data
        // TODO: Process actual refund via payment gateway

        errorMessage = nil
        return true
    }

    /// Get payments for a specific invoice
    /// - Parameter invoiceId: Invoice ID
    /// - Returns: Array of payments
    func payments(for invoiceId: UUID) -> [Payment] {
        return payments.filter { $0.invoiceId == invoiceId }
            .sorted { $0.paymentDate > $1.paymentDate }
    }

    /// Get payments for a specific client
    /// - Parameter clientId: Client ID
    /// - Returns: Array of payments
    func payments(for clientId: UUID) -> [Payment] {
        return payments.filter { $0.clientId == clientId }
            .sorted { $0.paymentDate > $1.paymentDate }
    }

    /// Get payments for a date range
    /// - Parameters:
    ///   - startDate: Start of range
    ///   - endDate: End of range
    /// - Returns: Array of payments
    func payments(from startDate: Date, to endDate: Date) -> [Payment] {
        return payments.filter { payment in
            payment.paymentDate >= startDate && payment.paymentDate <= endDate
        }.sorted { $0.paymentDate > $1.paymentDate }
    }

    /// Get total payments received in a date range
    /// - Parameters:
    ///   - startDate: Start of range
    ///   - endDate: End of range
    /// - Returns: Total amount
    func totalPayments(from startDate: Date, to endDate: Date) -> Decimal {
        return payments(from: startDate, to: endDate)
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.netAmount }
    }

    /// Generate a receipt for a payment
    /// - Parameter paymentId: Payment ID
    /// - Returns: The generated receipt
    func generateReceipt(for paymentId: UUID) -> Receipt? {
        guard let payment = payments.first(where: { $0.id == paymentId }) else {
            errorMessage = "Payment not found"
            return nil
        }

        let receiptNumber = generateReceiptNumber()

        let receipt = Receipt(
            paymentId: payment.id,
            invoiceId: payment.invoiceId,
            receiptNumber: receiptNumber,
            amountPaid: payment.amount,
            paymentMethod: payment.paymentMethod
        )

        // TODO: Save receipt to database
        // TODO: Optionally email receipt to client

        return receipt
    }

    /// Send receipt via email
    /// - Parameters:
    ///   - receipt: The receipt to send
    ///   - email: Email address
    func sendReceipt(_ receipt: Receipt, to email: String) async {
        // TODO: Implement email sending via backend

        print("📧 Would send receipt \(receipt.receiptNumber) to: \(email)")

        // Example implementation:
        // let emailBody = generateReceiptEmailBody(receipt)
        // try await emailService.send(to: email, subject: "Receipt \(receipt.receiptNumber)", body: emailBody)
    }

    // MARK: - Payment Methods Management

    /// Save a payment card
    /// - Parameter card: The card to save
    func saveCard(_ card: PaymentCard) {
        // If this is set as default, unset other default cards
        if card.isDefault {
            for index in savedCards.indices {
                if savedCards[index].clientId == card.clientId {
                    savedCards[index].isDefault = false
                }
            }
        }

        savedCards.append(card)

        // TODO: Save to Core Data
        // TODO: Tokenize card with payment processor
    }

    /// Delete a saved card
    /// - Parameter cardId: Card ID to delete
    func deleteCard(_ cardId: UUID) {
        savedCards.removeAll { $0.id == cardId }

        // TODO: Delete from Core Data
        // TODO: Remove token from payment processor
    }

    /// Get saved cards for a client
    /// - Parameter clientId: Client ID
    /// - Returns: Array of saved cards
    func savedCards(for clientId: UUID) -> [PaymentCard] {
        return savedCards.filter { $0.clientId == clientId }
            .sorted { $0.isDefault && !$1.isDefault }
    }

    // MARK: - Statistics

    /// Get payment statistics
    /// - Returns: Payment statistics
    func getStatistics() -> PaymentStatistics {
        let total = payments.count
        let completed = payments.filter { $0.status == .completed }.count
        let pending = payments.filter { $0.status == .pending }.count
        let refunded = payments.filter { $0.status == .refunded }.count
        let totalAmount = payments.filter { $0.status == .completed }.reduce(0) { $0 + $1.amount }
        let totalRefunds = payments.compactMap { $0.refund?.amount }.reduce(0, +)

        return PaymentStatistics(
            totalPayments: total,
            completedPayments: completed,
            pendingPayments: pending,
            refundedPayments: refunded,
            totalAmount: totalAmount,
            totalRefunds: totalRefunds
        )
    }

    // MARK: - Private Methods

    /// Generate a unique receipt number
    private func generateReceiptNumber() -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())

        let number = String(format: "%04d", nextReceiptNumber)
        nextReceiptNumber += 1

        return "REC-\(year)-\(number)"
    }
}

// MARK: - Payment Statistics

/// Statistics for payments
struct PaymentStatistics {
    let totalPayments: Int
    let completedPayments: Int
    let pendingPayments: Int
    let refundedPayments: Int
    let totalAmount: Decimal
    let totalRefunds: Decimal

    /// Net revenue (after refunds)
    var netRevenue: Decimal {
        return totalAmount - totalRefunds
    }

    /// Success rate as percentage
    var successRate: Double {
        guard totalPayments > 0 else { return 0 }
        return Double(completedPayments) / Double(totalPayments) * 100
    }

    /// Average payment amount
    var averagePayment: Decimal {
        guard completedPayments > 0 else { return 0 }
        return totalAmount / Decimal(completedPayments)
    }
}
