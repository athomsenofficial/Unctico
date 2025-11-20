import Foundation

/// Service for tax compliance, 1099 generation, and deduction calculations
@MainActor
class TaxService: ObservableObject {
    static let shared = TaxService()

    @Published var taxSettings: TaxSettings = TaxSettings()

    private let settingsKey = "unctico_tax_settings"

    init() {
        loadSettings()
    }

    // MARK: - 1099 Generation

    /// Generate 1099-NEC form for a contractor based on payments
    func generate1099NEC(
        for contractor: TaxContractor,
        taxYear: Int,
        totalPayments: Double,
        payerInfo: PayerInfo
    ) -> Form1099 {
        Form1099(
            taxYear: taxYear,
            recipientId: contractor.id,
            recipientName: contractor.name,
            recipientTin: contractor.tin,
            recipientAddress: contractor.address,
            payerTin: payerInfo.tin,
            payerName: payerInfo.name,
            payerAddress: payerInfo.address,
            formType: .nec,
            nonemployeeCompensation: totalPayments,
            state: payerInfo.address.state,
            stateIncome: totalPayments
        )
    }

    /// Check if 1099 is required for contractor
    func requires1099(totalPayments: Double) -> Bool {
        totalPayments >= 600
    }

    /// Validate 1099 form data
    func validate1099(_ form: Form1099) -> [String] {
        var errors: [String] = []

        // Validate TIN
        if form.recipientTin.count != 9 {
            errors.append("Invalid Tax ID Number (must be 9 digits)")
        }

        if form.payerTin.count != 9 {
            errors.append("Invalid Payer Tax ID Number (must be 9 digits)")
        }

        // Validate amounts
        if form.nonemployeeCompensation < 0 {
            errors.append("Compensation cannot be negative")
        }

        if form.federalIncomeTaxWithheld < 0 {
            errors.append("Federal tax withheld cannot be negative")
        }

        // Validate addresses
        if form.recipientAddress.street.isEmpty || form.recipientAddress.city.isEmpty {
            errors.append("Recipient address is incomplete")
        }

        if form.payerAddress.street.isEmpty || form.payerAddress.city.isEmpty {
            errors.append("Payer address is incomplete")
        }

        return errors
    }

    /// Generate 1099 PDF (simplified - would use actual PDF generation in production)
    func generate1099PDF(_ form: Form1099) -> String {
        """
        FORM 1099-NEC
        Nonemployee Compensation

        Tax Year: \(form.taxYear)

        PAYER'S Information:
        \(form.payerName)
        TIN: \(formatTIN(form.payerTin))
        \(form.payerAddress.formatted)

        RECIPIENT'S Information:
        \(form.recipientName)
        TIN: \(form.formattedTin)
        \(form.recipientAddress.formatted)

        Box 1 - Nonemployee compensation: $\(String(format: "%.2f", form.nonemployeeCompensation))
        Box 4 - Federal income tax withheld: $\(String(format: "%.2f", form.federalIncomeTaxWithheld))

        State: \(form.state)
        Box 5 - State tax withheld: $\(String(format: "%.2f", form.stateIncomeTaxWithheld))
        Box 6 - State income: $\(String(format: "%.2f", form.stateIncome))

        Form Status: \(form.status.rawValue)
        Created: \(formatDate(form.createdDate))
        \(form.filedDate != nil ? "Filed: \(formatDate(form.filedDate!))" : "")

        Notes: \(form.notes)
        """
    }

    // MARK: - Mileage Calculations

    /// Calculate mileage deduction for a trip
    func calculateMileageDeduction(trip: MileageTrip, year: Int? = nil) -> Double {
        let calendar = Calendar.current
        let tripYear = calendar.component(.year, from: trip.date)
        let rate = MileageRate.rate(for: year ?? tripYear)
        return trip.totalDistance * rate.businessRate
    }

    /// Calculate total mileage deduction for multiple trips
    func calculateTotalMileageDeduction(trips: [MileageTrip]) -> Double {
        trips.reduce(0) { total, trip in
            total + calculateMileageDeduction(trip: trip)
        }
    }

    /// Get mileage statistics
    func getMileageStatistics(trips: [MileageTrip], year: Int) -> MileageStatistics {
        let yearTrips = trips.filter {
            Calendar.current.component(.year, from: $0.date) == year
        }

        let totalMiles = yearTrips.reduce(0) { $0 + $1.totalDistance }
        let totalDeduction = calculateTotalMileageDeduction(trips: yearTrips)

        let tripsByPurpose = Dictionary(grouping: yearTrips, by: { $0.purpose })
            .mapValues { trips in
                trips.reduce(0) { $0 + $1.totalDistance }
            }

        let averageTripDistance = yearTrips.isEmpty ? 0 : totalMiles / Double(yearTrips.count)

        return MileageStatistics(
            year: year,
            totalTrips: yearTrips.count,
            totalMiles: totalMiles,
            totalDeduction: totalDeduction,
            averageTripDistance: averageTripDistance,
            milesByPurpose: tripsByPurpose
        )
    }

    // MARK: - Expense Calculations

    /// Calculate total deductible expenses
    func calculateTotalDeductions(expenses: [BusinessExpense]) -> Double {
        expenses.filter { $0.isTaxDeductible }.reduce(0) { total, expense in
            total + (expense.amount * expense.category.deductionPercentage)
        }
    }

    /// Get expense statistics by category
    func getExpenseStatistics(expenses: [BusinessExpense], year: Int) -> ExpenseStatistics {
        let yearExpenses = expenses.filter {
            Calendar.current.component(.year, from: $0.date) == year
        }

        let totalExpenses = yearExpenses.reduce(0) { $0 + $1.amount }
        let deductibleExpenses = calculateTotalDeductions(expenses: yearExpenses)

        let expensesByCategory = Dictionary(grouping: yearExpenses, by: { $0.category })
            .mapValues { expenses in
                expenses.reduce(0) { $0 + $1.amount }
            }

        let topCategories = expensesByCategory.sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }

        return ExpenseStatistics(
            year: year,
            totalExpenses: totalExpenses,
            deductibleExpenses: deductibleExpenses,
            expensesByCategory: expensesByCategory,
            topCategories: Array(topCategories),
            averageExpense: yearExpenses.isEmpty ? 0 : totalExpenses / Double(yearExpenses.count)
        )
    }

    // MARK: - Tax Year Summary

    /// Generate comprehensive tax year summary
    func generateTaxYearSummary(
        year: Int,
        income: [PaymentTransaction],
        expenses: [BusinessExpense],
        mileageTrips: [MileageTrip],
        forms1099: [Form1099],
        quarterlyPayments: [QuarterlyTaxPayment]
    ) -> TaxYearSummary {
        // Calculate total income
        let yearIncome = income.filter {
            Calendar.current.component(.year, from: $0.transactionDate) == year
        }
        let totalIncome = yearIncome.reduce(0) { $0 + $1.amount }

        // Calculate total expenses
        let yearExpenses = expenses.filter {
            Calendar.current.component(.year, from: $0.date) == year
        }
        let totalExpenses = calculateTotalDeductions(expenses: yearExpenses)

        // Calculate mileage deduction
        let totalMileageDeduction = calculateTotalMileageDeduction(trips: mileageTrips.filter {
            Calendar.current.component(.year, from: $0.date) == year
        })

        // Calculate 1099 income
        let total1099Income = forms1099.filter { $0.taxYear == year }
            .reduce(0) { $0 + $1.nonemployeeCompensation }

        // Calculate totals
        let totalDeductions = totalExpenses + totalMileageDeduction
        let netIncome = totalIncome - totalDeductions

        // Filter quarterly payments
        let yearQuarterlyPayments = quarterlyPayments.filter { $0.year == year }

        return TaxYearSummary(
            year: year,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            totalMileageDeduction: totalMileageDeduction,
            total1099Income: total1099Income,
            totalDeductions: totalDeductions,
            netIncome: netIncome,
            quarterlyPayments: yearQuarterlyPayments
        )
    }

    /// Calculate estimated quarterly tax payment
    func calculateEstimatedQuarterlyPayment(estimatedAnnualIncome: Double) -> Double {
        // Simplified calculation: 30% of annual income / 4 quarters
        let estimatedTax = estimatedAnnualIncome * 0.30
        return estimatedTax / 4
    }

    /// Generate quarterly payment reminders
    func generateQuarterlyPaymentReminders(year: Int, estimatedQuarterlyAmount: Double) -> [QuarterlyTaxPayment] {
        let dueDates = QuarterlyTaxPayment.dueDates(for: year)

        return dueDates.enumerated().map { index, dueDate in
            QuarterlyTaxPayment(
                year: index < 3 ? year : year + 1, // Q4 is paid in next year
                quarter: index + 1,
                dueDate: dueDate,
                amount: estimatedQuarterlyAmount
            )
        }
    }

    // MARK: - Tax Report Generation

    /// Generate comprehensive tax report for the year
    func generateTaxReport(summary: TaxYearSummary) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"

        let incomeStr = formatter.string(from: NSNumber(value: summary.totalIncome)) ?? "$0"
        let expensesStr = formatter.string(from: NSNumber(value: summary.totalExpenses)) ?? "$0"
        let mileageStr = formatter.string(from: NSNumber(value: summary.totalMileageDeduction)) ?? "$0"
        let deductionsStr = formatter.string(from: NSNumber(value: summary.totalDeductions)) ?? "$0"
        let netIncomeStr = formatter.string(from: NSNumber(value: summary.netIncome)) ?? "$0"
        let taxLiabilityStr = formatter.string(from: NSNumber(value: summary.estimatedTaxLiability)) ?? "$0"
        let taxesPaidStr = formatter.string(from: NSNumber(value: summary.taxesPaid)) ?? "$0"
        let taxDueStr = formatter.string(from: NSNumber(value: summary.estimatedTaxDue)) ?? "$0"

        return """
        TAX YEAR \(summary.year) SUMMARY REPORT
        =====================================

        INCOME
        ------
        Total Business Income: \(incomeStr)
        1099 Income Received: \(formatter.string(from: NSNumber(value: summary.total1099Income)) ?? "$0")

        DEDUCTIONS
        ----------
        Business Expenses: \(expensesStr)
        Mileage Deduction: \(mileageStr)
        Total Deductions: \(deductionsStr)

        NET INCOME
        ----------
        Net Business Income: \(netIncomeStr)

        ESTIMATED TAXES
        --------------
        Estimated Tax Liability: \(taxLiabilityStr)
        Quarterly Payments Made: \(taxesPaidStr)
        Estimated Tax Due: \(taxDueStr)

        QUARTERLY PAYMENTS
        -----------------
        \(formatQuarterlyPayments(summary.quarterlyPayments))

        NOTES
        -----
        This is an estimated summary. Please consult with a tax professional
        for accurate tax preparation and filing.

        Self-employment tax and state taxes not included in this estimate.
        """
    }

    /// Export data for tax preparation software
    func exportForTaxSoftware(summary: TaxYearSummary) -> String {
        // CSV format for easy import
        var csv = "Category,Description,Amount\n"
        csv += "Income,Total Business Income,\(summary.totalIncome)\n"
        csv += "Income,1099 Income,\(summary.total1099Income)\n"
        csv += "Deduction,Business Expenses,\(summary.totalExpenses)\n"
        csv += "Deduction,Mileage,\(summary.totalMileageDeduction)\n"
        csv += "Net Income,Net Business Income,\(summary.netIncome)\n"
        csv += "Tax Liability,Estimated Tax,\(summary.estimatedTaxLiability)\n"
        csv += "Tax Payment,Quarterly Payments,\(summary.taxesPaid)\n"

        return csv
    }

    // MARK: - Validation & Compliance

    /// Check if contractor has valid W-9 on file
    func validateContractorCompliance(contractor: TaxContractor) -> [String] {
        var issues: [String] = []

        if contractor.tin.isEmpty {
            issues.append("Missing Tax ID Number")
        }

        if contractor.w9ReceivedDate == nil {
            issues.append("W-9 form not on file")
        }

        if contractor.address.street.isEmpty {
            issues.append("Incomplete address")
        }

        if !contractor.isActive {
            issues.append("Contractor marked as inactive")
        }

        return issues
    }

    /// Get contractors requiring 1099 for the year
    func getContractorsRequiring1099(
        contractors: [TaxContractor],
        payments: [UUID: Double] // Contractor ID -> Total payments
    ) -> [(contractor: TaxContractor, amount: Double)] {
        contractors.compactMap { contractor in
            guard let amount = payments[contractor.id], requires1099(totalPayments: amount) else {
                return nil
            }
            return (contractor, amount)
        }
    }

    /// Check upcoming tax deadlines
    func getUpcomingDeadlines(year: Int) -> [TaxDeadline] {
        let today = Date()
        let calendar = Calendar.current

        var deadlines: [TaxDeadline] = []

        // Quarterly payment deadlines
        let quarterlyDates = QuarterlyTaxPayment.dueDates(for: year)
        for (index, date) in quarterlyDates.enumerated() {
            if date > today {
                deadlines.append(TaxDeadline(
                    date: date,
                    type: .quarterlyPayment,
                    description: "Q\(index + 1) Estimated Tax Payment",
                    isOverdue: false
                ))
            }
        }

        // 1099 filing deadline (January 31)
        var components = DateComponents()
        components.year = year + 1
        components.month = 1
        components.day = 31
        if let deadline1099 = calendar.date(from: components) {
            deadlines.append(TaxDeadline(
                date: deadline1099,
                type: .form1099,
                description: "1099 Forms Due to Recipients",
                isOverdue: deadline1099 < today
            ))
        }

        // Tax return deadline (April 15)
        components.month = 4
        components.day = 15
        if let deadlineTaxReturn = calendar.date(from: components) {
            deadlines.append(TaxDeadline(
                date: deadlineTaxReturn,
                type: .taxReturn,
                description: "Tax Return Filing Deadline",
                isOverdue: deadlineTaxReturn < today
            ))
        }

        return deadlines.sorted { $0.date < $1.date }
    }

    // MARK: - Helper Methods

    private func formatTIN(_ tin: String) -> String {
        if tin.count == 9 {
            return "\(tin.prefix(2))-\(tin.dropFirst(2))"
        }
        return tin
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatQuarterlyPayments(_ payments: [QuarterlyTaxPayment]) -> String {
        payments.map { payment in
            let status = payment.isPaid ? "PAID" : (payment.isOverdue ? "OVERDUE" : "DUE")
            let amount = String(format: "$%.2f", payment.amount)
            let dueDate = formatDate(payment.dueDate)
            return "Q\(payment.quarter): \(amount) - Due: \(dueDate) - Status: \(status)"
        }.joined(separator: "\n")
    }

    // MARK: - Settings Management

    func updateSettings(_ settings: TaxSettings) {
        taxSettings = settings
        saveSettings()
    }

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(TaxSettings.self, from: data) {
            taxSettings = decoded
        }
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(taxSettings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
}

// MARK: - Supporting Types

struct PayerInfo: Codable {
    let name: String
    let tin: String
    let address: TaxAddress

    init(name: String, tin: String, address: TaxAddress) {
        self.name = name
        self.tin = tin
        self.address = address
    }
}

struct TaxSettings: Codable {
    var businessName: String
    var businessTIN: String
    var businessAddress: TaxAddress?
    var fiscalYearEnd: Date
    var trackMileageAutomatically: Bool
    var defaultMileageRate: Double
    var enableQuarterlyReminders: Bool

    init(
        businessName: String = "",
        businessTIN: String = "",
        businessAddress: TaxAddress? = nil,
        fiscalYearEnd: Date = Date(),
        trackMileageAutomatically: Bool = false,
        defaultMileageRate: Double = 0.67,
        enableQuarterlyReminders: Bool = true
    ) {
        self.businessName = businessName
        self.businessTIN = businessTIN
        self.businessAddress = businessAddress
        self.fiscalYearEnd = fiscalYearEnd
        self.trackMileageAutomatically = trackMileageAutomatically
        self.defaultMileageRate = defaultMileageRate
        self.enableQuarterlyReminders = enableQuarterlyReminders
    }
}

struct MileageStatistics {
    let year: Int
    let totalTrips: Int
    let totalMiles: Double
    let totalDeduction: Double
    let averageTripDistance: Double
    let milesByPurpose: [TripPurpose: Double]
}

struct ExpenseStatistics {
    let year: Int
    let totalExpenses: Double
    let deductibleExpenses: Double
    let expensesByCategory: [ExpenseCategory: Double]
    let topCategories: [(ExpenseCategory, Double)]
    let averageExpense: Double
}

struct TaxDeadline {
    let date: Date
    let type: DeadlineType
    let description: String
    let isOverdue: Bool

    enum DeadlineType {
        case quarterlyPayment
        case form1099
        case taxReturn
        case other
    }
}
