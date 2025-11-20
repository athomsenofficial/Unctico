import Foundation

/// Repository for managing tax compliance data
@MainActor
class TaxRepository: ObservableObject {
    static let shared = TaxRepository()

    @Published var contractors: [TaxContractor] = []
    @Published var forms1099: [Form1099] = []
    @Published var mileageTrips: [MileageTrip] = []
    @Published var vehicles: [Vehicle] = []
    @Published var expenses: [BusinessExpense] = []
    @Published var quarterlyPayments: [QuarterlyTaxPayment] = []
    @Published var taxDocuments: [TaxDocument] = []

    private let contractorsKey = "unctico_tax_contractors"
    private let forms1099Key = "unctico_forms_1099"
    private let mileageTripsKey = "unctico_mileage_trips"
    private let vehiclesKey = "unctico_vehicles"
    private let expensesKey = "unctico_business_expenses"
    private let quarterlyPaymentsKey = "unctico_quarterly_payments"
    private let taxDocumentsKey = "unctico_tax_documents"

    init() {
        loadData()
    }

    // MARK: - Contractor Management

    func addContractor(_ contractor: TaxContractor) {
        contractors.append(contractor)
        saveContractors()
    }

    func updateContractor(_ contractor: TaxContractor) {
        if let index = contractors.firstIndex(where: { $0.id == contractor.id }) {
            contractors[index] = contractor
            saveContractors()
        }
    }

    func deleteContractor(_ contractorId: UUID) {
        contractors.removeAll { $0.id == contractorId }
        saveContractors()
    }

    func getContractor(id: UUID) -> TaxContractor? {
        contractors.first { $0.id == id }
    }

    func getActiveContractors() -> [TaxContractor] {
        contractors.filter { $0.isActive }
    }

    func getContractorsMissingW9() -> [TaxContractor] {
        contractors.filter { $0.w9ReceivedDate == nil }
    }

    // MARK: - 1099 Form Management

    func add1099Form(_ form: Form1099) {
        forms1099.append(form)
        saveForms1099()
    }

    func update1099Form(_ form: Form1099) {
        if let index = forms1099.firstIndex(where: { $0.id == form.id }) {
            forms1099[index] = form
            saveForms1099()
        }
    }

    func delete1099Form(_ formId: UUID) {
        forms1099.removeAll { $0.id == formId }
        saveForms1099()
    }

    func get1099Forms(for taxYear: Int) -> [Form1099] {
        forms1099.filter { $0.taxYear == taxYear }
    }

    func get1099Forms(for contractorId: UUID) -> [Form1099] {
        forms1099.filter { $0.recipientId == contractorId }
            .sorted { $0.taxYear > $1.taxYear }
    }

    func getUnfiled1099Forms() -> [Form1099] {
        forms1099.filter { $0.status == .draft || $0.status == .reviewed }
    }

    // MARK: - Mileage Trip Management

    func addMileageTrip(_ trip: MileageTrip) {
        mileageTrips.append(trip)
        saveMileageTrips()
    }

    func updateMileageTrip(_ trip: MileageTrip) {
        if let index = mileageTrips.firstIndex(where: { $0.id == trip.id }) {
            mileageTrips[index] = trip
            saveMileageTrips()
        }
    }

    func deleteMileageTrip(_ tripId: UUID) {
        mileageTrips.removeAll { $0.id == tripId }
        saveMileageTrips()
    }

    func getMileageTrips(for year: Int) -> [MileageTrip] {
        mileageTrips.filter {
            Calendar.current.component(.year, from: $0.date) == year
        }.sorted { $0.date > $1.date }
    }

    func getMileageTrips(for vehicleId: UUID) -> [MileageTrip] {
        mileageTrips.filter { $0.vehicleId == vehicleId }
            .sorted { $0.date > $1.date }
    }

    func getMileageTrips(for clientId: UUID) -> [MileageTrip] {
        mileageTrips.filter { $0.clientId == clientId }
            .sorted { $0.date > $1.date }
    }

    func getMileageTrips(from startDate: Date, to endDate: Date) -> [MileageTrip] {
        mileageTrips.filter { $0.date >= startDate && $0.date <= endDate }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Vehicle Management

    func addVehicle(_ vehicle: Vehicle) {
        vehicles.append(vehicle)
        saveVehicles()
    }

    func updateVehicle(_ vehicle: Vehicle) {
        if let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) {
            vehicles[index] = vehicle
            saveVehicles()
        }
    }

    func deleteVehicle(_ vehicleId: UUID) {
        vehicles.removeAll { $0.id == vehicleId }
        saveVehicles()
    }

    func getActiveVehicles() -> [Vehicle] {
        vehicles.filter { $0.isActive }
    }

    func getPrimaryVehicle() -> Vehicle? {
        getActiveVehicles().first
    }

    // MARK: - Business Expense Management

    func addExpense(_ expense: BusinessExpense) {
        expenses.append(expense)
        saveExpenses()
    }

    func updateExpense(_ expense: BusinessExpense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            saveExpenses()
        }
    }

    func deleteExpense(_ expenseId: UUID) {
        expenses.removeAll { $0.id == expenseId }
        saveExpenses()
    }

    func getExpenses(for year: Int) -> [BusinessExpense] {
        expenses.filter {
            Calendar.current.component(.year, from: $0.date) == year
        }.sorted { $0.date > $1.date }
    }

    func getExpenses(for category: ExpenseCategory) -> [BusinessExpense] {
        expenses.filter { $0.category == category }
            .sorted { $0.date > $1.date }
    }

    func getExpenses(from startDate: Date, to endDate: Date) -> [BusinessExpense] {
        expenses.filter { $0.date >= startDate && $0.date <= endDate }
            .sorted { $0.date > $1.date }
    }

    func getRecurringExpenses() -> [BusinessExpense] {
        expenses.filter { $0.isRecurring }
    }

    // MARK: - Quarterly Payment Management

    func addQuarterlyPayment(_ payment: QuarterlyTaxPayment) {
        quarterlyPayments.append(payment)
        saveQuarterlyPayments()
    }

    func updateQuarterlyPayment(_ payment: QuarterlyTaxPayment) {
        if let index = quarterlyPayments.firstIndex(where: { $0.id == payment.id }) {
            quarterlyPayments[index] = payment
            saveQuarterlyPayments()
        }
    }

    func deleteQuarterlyPayment(_ paymentId: UUID) {
        quarterlyPayments.removeAll { $0.id == paymentId }
        saveQuarterlyPayments()
    }

    func getQuarterlyPayments(for year: Int) -> [QuarterlyTaxPayment] {
        quarterlyPayments.filter { $0.year == year }
            .sorted { $0.quarter < $1.quarter }
    }

    func getUnpaidQuarterlyPayments() -> [QuarterlyTaxPayment] {
        quarterlyPayments.filter { !$0.isPaid }
            .sorted { $0.dueDate < $1.dueDate }
    }

    func getOverdueQuarterlyPayments() -> [QuarterlyTaxPayment] {
        quarterlyPayments.filter { $0.isOverdue }
            .sorted { $0.dueDate < $1.dueDate }
    }

    func markQuarterlyPaymentAsPaid(_ paymentId: UUID, date: Date, confirmationNumber: String) {
        if let index = quarterlyPayments.firstIndex(where: { $0.id == paymentId }) {
            var payment = quarterlyPayments[index]
            quarterlyPayments[index] = QuarterlyTaxPayment(
                id: payment.id,
                year: payment.year,
                quarter: payment.quarter,
                dueDate: payment.dueDate,
                amount: payment.amount,
                paymentDate: date,
                confirmationNumber: confirmationNumber,
                notes: payment.notes
            )
            saveQuarterlyPayments()
        }
    }

    // MARK: - Tax Document Management

    func addTaxDocument(_ document: TaxDocument) {
        taxDocuments.append(document)
        saveTaxDocuments()
    }

    func updateTaxDocument(_ document: TaxDocument) {
        if let index = taxDocuments.firstIndex(where: { $0.id == document.id }) {
            taxDocuments[index] = document
            saveTaxDocuments()
        }
    }

    func deleteTaxDocument(_ documentId: UUID) {
        taxDocuments.removeAll { $0.id == documentId }
        saveTaxDocuments()
    }

    func getTaxDocuments(for year: Int) -> [TaxDocument] {
        taxDocuments.filter { $0.year == year }
            .sorted { $0.uploadDate > $1.uploadDate }
    }

    func getTaxDocuments(for type: TaxDocumentType) -> [TaxDocument] {
        taxDocuments.filter { $0.documentType == type }
            .sorted { $0.uploadDate > $1.uploadDate }
    }

    // MARK: - Statistics & Analytics

    func getContractorPaymentTotal(contractorId: UUID, year: Int, transactions: [PaymentTransaction]) -> Double {
        transactions.filter {
            $0.clientId == contractorId &&
            Calendar.current.component(.year, from: $0.transactionDate) == year
        }.reduce(0) { $0 + $1.amount }
    }

    func getTaxYearStatistics(year: Int) -> TaxYearStats {
        let yearExpenses = getExpenses(for: year)
        let yearTrips = getMileageTrips(for: year)
        let yearForms = get1099Forms(for: taxYear: year)
        let yearPayments = getQuarterlyPayments(for: year)

        let totalExpenses = yearExpenses.reduce(0) { $0 + $1.amount }
        let totalMiles = yearTrips.reduce(0) { $0 + $1.totalDistance }
        let total1099Payments = yearForms.reduce(0) { $0 + $1.nonemployeeCompensation }
        let totalQuarterlyPayments = yearPayments.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }

        let expensesByCategory = Dictionary(grouping: yearExpenses, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }

        let mileageByPurpose = Dictionary(grouping: yearTrips, by: { $0.purpose })
            .mapValues { $0.reduce(0) { $0 + $1.totalDistance } }

        return TaxYearStats(
            year: year,
            totalExpenses: totalExpenses,
            totalMiles: totalMiles,
            total1099Payments: total1099Payments,
            totalQuarterlyPayments: totalQuarterlyPayments,
            expensesByCategory: expensesByCategory,
            mileageByPurpose: mileageByPurpose,
            forms1099Count: yearForms.count,
            tripsCount: yearTrips.count,
            expensesCount: yearExpenses.count
        )
    }

    func getRecentActivity(limit: Int = 10) -> [TaxActivity] {
        var activities: [TaxActivity] = []

        // Recent expenses
        for expense in expenses.prefix(limit) {
            activities.append(TaxActivity(
                date: expense.date,
                type: .expense,
                description: "\(expense.category.rawValue): \(expense.description)",
                amount: expense.amount
            ))
        }

        // Recent trips
        for trip in mileageTrips.prefix(limit) {
            let deduction = TaxService.shared.calculateMileageDeduction(trip: trip)
            activities.append(TaxActivity(
                date: trip.date,
                type: .mileage,
                description: "\(trip.purpose.rawValue): \(trip.startLocation) to \(trip.endLocation)",
                amount: deduction
            ))
        }

        return activities.sorted { $0.date > $1.date }.prefix(limit).map { $0 }
    }

    // MARK: - Data Export

    func exportMileageLog(for year: Int) -> String {
        let trips = getMileageTrips(for: year)

        var csv = "Date,Purpose,Start Location,End Location,Distance (miles),Description,Client,Deduction\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        for trip in trips {
            let deduction = TaxService.shared.calculateMileageDeduction(trip: trip)
            let date = dateFormatter.string(from: trip.date)
            let purpose = trip.purpose.rawValue
            let start = trip.startLocation.replacingOccurrences(of: ",", with: ";")
            let end = trip.endLocation.replacingOccurrences(of: ",", with: ";")
            let distance = String(format: "%.2f", trip.totalDistance)
            let description = trip.description.replacingOccurrences(of: ",", with: ";")
            let client = trip.clientName ?? "N/A"
            let deductionStr = String(format: "%.2f", deduction)

            csv += "\(date),\(purpose),\(start),\(end),\(distance),\(description),\(client),\(deductionStr)\n"
        }

        return csv
    }

    func exportExpenseReport(for year: Int) -> String {
        let yearExpenses = getExpenses(for: year)

        var csv = "Date,Category,Merchant,Description,Amount,Deductible,Payment Method,Receipt\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        for expense in yearExpenses {
            let date = dateFormatter.string(from: expense.date)
            let category = expense.category.rawValue
            let merchant = expense.merchant.replacingOccurrences(of: ",", with: ";")
            let description = expense.description.replacingOccurrences(of: ",", with: ";")
            let amount = String(format: "%.2f", expense.amount)
            let deductible = expense.isTaxDeductible ? "Yes" : "No"
            let payment = expense.paymentMethod
            let receipt = expense.receiptImagePath != nil ? "Yes" : "No"

            csv += "\(date),\(category),\(merchant),\(description),\(amount),\(deductible),\(payment),\(receipt)\n"
        }

        return csv
    }

    func export1099Summary(for year: Int) -> String {
        let forms = get1099Forms(for: taxYear: year)

        var csv = "Recipient Name,TIN,Address,Compensation,Status,Filed Date\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        for form in forms {
            let name = form.recipientName.replacingOccurrences(of: ",", with: ";")
            let tin = form.formattedTin
            let address = "\(form.recipientAddress.street) \(form.recipientAddress.city) \(form.recipientAddress.state)".replacingOccurrences(of: ",", with: ";")
            let compensation = String(format: "%.2f", form.nonemployeeCompensation)
            let status = form.status.rawValue
            let filedDate = form.filedDate != nil ? dateFormatter.string(from: form.filedDate!) : "Not Filed"

            csv += "\(name),\(tin),\(address),\(compensation),\(status),\(filedDate)\n"
        }

        return csv
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: contractorsKey),
           let decoded = try? JSONDecoder().decode([TaxContractor].self, from: data) {
            contractors = decoded
        }

        if let data = UserDefaults.standard.data(forKey: forms1099Key),
           let decoded = try? JSONDecoder().decode([Form1099].self, from: data) {
            forms1099 = decoded
        }

        if let data = UserDefaults.standard.data(forKey: mileageTripsKey),
           let decoded = try? JSONDecoder().decode([MileageTrip].self, from: data) {
            mileageTrips = decoded
        }

        if let data = UserDefaults.standard.data(forKey: vehiclesKey),
           let decoded = try? JSONDecoder().decode([Vehicle].self, from: data) {
            vehicles = decoded
        }

        if let data = UserDefaults.standard.data(forKey: expensesKey),
           let decoded = try? JSONDecoder().decode([BusinessExpense].self, from: data) {
            expenses = decoded
        }

        if let data = UserDefaults.standard.data(forKey: quarterlyPaymentsKey),
           let decoded = try? JSONDecoder().decode([QuarterlyTaxPayment].self, from: data) {
            quarterlyPayments = decoded
        }

        if let data = UserDefaults.standard.data(forKey: taxDocumentsKey),
           let decoded = try? JSONDecoder().decode([TaxDocument].self, from: data) {
            taxDocuments = decoded
        }
    }

    private func saveContractors() {
        if let encoded = try? JSONEncoder().encode(contractors) {
            UserDefaults.standard.set(encoded, forKey: contractorsKey)
        }
    }

    private func saveForms1099() {
        if let encoded = try? JSONEncoder().encode(forms1099) {
            UserDefaults.standard.set(encoded, forKey: forms1099Key)
        }
    }

    private func saveMileageTrips() {
        if let encoded = try? JSONEncoder().encode(mileageTrips) {
            UserDefaults.standard.set(encoded, forKey: mileageTripsKey)
        }
    }

    private func saveVehicles() {
        if let encoded = try? JSONEncoder().encode(vehicles) {
            UserDefaults.standard.set(encoded, forKey: vehiclesKey)
        }
    }

    private func saveExpenses() {
        if let encoded = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encoded, forKey: expensesKey)
        }
    }

    private func saveQuarterlyPayments() {
        if let encoded = try? JSONEncoder().encode(quarterlyPayments) {
            UserDefaults.standard.set(encoded, forKey: quarterlyPaymentsKey)
        }
    }

    private func saveTaxDocuments() {
        if let encoded = try? JSONEncoder().encode(taxDocuments) {
            UserDefaults.standard.set(encoded, forKey: taxDocumentsKey)
        }
    }
}

// MARK: - Supporting Types

struct TaxYearStats {
    let year: Int
    let totalExpenses: Double
    let totalMiles: Double
    let total1099Payments: Double
    let totalQuarterlyPayments: Double
    let expensesByCategory: [ExpenseCategory: Double]
    let mileageByPurpose: [TripPurpose: Double]
    let forms1099Count: Int
    let tripsCount: Int
    let expensesCount: Int
}

struct TaxActivity {
    let date: Date
    let type: ActivityType
    let description: String
    let amount: Double

    enum ActivityType {
        case expense
        case mileage
        case payment
        case form1099
    }
}
