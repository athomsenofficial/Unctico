// TaxDeadlinesView.swift
// Tax deadline tracking and management

import SwiftUI

/// Tax deadline tracking view
struct TaxDeadlinesView: View {
    @ObservedObject var deadlineManager: TaxDeadlineManager

    @State private var selectedFilter: DeadlineFilter = .all
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var showingCompleteDeadline: TaxDeadline?

    var body: some View {
        VStack(spacing: 0) {
            // Filter selector
            filterSelector

            // Deadline list
            List {
                if filteredDeadlines.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredDeadlines) { deadline in
                        DeadlineDetailRowView(deadline: deadline)
                            .onTapGesture {
                                if !deadline.isCompleted {
                                    showingCompleteDeadline = deadline
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Tax Deadlines")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("Year", selection: $selectedYear) {
                    ForEach((2020...2030), id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
            }
        }
        .sheet(item: $showingCompleteDeadline) { deadline in
            CompleteDeadlineView(
                deadline: deadline,
                deadlineManager: deadlineManager
            )
        }
    }

    // MARK: - View Components

    private var filterSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DeadlineFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: filter.icon)
                                .font(.caption)

                            Text(filter.rawValue)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedFilter == filter ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundStyle(selectedFilter == filter ? .white : .primary)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGray6))
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text("No Deadlines")
                .font(.title3)
                .fontWeight(.semibold)

            Text("No tax deadlines match your current filter")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Computed Properties

    private var filteredDeadlines: [TaxDeadline] {
        var filtered: [TaxDeadline]

        switch selectedFilter {
        case .all:
            filtered = deadlineManager.deadlines(year: selectedYear)
        case .upcoming:
            filtered = deadlineManager.upcomingDeadlines().filter { $0.year == selectedYear }
        case .overdue:
            filtered = deadlineManager.overdueDeadlines().filter { $0.year == selectedYear }
        case .completed:
            filtered = deadlineManager.completedDeadlines(year: selectedYear)
        }

        return filtered.sorted { deadline1, deadline2 in
            if deadline1.isCompleted != deadline2.isCompleted {
                return !deadline1.isCompleted
            }
            return deadline1.dueDate < deadline2.dueDate
        }
    }
}

// MARK: - Deadline Detail Row View

struct DeadlineDetailRowView: View {
    let deadline: TaxDeadline

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: deadline.type.icon)
                .font(.title3)
                .foregroundStyle(typeColor)
                .frame(width: 40, height: 40)
                .background(typeColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(deadline.displayTitle)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(deadline.dueDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !deadline.isCompleted {
                        Text("•")
                            .foregroundStyle(.secondary)

                        if deadline.daysUntil >= 0 {
                            Text("\(deadline.daysUntil) days")
                                .font(.caption)
                                .foregroundStyle(deadline.isUpcoming ? .orange : .secondary)
                        } else {
                            Text("\(abs(deadline.daysUntil)) days overdue")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                if deadline.isCompleted, let completedDate = deadline.completedDate {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)

                        Text("Completed on \(completedDate, style: .date)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: deadline.status.icon)
                        .font(.caption)

                    Text(deadline.status.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(statusColor)

                if let amount = deadline.amount {
                    Text(CurrencyFormatter.format(amount))
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var typeColor: Color {
        switch deadline.type.color {
        case "blue": return .blue
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "purple": return .purple
        default: return .gray
        }
    }

    private var statusColor: Color {
        switch deadline.status.color {
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        default: return .gray
        }
    }
}

// MARK: - Complete Deadline View

struct CompleteDeadlineView: View {
    @Environment(\.dismiss) var dismiss

    let deadline: TaxDeadline
    @ObservedObject var deadlineManager: TaxDeadlineManager

    @State private var amount = ""
    @State private var confirmationNumber = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Deadline Information") {
                    LabeledContent("Type", value: deadline.displayTitle)
                    LabeledContent("Due Date", value: deadline.dueDate, format: .dateTime.month().day().year())
                }

                Section("Payment Details") {
                    TextField("Amount Paid", text: $amount)
                        .keyboardType(.decimalPad)

                    TextField("Confirmation Number (Optional)", text: $confirmationNumber)
                }
            }
            .navigationTitle("Complete Deadline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Mark Complete") {
                        completeDeadline()
                    }
                    .disabled(amount.isEmpty)
                }
            }
        }
    }

    private func completeDeadline() {
        guard let amountValue = Decimal(string: amount) else { return }

        deadlineManager.completeDeadline(
            deadline,
            amount: amountValue,
            confirmationNumber: confirmationNumber.isEmpty ? nil : confirmationNumber
        )

        dismiss()
    }
}

// MARK: - Supporting Types

enum DeadlineFilter: String, CaseIterable {
    case all = "All"
    case upcoming = "Upcoming"
    case overdue = "Overdue"
    case completed = "Completed"

    var icon: String {
        switch self {
        case .all: return "calendar"
        case .upcoming: return "clock.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TaxDeadlinesView(deadlineManager: TaxDeadlineManager())
    }
}
