import SwiftUI

/// Comprehensive tax compliance view for managing business finances
struct TaxComplianceView: View {
    @StateObject private var repository = TaxRepository.shared
    @StateObject private var taxService = TaxService.shared
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                TaxOverviewView(selectedYear: $selectedYear)
                    .tabItem {
                        Label("Overview", systemImage: "chart.bar.fill")
                    }
                    .tag(0)

                MileageTrackingView(selectedYear: $selectedYear)
                    .tabItem {
                        Label("Mileage", systemImage: "car.fill")
                    }
                    .tag(1)

                ExpenseTrackingView(selectedYear: $selectedYear)
                    .tabItem {
                        Label("Expenses", systemImage: "dollarsign.circle.fill")
                    }
                    .tag(2)

                Forms1099View(selectedYear: $selectedYear)
                    .tabItem {
                        Label("1099 Forms", systemImage: "doc.text.fill")
                    }
                    .tag(3)

                TaxSettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(4)
            }
            .navigationTitle("Tax Compliance")
        }
    }
}

// MARK: - Tax Overview

struct TaxOverviewView: View {
    @Binding var selectedYear: Int
    @StateObject private var repository = TaxRepository.shared
    @StateObject private var taxService = TaxService.shared

    var statistics: TaxYearStats {
        repository.getTaxYearStatistics(year: selectedYear)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Year selector
                YearPickerView(selectedYear: $selectedYear)
                    .padding(.horizontal)

                // Quick stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(
                        title: "Total Expenses",
                        value: statistics.totalExpenses,
                        icon: "dollarsign.circle.fill",
                        color: .red
                    )

                    StatCard(
                        title: "Miles Driven",
                        value: statistics.totalMiles,
                        icon: "car.fill",
                        color: .blue,
                        isCurrency: false
                    )

                    StatCard(
                        title: "1099 Payments",
                        value: statistics.total1099Payments,
                        icon: "doc.text.fill",
                        color: .green
                    )

                    StatCard(
                        title: "Quarterly Paid",
                        value: statistics.totalQuarterlyPayments,
                        icon: "calendar.fill",
                        color: .purple
                    )
                }
                .padding(.horizontal)

                // Upcoming deadlines
                UpcomingDeadlinesSection(year: selectedYear)
                    .padding(.horizontal)

                // Recent activity
                RecentActivitySection()
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    var isCurrency: Bool = true

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(formattedValue)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    var formattedValue: String {
        if isCurrency {
            return String(format: "$%.0f", value)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

struct UpcomingDeadlinesSection: View {
    let year: Int
    @StateObject private var taxService = TaxService.shared

    var deadlines: [TaxDeadline] {
        taxService.getUpcomingDeadlines(year: year).prefix(5).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Deadlines")
                .font(.headline)

            if deadlines.isEmpty {
                Text("No upcoming deadlines")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(deadlines, id: \.date) { deadline in
                    DeadlineRow(deadline: deadline)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DeadlineRow: View {
    let deadline: TaxDeadline

    var body: some View {
        HStack {
            Image(systemName: deadline.isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                .foregroundColor(deadline.isOverdue ? .red : .blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(deadline.description)
                    .font(.subheadline)

                Text(deadline.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if deadline.isOverdue {
                Text("OVERDUE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(4)
            }
        }
    }
}

struct RecentActivitySection: View {
    @StateObject private var repository = TaxRepository.shared

    var activities: [TaxActivity] {
        repository.getRecentActivity(limit: 5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)

            if activities.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(activities, id: \.date) { activity in
                    ActivityRow(activity: activity)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let activity: TaxActivity

    var body: some View {
        HStack {
            Image(systemName: activity.type == .expense ? "cart.fill" : "car.fill")
                .foregroundColor(activity.type == .expense ? .red : .blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(activity.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(String(format: "$%.2f", activity.amount))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Mileage Tracking

struct MileageTrackingView: View {
    @Binding var selectedYear: Int
    @StateObject private var repository = TaxRepository.shared
    @State private var showingAddTrip = false

    var trips: [MileageTrip] {
        repository.getMileageTrips(for: selectedYear)
    }

    var totalDeduction: Double {
        TaxService.shared.calculateTotalMileageDeduction(trips: trips)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Summary header
            VStack(spacing: 8) {
                Text("Total Deduction: \(String(format: "$%.2f", totalDeduction))")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(trips.count) trips • \(String(format: "%.0f", trips.reduce(0) { $0 + $1.totalDistance })) miles")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))

            List {
                if trips.isEmpty {
                    ContentUnavailableView(
                        "No Mileage Trips",
                        systemImage: "car",
                        description: Text("Track your business mileage for tax deductions")
                    )
                } else {
                    ForEach(trips) { trip in
                        MileageTripRow(trip: trip)
                    }
                    .onDelete(perform: deleteTrips)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddTrip = true }) {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Button(action: exportMileageLog) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingAddTrip) {
            AddMileageTripView()
        }
    }

    func deleteTrips(at offsets: IndexSet) {
        offsets.forEach { index in
            let trip = trips[index]
            repository.deleteMileageTrip(trip.id)
        }
    }

    func exportMileageLog() {
        let csv = repository.exportMileageLog(for: selectedYear)
        // In production, present share sheet with CSV
        print(csv)
    }
}

struct MileageTripRow: View {
    let trip: MileageTrip

    var deduction: Double {
        TaxService.shared.calculateMileageDeduction(trip: trip)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: trip.purpose.icon)
                    .foregroundColor(.blue)

                Text(trip.purpose.rawValue)
                    .font(.headline)

                Spacer()

                Text(trip.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("\(trip.startLocation) → \(trip.endLocation)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Label(String(format: "%.1f mi", trip.totalDistance), systemImage: "road.lanes")
                    .font(.caption)

                Spacer()

                Text(String(format: "$%.2f", deduction))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddMileageTripView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var repository = TaxRepository.shared

    @State private var date = Date()
    @State private var startLocation = ""
    @State private var endLocation = ""
    @State private var distance = ""
    @State private var purpose: TripPurpose = .clientVisit
    @State private var description = ""
    @State private var isRoundTrip = false

    var body: some View {
        NavigationView {
            Form {
                Section("Trip Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    Picker("Purpose", selection: $purpose) {
                        ForEach(TripPurpose.allCases, id: \.self) { purpose in
                            Text(purpose.rawValue).tag(purpose)
                        }
                    }
                }

                Section("Locations") {
                    TextField("Start Location", text: $startLocation)
                    TextField("End Location", text: $endLocation)

                    HStack {
                        Text("Distance (miles)")
                        TextField("0.0", text: $distance)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    Toggle("Round Trip", isOn: $isRoundTrip)
                }

                Section("Additional Info") {
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Mileage Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTrip() }
                        .disabled(startLocation.isEmpty || endLocation.isEmpty || distance.isEmpty)
                }
            }
        }
    }

    func saveTrip() {
        guard let distanceValue = Double(distance), distanceValue > 0 else { return }

        let trip = MileageTrip(
            date: date,
            startLocation: startLocation,
            endLocation: endLocation,
            distance: distanceValue,
            purpose: purpose,
            description: description,
            isRoundTrip: isRoundTrip
        )

        repository.addMileageTrip(trip)
        dismiss()
    }
}

// MARK: - Expense Tracking

struct ExpenseTrackingView: View {
    @Binding var selectedYear: Int
    @StateObject private var repository = TaxRepository.shared
    @State private var showingAddExpense = false

    var expenses: [BusinessExpense] {
        repository.getExpenses(for: selectedYear)
    }

    var totalDeductions: Double {
        TaxService.shared.calculateTotalDeductions(expenses: expenses)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Summary header
            VStack(spacing: 8) {
                Text("Total Deductions: \(String(format: "$%.2f", totalDeductions))")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(expenses.count) expenses tracked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))

            List {
                if expenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses",
                        systemImage: "dollarsign.circle",
                        description: Text("Track your business expenses for tax deductions")
                    )
                } else {
                    ForEach(expenses) { expense in
                        ExpenseRow(expense: expense)
                    }
                    .onDelete(perform: deleteExpenses)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddExpense = true }) {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Button(action: exportExpenseReport) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView()
        }
    }

    func deleteExpenses(at offsets: IndexSet) {
        offsets.forEach { index in
            let expense = expenses[index]
            repository.deleteExpense(expense.id)
        }
    }

    func exportExpenseReport() {
        let csv = repository.exportExpenseReport(for: selectedYear)
        // In production, present share sheet with CSV
        print(csv)
    }
}

struct ExpenseRow: View {
    let expense: BusinessExpense

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: expense.category.icon)
                    .foregroundColor(.red)

                Text(expense.category.rawValue)
                    .font(.headline)

                Spacer()

                Text(expense.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("\(expense.merchant) - \(expense.description)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                if expense.isTaxDeductible {
                    Label("Deductible", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }

                Spacer()

                Text(String(format: "$%.2f", expense.amount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var repository = TaxRepository.shared

    @State private var date = Date()
    @State private var category: ExpenseCategory = .supplies
    @State private var amount = ""
    @State private var merchant = ""
    @State private var description = ""
    @State private var isTaxDeductible = true

    var body: some View {
        NavigationView {
            Form {
                Section("Expense Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }.tag(category)
                        }
                    }

                    HStack {
                        Text("$")
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }

                    TextField("Merchant", text: $merchant)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Toggle("Tax Deductible", isOn: $isTaxDeductible)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveExpense() }
                        .disabled(amount.isEmpty || merchant.isEmpty || description.isEmpty)
                }
            }
        }
    }

    func saveExpense() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }

        let expense = BusinessExpense(
            date: date,
            category: category,
            amount: amountValue,
            merchant: merchant,
            description: description,
            isTaxDeductible: isTaxDeductible
        )

        repository.addExpense(expense)
        dismiss()
    }
}

// MARK: - 1099 Forms

struct Forms1099View: View {
    @Binding var selectedYear: Int
    @StateObject private var repository = TaxRepository.shared

    var forms: [Form1099] {
        repository.get1099Forms(for: taxYear: selectedYear)
    }

    var body: some View {
        List {
            if forms.isEmpty {
                ContentUnavailableView(
                    "No 1099 Forms",
                    systemImage: "doc.text",
                    description: Text("1099 forms will appear here when contractors are paid $600 or more")
                )
            } else {
                ForEach(forms) { form in
                    Form1099Row(form: form)
                }
            }
        }
    }
}

struct Form1099Row: View {
    let form: Form1099

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(form.recipientName)
                    .font(.headline)

                Spacer()

                StatusBadge1099(status: form.status)
            }

            Text("TIN: \(form.formattedTin)")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text("Compensation:")
                    .font(.subheadline)

                Spacer()

                Text(String(format: "$%.2f", form.nonemployeeCompensation))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }

            if let filedDate = form.filedDate {
                Text("Filed: \(filedDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge1099: View {
    let status: FormStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(status.color).opacity(0.2))
            .foregroundColor(Color(status.color))
            .cornerRadius(4)
    }
}

// MARK: - Tax Settings

struct TaxSettingsView: View {
    @StateObject private var taxService = TaxService.shared
    @State private var settings: TaxSettings

    init() {
        _settings = State(initialValue: TaxService.shared.taxSettings)
    }

    var body: some View {
        Form {
            Section("Business Information") {
                TextField("Business Name", text: $settings.businessName)
                TextField("Business TIN/EIN", text: $settings.businessTIN)
                    .keyboardType(.numberPad)
            }

            Section("Mileage Tracking") {
                Toggle("Track Automatically", isOn: $settings.trackMileageAutomatically)

                HStack {
                    Text("Default Rate (per mile)")
                    TextField("0.67", value: $settings.defaultMileageRate, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Reminders") {
                Toggle("Quarterly Tax Reminders", isOn: $settings.enableQuarterlyReminders)
            }
        }
        .navigationTitle("Tax Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    taxService.updateSettings(settings)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct YearPickerView: View {
    @Binding var selectedYear: Int

    private let years: [Int] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 5)...currentYear).reversed()
    }()

    var body: some View {
        Picker("Tax Year", selection: $selectedYear) {
            ForEach(years, id: \.self) { year in
                Text(String(year)).tag(year)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    TaxComplianceView()
}
