// InvoiceManager.swift
// Manages invoice creation, updates, and operations

import Foundation
import SwiftUI

/// Manages all invoice operations
/// Use this for creating, updating, and tracking invoices
class InvoiceManager: ObservableObject {

    // MARK: - Published Properties

    /// All invoices (in-memory for now, will connect to Core Data)
    @Published var invoices: [Invoice] = []

    /// Invoice templates
    @Published var templates: [InvoiceTemplate] = []

    /// Is loading?
    @Published var isLoading: Bool = false

    /// Error message
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let databaseManager: DatabaseManager
    private var nextInvoiceNumber: Int = 1

    // MARK: - Initialization

    init(databaseManager: DatabaseManager = DatabaseManager()) {
        self.databaseManager = databaseManager
        loadInvoices()
        loadTemplates()
    }

    // MARK: - Public Methods

    /// Load all invoices from database
    func loadInvoices() {
        // TODO: Load from Core Data
        // For now, using in-memory array
    }

    /// Load invoice templates
    func loadTemplates() {
        // Create default template if none exist
        if templates.isEmpty {
            var defaultTemplate = InvoiceTemplate(name: "Standard Invoice")
            defaultTemplate.defaultPaymentTerms = "Due on receipt"
            defaultTemplate.defaultDueDateOffset = 0
            defaultTemplate.defaultTaxRate = 0.08 // 8% default tax
            templates.append(defaultTemplate)
        }
    }

    /// Create a new invoice
    /// - Parameters:
    ///   - clientId: Client ID
    ///   - dueDate: Payment due date
    ///   - template: Optional template to use
    /// - Returns: The created invoice
    func createInvoice(for clientId: UUID, dueDate: Date, template: InvoiceTemplate? = nil) -> Invoice {
        let invoiceNumber = generateInvoiceNumber()

        var invoice = Invoice(
            clientId: clientId,
            invoiceNumber: invoiceNumber,
            dueDate: dueDate
        )

        // Apply template if provided
        if let template = template {
            invoice.paymentTerms = template.defaultPaymentTerms
            invoice.taxRate = template.defaultTaxRate
        } else if let defaultTemplate = templates.first {
            invoice.paymentTerms = defaultTemplate.defaultPaymentTerms
            invoice.taxRate = defaultTemplate.defaultTaxRate
        }

        invoices.append(invoice)

        // TODO: Save to Core Data

        return invoice
    }

    /// Create invoice from an appointment
    /// - Parameters:
    ///   - appointment: The appointment to invoice
    ///   - price: Price for the service
    /// - Returns: The created invoice
    func createInvoice(from appointment: Appointment, price: Decimal) -> Invoice {
        let dueDate = Calendar.current.date(byAdding: .day, value: 0, to: Date()) ?? Date()

        var invoice = createInvoice(for: appointment.clientId, dueDate: dueDate)

        // Add line item from appointment
        let lineItem = InvoiceLineItem.fromAppointment(appointment, price: price)
        invoice.addLineItem(lineItem)

        invoice.appointmentId = appointment.id

        updateInvoice(invoice)

        return invoice
    }

    /// Update an invoice
    /// - Parameter invoice: The invoice to update
    func updateInvoice(_ invoice: Invoice) {
        if let index = invoices.firstIndex(where: { $0.id == invoice.id }) {
            var updatedInvoice = invoice
            updatedInvoice.updatedAt = Date()
            invoices[index] = updatedInvoice

            // TODO: Save to Core Data
        }
    }

    /// Delete an invoice
    /// - Parameter invoiceId: ID of invoice to delete
    func deleteInvoice(_ invoiceId: UUID) {
        guard let invoice = invoices.first(where: { $0.id == invoiceId }) else {
            errorMessage = "Invoice not found"
            return
        }

        // Only allow deletion of draft invoices
        guard invoice.status == .draft else {
            errorMessage = "Cannot delete a sent invoice. Void it instead."
            return
        }

        invoices.removeAll { $0.id == invoiceId }

        // TODO: Delete from Core Data
    }

    /// Send an invoice to client
    /// - Parameter invoiceId: ID of invoice to send
    func sendInvoice(_ invoiceId: UUID) {
        guard let index = invoices.firstIndex(where: { $0.id == invoiceId }) else {
            errorMessage = "Invoice not found"
            return
        }

        guard invoices[index].canBeSent else {
            errorMessage = "Invoice cannot be sent (must have line items and be in draft status)"
            return
        }

        invoices[index].markAsSent()

        // TODO: Send email to client
        // TODO: Save to Core Data

        errorMessage = nil
    }

    /// Void an invoice
    /// - Parameter invoiceId: ID of invoice to void
    func voidInvoice(_ invoiceId: UUID) {
        guard let index = invoices.firstIndex(where: { $0.id == invoiceId }) else {
            errorMessage = "Invoice not found"
            return
        }

        guard invoices[index].canBeVoided else {
            errorMessage = "Invoice cannot be voided"
            return
        }

        invoices[index].void()

        // TODO: Save to Core Data

        errorMessage = nil
    }

    /// Get invoices for a specific client
    /// - Parameter clientId: Client ID
    /// - Returns: Array of invoices for that client
    func invoices(for clientId: UUID) -> [Invoice] {
        return invoices.filter { $0.clientId == clientId }
            .sorted { $0.invoiceDate > $1.invoiceDate }
    }

    /// Get outstanding invoices (sent but not paid)
    /// - Returns: Array of outstanding invoices
    func outstandingInvoices() -> [Invoice] {
        return invoices.filter { invoice in
            invoice.status == .sent || invoice.status == .partiallyPaid || invoice.status == .overdue
        }.sorted { $0.dueDate < $1.dueDate }
    }

    /// Get overdue invoices
    /// - Returns: Array of overdue invoices
    func overdueInvoices() -> [Invoice] {
        return invoices.filter { $0.isOverdue }
            .sorted { $0.dueDate < $1.dueDate }
    }

    /// Get draft invoices
    /// - Returns: Array of draft invoices
    func draftInvoices() -> [Invoice] {
        return invoices.filter { $0.status == .draft }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Get invoices for a date range
    /// - Parameters:
    ///   - startDate: Start of range
    ///   - endDate: End of range
    /// - Returns: Array of invoices in range
    func invoices(from startDate: Date, to endDate: Date) -> [Invoice] {
        return invoices.filter { invoice in
            invoice.invoiceDate >= startDate && invoice.invoiceDate <= endDate
        }.sorted { $0.invoiceDate > $1.invoiceDate }
    }

    /// Get total revenue for a date range
    /// - Parameters:
    ///   - startDate: Start of range
    ///   - endDate: End of range
    /// - Returns: Total revenue
    func totalRevenue(from startDate: Date, to endDate: Date) -> Decimal {
        return invoices(from: startDate, to: endDate)
            .filter { $0.status == .paid }
            .reduce(0) { $0 + $1.totalAmount }
    }

    /// Get total outstanding balance
    /// - Returns: Total amount owed by all clients
    func totalOutstanding() -> Decimal {
        return outstandingInvoices().reduce(0) { $0 + $1.balanceRemaining }
    }

    /// Get statistics
    /// - Returns: Invoice statistics
    func getStatistics() -> InvoiceStatistics {
        let total = invoices.count
        let draft = draftInvoices().count
        let sent = invoices.filter { $0.status == .sent }.count
        let paid = invoices.filter { $0.status == .paid }.count
        let overdue = overdueInvoices().count
        let outstanding = totalOutstanding()
        let totalRevenue = invoices.filter { $0.status == .paid }.reduce(0) { $0 + $1.totalAmount }

        return InvoiceStatistics(
            totalInvoices: total,
            draftInvoices: draft,
            sentInvoices: sent,
            paidInvoices: paid,
            overdueInvoices: overdue,
            totalOutstanding: outstanding,
            totalRevenue: totalRevenue
        )
    }

    // MARK: - Invoice Number Generation

    /// Generate a unique invoice number
    /// - Returns: Invoice number string (e.g., "INV-2024-001")
    private func generateInvoiceNumber() -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())

        let number = String(format: "%03d", nextInvoiceNumber)
        nextInvoiceNumber += 1

        return "INV-\(year)-\(number)"
    }

    /// Set the next invoice number (for customization)
    /// - Parameter number: The next number to use
    func setNextInvoiceNumber(_ number: Int) {
        nextInvoiceNumber = number
    }
}

// MARK: - Invoice Statistics

/// Statistics for invoices
struct InvoiceStatistics {
    let totalInvoices: Int
    let draftInvoices: Int
    let sentInvoices: Int
    let paidInvoices: Int
    let overdueInvoices: Int
    let totalOutstanding: Decimal
    let totalRevenue: Decimal

    /// Payment collection rate as percentage
    var collectionRate: Double {
        guard totalInvoices > 0 else { return 0 }
        return Double(paidInvoices) / Double(totalInvoices) * 100
    }

    /// Average invoice amount
    var averageInvoiceAmount: Decimal {
        guard totalInvoices > 0 else { return 0 }
        return totalRevenue / Decimal(totalInvoices)
    }
}
