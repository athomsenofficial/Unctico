// InvoiceListView.swift
// List and manage all invoices

import SwiftUI

/// View for displaying and managing invoices
struct InvoiceListView: View {

    @StateObject private var invoiceManager = InvoiceManager()

    @State private var searchText = ""
    @State private var filterStatus: InvoiceStatus? = nil
    @State private var showingNewInvoice = false

    var body: some View {
        NavigationStack {
            Group {
                if filteredInvoices.isEmpty {
                    emptyState
                } else {
                    invoiceList
                }
            }
            .navigationTitle("Invoices")
            .searchable(text: $searchText, prompt: "Search invoices")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewInvoice = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("All Invoices") {
                            filterStatus = nil
                        }

                        Divider()

                        ForEach(InvoiceStatus.allCases, id: \.self) { status in
                            Button(status.rawValue) {
                                filterStatus = status
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingNewInvoice) {
                CreateInvoiceView(invoiceManager: invoiceManager)
            }
        }
    }

    // MARK: - View Components

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Invoices")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create your first invoice to get started")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingNewInvoice = true
            } label: {
                Text("Create Invoice")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top)
        }
        .padding()
    }

    private var invoiceList: some View {
        List {
            ForEach(filteredInvoices) { invoice in
                NavigationLink {
                    InvoiceDetailView(invoice: invoice, invoiceManager: invoiceManager)
                } label: {
                    InvoiceRowView(invoice: invoice)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredInvoices: [Invoice] {
        var invoices = invoiceManager.invoices

        // Filter by status
        if let status = filterStatus {
            invoices = invoices.filter { $0.status == status }
        }

        // Filter by search text
        if !searchText.isEmpty {
            invoices = invoices.filter { invoice in
                invoice.invoiceNumber.localizedCaseInsensitiveContains(searchText)
                // TODO: Add client name search when we have client data
            }
        }

        return invoices.sorted { $0.invoiceDate > $1.invoiceDate }
    }
}

// MARK: - Invoice Row View

struct InvoiceRowView: View {
    let invoice: Invoice

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 6) {
                Text(invoice.invoiceNumber)
                    .font(.headline)

                HStack(spacing: 4) {
                    Text(invoice.invoiceDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(invoice.status.rawValue)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                }

                if invoice.isOverdue {
                    Text("Overdue by \(abs(invoice.daysUntilDue)) days")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyFormatter.format(invoice.totalAmount))
                    .font(.headline)

                if invoice.balanceRemaining > 0 && invoice.status != .void {
                    Text("Due: \(CurrencyFormatter.format(invoice.balanceRemaining))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

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
}

// MARK: - Create Invoice View

struct CreateInvoiceView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var invoiceManager: InvoiceManager

    @State private var selectedClient: Client?
    @State private var dueDate = Date()
    @State private var lineItems: [InvoiceLineItem] = []
    @State private var taxRate: String = "8.0"
    @State private var notes = ""
    @State private var showingAddLineItem = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    Button {
                        // TODO: Show client picker
                    } label: {
                        HStack {
                            Text("Select Client")
                            Spacer()
                            if let client = selectedClient {
                                Text(client.fullName)
                                    .foregroundStyle(.secondary)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Details") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])

                    HStack {
                        Text("Tax Rate")
                        Spacer()
                        TextField("0.0", text: $taxRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("%")
                    }
                }

                Section {
                    if lineItems.isEmpty {
                        Button {
                            showingAddLineItem = true
                        } label: {
                            Label("Add Line Item", systemImage: "plus.circle")
                        }
                    } else {
                        ForEach(lineItems) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.description)
                                        .font(.body)

                                    Text("\(item.quantity) × \(CurrencyFormatter.format(item.unitPrice))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(CurrencyFormatter.format(item.total))
                                    .font(.headline)
                            }
                        }
                        .onDelete { indexSet in
                            lineItems.remove(atOffsets: indexSet)
                        }

                        Button {
                            showingAddLineItem = true
                        } label: {
                            Label("Add Line Item", systemImage: "plus.circle")
                        }
                    }
                } header: {
                    Text("Line Items")
                }

                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                if !lineItems.isEmpty {
                    Section("Summary") {
                        HStack {
                            Text("Subtotal")
                            Spacer()
                            Text(CurrencyFormatter.format(subtotal))
                        }

                        HStack {
                            Text("Tax (\(taxRate)%)")
                            Spacer()
                            Text(CurrencyFormatter.format(taxAmount))
                        }

                        HStack {
                            Text("Total")
                                .fontWeight(.bold)
                            Spacer()
                            Text(CurrencyFormatter.format(totalAmount))
                                .fontWeight(.bold)
                        }
                    }
                }
            }
            .navigationTitle("New Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createInvoice()
                    }
                    .disabled(selectedClient == nil || lineItems.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddLineItem) {
                AddLineItemView { item in
                    lineItems.append(item)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var subtotal: Decimal {
        lineItems.reduce(0) { $0 + $1.total }
    }

    private var taxAmount: Decimal {
        let rate = Decimal(string: taxRate) ?? 0
        return subtotal * (rate / 100)
    }

    private var totalAmount: Decimal {
        subtotal + taxAmount
    }

    // MARK: - Actions

    private func createInvoice() {
        guard let client = selectedClient else { return }

        var invoice = invoiceManager.createInvoice(for: client.id, dueDate: dueDate)
        invoice.taxRate = Decimal(string: taxRate) ?? 0 / 100
        invoice.notes = notes.isEmpty ? nil : notes

        // Add line items
        for item in lineItems {
            invoice.addLineItem(item)
        }

        invoiceManager.updateInvoice(invoice)

        dismiss()
    }
}

// MARK: - Add Line Item View

struct AddLineItemView: View {
    @Environment(\.dismiss) var dismiss

    @State private var description = ""
    @State private var quantity = "1"
    @State private var unitPrice = ""
    @State private var isTaxable = true

    let onSave: (InvoiceLineItem) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Description", text: $description)

                TextField("Quantity", text: $quantity)
                    .keyboardType(.decimalPad)

                TextField("Unit Price", text: $unitPrice)
                    .keyboardType(.decimalPad)

                Toggle("Taxable", isOn: $isTaxable)

                Section("Total") {
                    HStack {
                        Text("Line Total")
                        Spacer()
                        Text(CurrencyFormatter.format(lineTotal))
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Add Line Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveLineItem()
                    }
                    .disabled(description.isEmpty || unitPrice.isEmpty)
                }
            }
        }
    }

    private var lineTotal: Decimal {
        let qty = Decimal(string: quantity) ?? 1
        let price = Decimal(string: unitPrice) ?? 0
        return qty * price
    }

    private func saveLineItem() {
        let item = InvoiceLineItem(
            description: description,
            quantity: Decimal(string: quantity) ?? 1,
            unitPrice: Decimal(string: unitPrice) ?? 0,
            isTaxable: isTaxable
        )

        onSave(item)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    InvoiceListView()
}
