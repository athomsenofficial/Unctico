// ExpenseListView.swift
// Expense tracking with categories, receipts, and reporting

import SwiftUI
import PhotosUI

/// Expense list and management view
struct ExpenseListView: View {
    @StateObject private var expenseManager = ExpenseManager()

    @State private var searchText = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var showingCreateExpense = false
    @State private var selectedExpense: Expense?

    var body: some View {
        VStack(spacing: 0) {
            // Category filter
            categoryFilter

            // Expense list
            expensesList
        }
        .searchable(text: $searchText, prompt: "Search expenses")
        .navigationTitle("Expenses")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateExpense = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateExpense) {
            CreateExpenseView(expenseManager: expenseManager)
        }
        .sheet(item: $selectedExpense) { expense in
            ExpenseDetailView(expense: expense, expenseManager: expenseManager)
        }
    }

    // MARK: - View Components

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All expenses button
                Button {
                    selectedCategory = nil
                } label: {
                    Text("All")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundStyle(selectedCategory == nil ? .white : .primary)
                        .clipShape(Capsule())
                }

                // Category buttons
                ForEach(ExpenseCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.caption)

                            Text(category.rawValue)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
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

    private var expensesList: some View {
        List {
            if filteredExpenses.isEmpty {
                emptyState
            } else {
                ForEach(filteredExpenses) { expense in
                    Button {
                        selectedExpense = expense
                    } label: {
                        ExpenseRowView(expense: expense)
                    }
                    .foregroundStyle(.primary)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        expenseManager.deleteExpense(filteredExpenses[index])
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No Expenses")
                .font(.title3)
                .fontWeight(.semibold)

            Text(selectedCategory == nil ?
                 "Track your business expenses here" :
                 "No expenses in this category")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingCreateExpense = true
            } label: {
                Label("Add Expense", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Computed Properties

    private var filteredExpenses: [Expense] {
        var filtered = expenseManager.allExpenses()

        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.vendor.localizedCaseInsensitiveContains(searchText) ||
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }
}

// MARK: - Expense Row View

struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: expense.category.icon)
                .font(.title3)
                .foregroundStyle(categoryColor)
                .frame(width: 40, height: 40)
                .background(categoryColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(expense.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !expense.vendor.isEmpty {
                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(expense.vendor)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if expense.hasReceipt {
                        Image(systemName: "paperclip")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }

                Text(expense.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyFormatter.format(expense.amount))
                    .font(.headline)

                if expense.isTaxDeductible {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)

                        Text("Deductible")
                            .font(.caption2)
                    }
                    .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        switch expense.category.color {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "indigo": return .indigo
        default: return .gray
        }
    }
}

// MARK: - Create Expense View

struct CreateExpenseView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var expenseManager: ExpenseManager

    @State private var date = Date()
    @State private var amount = ""
    @State private var category: ExpenseCategory = .officeSupplies
    @State private var description = ""
    @State private var vendor = ""
    @State private var paymentMethod: PaymentMethod = .cash
    @State private var isTaxDeductible = true
    @State private var hasReceipt = false
    @State private var notes = ""

    @State private var showingPhotosPicker = false
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date])

                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)

                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }

                    TextField("Description", text: $description)
                        .textInputAutocapitalization(.sentences)

                    TextField("Vendor (optional)", text: $vendor)
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

                Section("Tax & Receipt") {
                    Toggle("Tax Deductible", isOn: $isTaxDeductible)

                    if let taxNotes = category.taxNotes {
                        Text(taxNotes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Toggle("Has Receipt", isOn: $hasReceipt)

                    if hasReceipt {
                        Button {
                            showingPhotosPicker = true
                        } label: {
                            Label("Attach Receipt Photo", systemImage: "camera.fill")
                        }
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(!canSave)
                }
            }
            .photosPicker(
                isPresented: $showingPhotosPicker,
                selection: $selectedPhoto,
                matching: .images
            )
            .onChange(of: category) { _, newCategory in
                isTaxDeductible = newCategory.isDefaultDeductible
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

    private func saveExpense() {
        guard let amountValue = Decimal(string: amount) else { return }

        _ = expenseManager.createExpense(
            date: date,
            amount: amountValue,
            category: category,
            description: description,
            vendor: vendor,
            paymentMethod: paymentMethod,
            isTaxDeductible: isTaxDeductible,
            hasReceipt: hasReceipt
        )

        // TODO: Save receipt photo if selected

        dismiss()
    }
}

// MARK: - Expense Detail View

struct ExpenseDetailView: View {
    let expense: Expense
    @ObservedObject var expenseManager: ExpenseManager

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Details") {
                    LabeledContent("Amount", value: CurrencyFormatter.format(expense.amount))

                    LabeledContent("Category") {
                        HStack {
                            Image(systemName: expense.category.icon)
                            Text(expense.category.rawValue)
                        }
                    }

                    LabeledContent("Date", value: expense.date, format: .dateTime.month().day().year())

                    if !expense.vendor.isEmpty {
                        LabeledContent("Vendor", value: expense.vendor)
                    }

                    LabeledContent("Payment Method") {
                        HStack {
                            Image(systemName: expense.paymentMethod.icon)
                            Text(expense.paymentMethod.rawValue)
                        }
                    }
                }

                Section("Tax Information") {
                    LabeledContent("Tax Deductible") {
                        Image(systemName: expense.isTaxDeductible ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(expense.isTaxDeductible ? .green : .red)
                    }

                    if let taxNotes = expense.category.taxNotes {
                        Text(taxNotes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if expense.hasReceipt {
                    Section("Receipt") {
                        HStack {
                            Image(systemName: "paperclip.circle.fill")
                                .foregroundStyle(.blue)

                            Text("Receipt attached")

                            Spacer()

                            Button("View") {
                                // TODO: Show receipt image
                            }
                        }
                    }
                }

                if let notes = expense.notes, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes)
                    }
                }
            }
            .navigationTitle(expense.description)
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
        ExpenseListView()
    }
}
