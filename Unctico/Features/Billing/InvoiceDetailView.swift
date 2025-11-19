// InvoiceDetailView.swift
// Detailed view of a single invoice with payment options

import SwiftUI

/// Detailed view of an invoice
struct InvoiceDetailView: View {

    let invoice: Invoice
    @ObservedObject var invoiceManager: InvoiceManager

    @State private var showingRecordPayment = false
    @State private var showingSendInvoice = false
    @State private var showingVoidConfirmation = false

    var body: some View {
        List {
            // Status section
            statusSection

            // Line items
            lineItemsSection

            // Totals
            totalsSection

            // Payments
            if !invoice.payments.isEmpty {
                paymentsSection
            }

            // Notes
            if let notes = invoice.notes {
                Section("Notes") {
                    Text(notes)
                }
            }

            // Actions
            actionsSection
        }
        .navigationTitle(invoice.invoiceNumber)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingRecordPayment) {
            RecordPaymentView(invoice: invoice, invoiceManager: invoiceManager)
        }
        .alert("Send Invoice", isPresented: $showingSendInvoice) {
            Button("Cancel", role: .cancel) {}
            Button("Send") {
                invoiceManager.sendInvoice(invoice.id)
            }
        } message: {
            Text("Send this invoice to the client?")
        }
        .alert("Void Invoice", isPresented: $showingVoidConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Void", role: .destructive) {
                invoiceManager.voidInvoice(invoice.id)
            }
        } message: {
            Text("Are you sure you want to void this invoice? This action cannot be undone.")
        }
    }

    // MARK: - Sections

    private var statusSection: some View {
        Section {
            HStack {
                Label(invoice.status.rawValue, systemImage: invoice.status.icon)
                    .foregroundStyle(statusColor)

                Spacer()

                if invoice.isPaid {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }
            .font(.headline)

            HStack {
                Text("Invoice Date")
                Spacer()
                Text(invoice.invoiceDate, style: .date)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Due Date")
                Spacer()
                Text(invoice.dueDate, style: .date)
                    .foregroundStyle(invoice.isOverdue ? .red : .secondary)
            }

            if invoice.isOverdue {
                HStack {
                    Text("Days Overdue")
                    Spacer()
                    Text("\(abs(invoice.daysUntilDue))")
                        .foregroundStyle(.red)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var lineItemsSection: some View {
        Section("Line Items") {
            ForEach(invoice.lineItems) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.description)
                        Spacer()
                        Text(CurrencyFormatter.format(item.total))
                            .fontWeight(.semibold)
                    }

                    Text("\(item.quantity) × \(CurrencyFormatter.format(item.unitPrice))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var totalsSection: some View {
        Section("Total") {
            HStack {
                Text("Subtotal")
                Spacer()
                Text(CurrencyFormatter.format(invoice.subtotal))
            }

            if invoice.taxRate > 0 {
                HStack {
                    Text("Tax (\(formatTaxRate(invoice.taxRate))%)")
                    Spacer()
                    Text(CurrencyFormatter.format(invoice.taxAmount))
                }
            }

            if invoice.discountAmount > 0 {
                HStack {
                    Text("Discount")
                    Spacer()
                    Text("-\(CurrencyFormatter.format(invoice.discountAmount))")
                        .foregroundStyle(.green)
                }
            }

            Divider()

            HStack {
                Text("Total Amount")
                    .fontWeight(.bold)
                Spacer()
                Text(CurrencyFormatter.format(invoice.totalAmount))
                    .fontWeight(.bold)
                    .font(.title3)
            }

            if invoice.paidAmount > 0 {
                HStack {
                    Text("Paid")
                        .foregroundStyle(.green)
                    Spacer()
                    Text(CurrencyFormatter.format(invoice.paidAmount))
                        .foregroundStyle(.green)
                }
            }

            if invoice.balanceRemaining > 0 {
                HStack {
                    Text("Balance Due")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(CurrencyFormatter.format(invoice.balanceRemaining))
                        .fontWeight(.semibold)
                        .foregroundStyle(invoice.isOverdue ? .red : .primary)
                }
            }
        }
    }

    private var paymentsSection: some View {
        Section("Payments") {
            ForEach(invoice.payments) { payment in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(payment.paymentDate, style: .date)
                            .font(.body)

                        Text(payment.paymentMethod.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(CurrencyFormatter.format(payment.amount))
                            .fontWeight(.semibold)

                        if payment.isRefunded {
                            Text("Refunded")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        Section {
            if invoice.canBeSent {
                Button {
                    showingSendInvoice = true
                } label: {
                    Label("Send Invoice", systemImage: "paperplane.fill")
                        .foregroundStyle(.blue)
                }
            }

            if invoice.balanceRemaining > 0 && invoice.status != .void {
                Button {
                    showingRecordPayment = true
                } label: {
                    Label("Record Payment", systemImage: "dollarsign.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            if invoice.canBeVoided {
                Button(role: .destructive) {
                    showingVoidConfirmation = true
                } label: {
                    Label("Void Invoice", systemImage: "xmark.circle.fill")
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        switch invoice.status {
        case .draft:
            return .gray
        case .sent:
            return .blue
        case .partiallyPaid:
            return .orange
        case .paid:
            return .green
        case .overdue:
            return .red
        case .void:
            return .red
        }
    }

    // MARK: - Helper Methods

    private func formatTaxRate(_ rate: Decimal) -> String {
        let percentage = rate * 100
        return String(format: "%.1f", Double(truncating: percentage as NSDecimalNumber))
    }
}

// MARK: - Record Payment View

struct RecordPaymentView: View {
    @Environment(\.dismiss) var dismiss

    let invoice: Invoice
    @ObservedObject var invoiceManager: InvoiceManager

    @State private var paymentAmount: String = ""
    @State private var paymentMethod: PaymentMethod = .cash
    @State private var referenceNumber = ""
    @State private var paymentDate = Date()
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Invoice Total")
                        Spacer()
                        Text(CurrencyFormatter.format(invoice.totalAmount))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Amount Paid")
                        Spacer()
                        Text(CurrencyFormatter.format(invoice.paidAmount))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Balance Due")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(CurrencyFormatter.format(invoice.balanceRemaining))
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    }
                }

                Section("Payment Details") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $paymentAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    Button("Pay Full Balance") {
                        paymentAmount = String(describing: invoice.balanceRemaining)
                    }
                    .font(.subheadline)

                    Picker("Payment Method", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Label(method.rawValue, systemImage: method.icon)
                                .tag(method)
                        }
                    }

                    DatePicker("Payment Date", selection: $paymentDate, displayedComponents: [.date])

                    TextField("Reference Number (Optional)", text: $referenceNumber)
                }
            }
            .navigationTitle("Record Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Record") {
                        recordPayment()
                    }
                    .disabled(paymentAmount.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func recordPayment() {
        guard let amount = Decimal(string: paymentAmount) else {
            errorMessage = "Invalid payment amount"
            showError = true
            return
        }

        // Create a PaymentManager instance
        let paymentManager = PaymentManager(invoiceManager: invoiceManager)

        let payment = paymentManager.recordPayment(
            for: invoice.id,
            clientId: invoice.clientId,
            amount: amount,
            paymentMethod: paymentMethod,
            referenceNumber: referenceNumber.isEmpty ? nil : referenceNumber
        )

        if payment != nil {
            dismiss()
        } else {
            errorMessage = paymentManager.errorMessage ?? "Failed to record payment"
            showError = true
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        InvoiceDetailView(
            invoice: Invoice(
                clientId: UUID(),
                invoiceNumber: "INV-2024-001",
                dueDate: Date()
            ),
            invoiceManager: InvoiceManager()
        )
    }
}
