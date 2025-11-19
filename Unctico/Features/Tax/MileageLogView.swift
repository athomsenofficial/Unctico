// MileageLogView.swift
// Mileage tracking for tax deductions

import SwiftUI

/// Mileage log tracking view
struct MileageLogView: View {
    @ObservedObject var mileageManager: MileageManager

    @State private var searchText = ""
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var showingCreateLog = false

    var body: some View {
        VStack(spacing: 0) {
            // Summary section
            summarySection

            // Mileage list
            List {
                if filteredLogs.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredLogs) { log in
                        MileageLogRowView(log: log)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            mileageManager.deleteMileageLog(filteredLogs[index])
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search mileage logs")
        .navigationTitle("Mileage Log")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Picker("Year", selection: $selectedYear) {
                        ForEach((2020...2030), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }

                    Button {
                        showingCreateLog = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateLog) {
            CreateMileageLogView(mileageManager: mileageManager)
        }
    }

    // MARK: - View Components

    private var summarySection: some View {
        let stats = mileageManager.getStatistics(
            from: Calendar.current.date(from: DateComponents(year: selectedYear, month: 1, day: 1))!,
            to: Calendar.current.date(from: DateComponents(year: selectedYear, month: 12, day: 31))!
        )

        return VStack(spacing: 16) {
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("Total Miles")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(formatMiles(stats.totalMiles))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("Total Deduction")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(CurrencyFormatter.format(stats.totalDeduction))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("Trips")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(stats.totalTrips)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.systemGray6))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .font(.system(size: 50))
                .foregroundStyle(.blue)

            Text("No Mileage Logs")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Track your business mileage for tax deductions")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingCreateLog = true
            } label: {
                Label("Add Mileage Log", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Computed Properties

    private var filteredLogs: [MileageLog] {
        var filtered = mileageManager.logs(year: selectedYear)

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.startLocation.localizedCaseInsensitiveContains(searchText) ||
                $0.endLocation.localizedCaseInsensitiveContains(searchText) ||
                $0.businessPurpose.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered.sorted { $0.date > $1.date }
    }

    private func formatMiles(_ miles: Double) -> String {
        String(format: "%.1f mi", miles)
    }
}

// MARK: - Mileage Log Row View

struct MileageLogRowView: View {
    let log: MileageLog

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: log.purpose.icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("\(log.startLocation) → \(log.endLocation)")
                    .font(.headline)
                    .lineLimit(1)

                Text(log.businessPurpose)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(log.purpose.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if log.isRoundTrip {
                        Text("•")
                            .foregroundStyle(.secondary)

                        Text("Round Trip")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(log.date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatMiles(log.totalMiles))
                    .font(.headline)

                Text(CurrencyFormatter.format(log.totalDeduction))
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatMiles(_ miles: Double) -> String {
        String(format: "%.1f mi", miles)
    }
}

// MARK: - Create Mileage Log View

struct CreateMileageLogView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var mileageManager: MileageManager

    @State private var date = Date()
    @State private var startLocation = ""
    @State private var endLocation = ""
    @State private var purpose: MileagePurpose = .clientVisit
    @State private var businessPurpose = ""
    @State private var miles = ""
    @State private var isRoundTrip = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Information") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date])

                    TextField("Start Location", text: $startLocation)
                        .textInputAutocapitalization(.words)

                    TextField("End Location", text: $endLocation)
                        .textInputAutocapitalization(.words)

                    TextField("Miles", text: $miles)
                        .keyboardType(.decimalPad)

                    Toggle("Round Trip", isOn: $isRoundTrip)
                }

                Section("Business Purpose") {
                    Picker("Purpose", selection: $purpose) {
                        ForEach(MileagePurpose.allCases) { purpose in
                            HStack {
                                Image(systemName: purpose.icon)
                                Text(purpose.rawValue)
                            }
                            .tag(purpose)
                        }
                    }

                    TextField("Detailed Description", text: $businessPurpose, axis: .vertical)
                        .lineLimit(3...6)
                }

                if !purpose.isDeductible {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)

                            Text("This purpose is typically not tax deductible")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Mileage Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveLog()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    // MARK: - Actions

    private var canSave: Bool {
        !startLocation.isEmpty &&
        !endLocation.isEmpty &&
        !businessPurpose.isEmpty &&
        Double(miles) != nil
    }

    private func saveLog() {
        guard let milesValue = Double(miles) else { return }

        _ = mileageManager.createMileageLog(
            date: date,
            startLocation: startLocation,
            endLocation: endLocation,
            purpose: purpose,
            businessPurpose: businessPurpose,
            miles: milesValue,
            isRoundTrip: isRoundTrip
        )

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MileageLogView(mileageManager: MileageManager())
    }
}
