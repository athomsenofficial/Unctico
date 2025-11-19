// IncomeListView.swift
// Income tracking with automatic appointment linking

import SwiftUI

/// Income list and management view
struct IncomeListView: View {
    @StateObject private var incomeManager = IncomeManager()

    @State private var searchText = ""
    @State private var selectedCategory: IncomeCategory?
    @State private var showingCreateIncome = false
    @State private var selectedIncome: Income?

    var body: some View {
        VStack(spacing: 0) {
            // Category filter
            categoryFilter

            // Income list
            incomesList
        }
        .searchable(text: $searchText, prompt: "Search income")
        .navigationTitle("Income")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateIncome = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateIncome) {
            CreateIncomeView(incomeManager: incomeManager)
        }
        .sheet(item: $selectedIncome) { income in
            IncomeDetailView(income: income, incomeManager: incomeManager)
        }
    }

    // MARK: - View Components

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All incomes button
                Button {
                    selectedCategory = nil
                } label: {
                    Text("All")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedCategory == nil ? Color.green : Color.gray.opacity(0.2))
                        .foregroundStyle(selectedCategory == nil ? .white : .primary)
                        .clipShape(Capsule())
                }

                // Category buttons
                ForEach(IncomeCategory.allCases.prefix(8)) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.caption)

                            Text(category.rawValue)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedCategory == category ? Color.green : Color.gray.opacity(0.2))
                        .foregroundStyle(selectedCategory == category ? .white : .primary)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGray6))
    }

    private var incomesList: some View {
        List {
            if filteredIncomes.isEmpty {
                emptyState
            } else {
                ForEach(filteredIncomes) { income in
                    Button {
                        selectedIncome = income
                    } label: {
                        IncomeRowView(income: income)
                    }
                    .foregroundStyle(.primary)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        incomeManager.deleteIncome(filteredIncomes[index])
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.green)

            Text("No Income")
                .font(.title3)
                .fontWeight(.semibold)

            Text(selectedCategory == nil ?
                 "Record your business income here" :
                 "No income in this category")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingCreateIncome = true
            } label: {
                Label("Add Income", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
    }

    // MARK: - Computed Properties

    private var filteredIncomes: [Income] {
        var filtered = incomeManager.allIncomes()

        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.source.localizedCaseInsensitiveContains(searchText) ||
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }
}

// MARK: - Income Row View

struct IncomeRowView: View {
    let income: Income

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: income.category.icon)
                .font(.title3)
                .foregroundStyle(categoryColor)
                .frame(width: 40, height: 40)
                .background(categoryColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(income.description)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(income.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !income.source.isEmpty {
                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(income.source)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if income.isAutomatic {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }

                Text(income.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyFormatter.format(income.amount))
                    .font(.headline)
                    .foregroundStyle(.green)

                HStack(spacing: 4) {
                    Image(systemName: income.paymentMethod.icon)
                        .font(.caption)

                    Text(income.paymentMethod.rawValue)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        switch income.category.color {
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "indigo": return .indigo
        default: return .gray
        }
    }
}

// MARK: - Create Income View

struct CreateIncomeView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var incomeManager: IncomeManager

    @State private var date = Date()
    @State private var amount = ""
    @State private var category: IncomeCategory = .massageServices
    @State private var description = ""
    @State private var source = ""
    @State private var paymentMethod: PaymentMethod = .cash
    @State private var isTaxable = true
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date])

                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)

                    Picker("Category", selection: $category) {
                        ForEach(IncomeCategory.allCases) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }

                    TextField("Description", text: $description)
                        .textInputAutocapitalization(.sentences)

                    TextField("Source (optional)", text: $source)
                        .textInputAutocapitalization(.words)
                }

                Section("Payment") {
                    Picker("Payment Method", selection: $paymentMethod) {
                        ForEach([PaymentMethod.cash, .creditCard, .check, .bankTransfer, .ach], id: \.self) { method in
                            HStack {
                                Image(systemName: method.icon)
                                Text(method.rawValue)
                            }
                            .tag(method)
                        }
                    }
                }

                Section("Tax Information") {
                    Toggle("Taxable Income", isOn: $isTaxable)

                    if let taxNotes = category.taxNotes {
                        Text(taxNotes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveIncome()
                    }
                    .disabled(!canSave)
                }
            }
            .onChange(of: category) { _, newCategory in
                isTaxable = newCategory.isDefaultTaxable
            }
        }
    }

    // MARK: - Actions

    private var canSave: Bool {
        guard let _ = Decimal(string: amount), !description.isEmpty else {
            return false
        }
        return true
    }

    private func saveIncome() {
        guard let amountValue = Decimal(string: amount) else { return }

        _ = incomeManager.createIncome(
            date: date,
            amount: amountValue,
            category: category,
            description: description,
            source: source,
            paymentMethod: paymentMethod
        )

        dismiss()
    }
}

// MARK: - Income Detail View

struct IncomeDetailView: View {
    let income: Income
    @ObservedObject var incomeManager: IncomeManager

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Details") {
                    LabeledContent("Amount") {
                        Text(CurrencyFormatter.format(income.amount))
                            .foregroundStyle(.green)
                    }

                    LabeledContent("Category") {
                        HStack {
                            Image(systemName: income.category.icon)
                            Text(income.category.rawValue)
                        }
                    }

                    LabeledContent("Date", value: income.date, format: .dateTime.month().day().year())

                    if !income.source.isEmpty {
                        LabeledContent("Source", value: income.source)
                    }

                    LabeledContent("Payment Method") {
                        HStack {
                            Image(systemName: income.paymentMethod.icon)
                            Text(income.paymentMethod.rawValue)
                        }
                    }

                    LabeledContent("Type", value: income.sourceType)
                }

                Section("Tax Information") {
                    LabeledContent("Taxable") {
                        Image(systemName: income.isTaxable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(income.isTaxable ? .green : .red)
                    }

                    if let taxNotes = income.category.taxNotes {
                        Text(taxNotes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let notes = income.notes, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes)
                    }
                }
            }
            .navigationTitle(income.description)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        IncomeListView()
    }
}
