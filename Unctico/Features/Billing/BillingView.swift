// BillingView.swift
// Billing, invoicing, and payment management view

import SwiftUI

/// Billing and invoicing view
struct BillingView: View {

    // MARK: - State

    @State private var selectedTab: BillingTab = .invoices
    @State private var showingNewInvoice = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                billingTabSelector

                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    InvoicesTabView()
                        .tag(BillingTab.invoices)

                    PaymentsTabView()
                        .tag(BillingTab.payments)

                    ReportsTabView()
                        .tag(BillingTab.reports)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Billing")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewInvoice = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewInvoice) {
                NewInvoiceView()
            }
        }
    }

    // MARK: - View Components

    /// Tab selector for billing sections
    private var billingTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(BillingTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedTab == tab ? .semibold : .regular)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
                        .foregroundStyle(selectedTab == tab ? .blue : .secondary)
                }
            }
        }
        .background(Color(.systemGray6))
    }
}

// MARK: - Billing Tab Enum

enum BillingTab: String, CaseIterable, Identifiable {
    case invoices = "Invoices"
    case payments = "Payments"
    case reports = "Reports"

    var id: String { rawValue }
}

// MARK: - Invoices Tab

struct InvoicesTabView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No Invoices")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Create invoices for your clients")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Payments Tab

struct PaymentsTabView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No Payments")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Track payments from clients")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Reports Tab

struct ReportsTabView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Revenue summary card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Revenue Summary")
                        .font(.headline)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Today")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("$0")
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        VStack(alignment: .leading) {
                            Text("This Week")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("$0")
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        VStack(alignment: .leading) {
                            Text("This Month")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("$0")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Outstanding invoices
                VStack(alignment: .leading, spacing: 12) {
                    Text("Outstanding")
                        .font(.headline)

                    HStack {
                        Text("Total Outstanding")
                        Spacer()
                        Text("$0")
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
}

// MARK: - New Invoice View

struct NewInvoiceView: View {
    @Environment(\.dismiss) var dismiss

    @State private var selectedClient: Client?
    @State private var invoiceDate = Date()
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var amount = ""
    @State private var serviceDescription = ""

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
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }

                Section("Invoice Details") {
                    DatePicker("Invoice Date", selection: $invoiceDate, displayedComponents: [.date])
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                }

                Section("Line Items") {
                    TextField("Service Description", text: $serviceDescription)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("New Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        // TODO: Save invoice
                        dismiss()
                    }
                    .disabled(selectedClient == nil || amount.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BillingView()
}
