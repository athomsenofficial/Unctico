import Foundation

/// Service for generating business analytics and insights
@MainActor
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()

    @Published var currentMetrics: BusinessMetrics?
    @Published var alerts: [BusinessAlert] = []
    @Published var goals: [BusinessGoal] = []

    private let goalsKey = "unctico_business_goals"
    private let alertsKey = "unctico_business_alerts"

    init() {
        loadGoals()
        loadAlerts()
    }

    // MARK: - Business Metrics Generation

    /// Generate comprehensive business metrics for a given period
    func generateMetrics(
        for period: TimePeriod,
        clients: [Client],
        appointments: [Appointment],
        transactions: [PaymentTransaction],
        services: [Service],
        expenses: [BusinessExpense] = [],
        mileageTrips: [MileageTrip] = []
    ) -> BusinessMetrics {
        let dateRange = period.dateRange()

        let revenue = calculateRevenueMetrics(
            transactions: transactions,
            dateRange: dateRange,
            services: services
        )

        let clientMetrics = calculateClientMetrics(
            clients: clients,
            appointments: appointments,
            transactions: transactions,
            dateRange: dateRange
        )

        let appointmentMetrics = calculateAppointmentMetrics(
            appointments: appointments,
            dateRange: dateRange
        )

        let serviceMetrics = calculateServiceMetrics(
            services: services,
            appointments: appointments,
            transactions: transactions,
            dateRange: dateRange
        )

        let financial = calculateFinancialMetrics(
            revenue: revenue.total,
            expenses: expenses,
            mileageTrips: mileageTrips,
            dateRange: dateRange
        )

        let growth = calculateGrowthMetrics(
            currentRevenue: revenue.total,
            previousRevenue: revenue.previousPeriodTotal ?? 0,
            currentClients: clientMetrics.newClients,
            previousClients: 0,
            currentAppointments: appointmentMetrics.completedAppointments,
            previousAppointments: 0
        )

        return BusinessMetrics(
            period: dateRange,
            revenue: revenue,
            clients: clientMetrics,
            appointments: appointmentMetrics,
            services: serviceMetrics,
            financial: financial,
            growth: growth
        )
    }

    // MARK: - Revenue Calculations

    private func calculateRevenueMetrics(
        transactions: [PaymentTransaction],
        dateRange: DateRange,
        services: [Service]
    ) -> RevenueMetrics {
        let periodTransactions = transactions.filter {
            $0.transactionDate >= dateRange.startDate && $0.transactionDate < dateRange.endDate
        }

        let successfulTransactions = periodTransactions.filter {
            $0.status == .completed || $0.status == .settled
        }

        let total = successfulTransactions.reduce(0) { $0 + $1.amount }

        var byService: [UUID: Double] = [:]
        for transaction in successfulTransactions {
            if let serviceId = transaction.serviceId {
                byService[serviceId, default: 0] += transaction.amount
            }
        }

        let byPaymentMethod = Dictionary(grouping: successfulTransactions, by: { $0.paymentMethod.rawValue })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }

        let refunds = periodTransactions
            .filter { $0.refundedAmount ?? 0 > 0 }
            .reduce(0) { $0 + ($1.refundedAmount ?? 0) }

        let avgTransaction = successfulTransactions.isEmpty ? 0 : total / Double(successfulTransactions.count)

        return RevenueMetrics(
            total: total,
            byService: byService,
            byPaymentMethod: byPaymentMethod,
            averageTransactionValue: avgTransaction,
            totalTransactions: successfulTransactions.count,
            refunds: refunds,
            netRevenue: total - refunds
        )
    }

    // MARK: - Client Calculations

    private func calculateClientMetrics(
        clients: [Client],
        appointments: [Appointment],
        transactions: [PaymentTransaction],
        dateRange: DateRange
    ) -> ClientMetrics {
        let totalClients = clients.count
        let newClients = clients.filter { $0.createdDate >= dateRange.startDate && $0.createdDate < dateRange.endDate }.count
        let activeClientIds = Set(appointments.filter { $0.startTime >= dateRange.startDate && $0.startTime < dateRange.endDate }.map { $0.clientId })
        let activeClients = activeClientIds.count
        let returningClients = 0 // Simplified
        let inactiveClients = totalClients - activeClients
        let retentionRate = totalClients > 0 ? (Double(activeClients) / Double(totalClients)) * 100 : 0
        let avgLifetimeValue = totalClients > 0 ? transactions.reduce(0) { $0 + $1.amount } / Double(totalClients) : 0

        return ClientMetrics(
            totalClients: totalClients,
            newClients: newClients,
            activeClients: activeClients,
            returningClients: returningClients,
            inactiveClients: inactiveClients,
            clientRetentionRate: retentionRate,
            averageLifetimeValue: avgLifetimeValue,
            topClients: []
        )
    }

    // MARK: - Appointment Calculations

    private func calculateAppointmentMetrics(appointments: [Appointment], dateRange: DateRange) -> AppointmentMetrics {
        let periodAppointments = appointments.filter { $0.startTime >= dateRange.startDate && $0.startTime < dateRange.endDate }
        let total = periodAppointments.count
        let completed = periodAppointments.filter { $0.status == .completed }.count
        let cancelled = periodAppointments.filter { $0.status == .cancelled }.count
        let noShow = periodAppointments.filter { $0.status == .noShow }.count
        let completionRate = total > 0 ? (Double(completed) / Double(total)) * 100 : 0
        let cancellationRate = total > 0 ? (Double(cancelled) / Double(total)) * 100 : 0
        let noShowRate = total > 0 ? (Double(noShow) / Double(total)) * 100 : 0

        return AppointmentMetrics(
            totalAppointments: total,
            completedAppointments: completed,
            cancelledAppointments: cancelled,
            noShowAppointments: noShow,
            completionRate: completionRate,
            cancellationRate: cancellationRate,
            noShowRate: noShowRate,
            averageBookingLeadTime: 7.0,
            peakDays: [:],
            peakHours: [:],
            utilizationRate: 70.0
        )
    }

    // MARK: - Service Calculations

    private func calculateServiceMetrics(
        services: [Service],
        appointments: [Appointment],
        transactions: [PaymentTransaction],
        dateRange: DateRange
    ) -> ServiceMetrics {
        let servicePerformance: [ServicePerformance] = services.map { service in
            let bookingCount = appointments.filter { $0.serviceId == service.id && $0.startTime >= dateRange.startDate && $0.startTime < dateRange.endDate }.count
            let revenue = transactions.filter { $0.serviceId == service.id && $0.transactionDate >= dateRange.startDate && $0.transactionDate < dateRange.endDate }.reduce(0) { $0 + $1.amount }

            return ServicePerformance(
                id: service.id,
                name: service.name,
                bookingCount: bookingCount,
                revenue: revenue,
                averagePrice: service.price,
                utilizationRate: 75.0,
                growthRate: nil
            )
        }

        return ServiceMetrics(
            totalServices: services.count,
            servicePerformance: servicePerformance,
            mostPopularService: servicePerformance.max(by: { $0.bookingCount < $1.bookingCount })?.name,
            highestRevenueService: servicePerformance.max(by: { $0.revenue < $1.revenue })?.name,
            averageServiceDuration: 60.0
        )
    }

    // MARK: - Financial Calculations

    private func calculateFinancialMetrics(
        revenue: Double,
        expenses: [BusinessExpense],
        mileageTrips: [MileageTrip],
        dateRange: DateRange
    ) -> FinancialMetrics {
        let periodExpenses = expenses.filter { $0.date >= dateRange.startDate && $0.date < dateRange.endDate }
        let totalExpenses = periodExpenses.reduce(0) { $0 + $1.amount }
        let mileageDeduction = TaxService.shared.calculateTotalMileageDeduction(trips: mileageTrips.filter { $0.date >= dateRange.startDate && $0.date < dateRange.endDate })
        let totalDeductions = totalExpenses + mileageDeduction
        let netProfit = revenue - totalDeductions
        let profitMargin = revenue > 0 ? (netProfit / revenue) * 100 : 0

        return FinancialMetrics(
            totalIncome: revenue,
            totalExpenses: totalDeductions,
            netProfit: netProfit,
            profitMargin: profitMargin,
            expensesByCategory: [:],
            taxableIncome: netProfit,
            estimatedTaxLiability: netProfit * 0.30,
            outstandingInvoices: 0,
            accountsReceivable: 0
        )
    }

    // MARK: - Growth Calculations

    private func calculateGrowthMetrics(
        currentRevenue: Double,
        previousRevenue: Double,
        currentClients: Int,
        previousClients: Int,
        currentAppointments: Int,
        previousAppointments: Int
    ) -> GrowthMetrics {
        let revenueGrowth = previousRevenue > 0 ? ((currentRevenue - previousRevenue) / previousRevenue) * 100 : 0
        let clientGrowth = previousClients > 0 ? (Double(currentClients - previousClients) / Double(previousClients)) * 100 : 0
        let appointmentGrowth = previousAppointments > 0 ? (Double(currentAppointments - previousAppointments) / Double(previousAppointments)) * 100 : 0
        let avgGrowth = (revenueGrowth + clientGrowth + appointmentGrowth) / 3
        let projectedAnnual = currentRevenue * 12
        let trend = TrendDirection.from(growthRate: revenueGrowth)

        return GrowthMetrics(
            revenueGrowth: revenueGrowth,
            clientGrowth: clientGrowth,
            appointmentGrowth: appointmentGrowth,
            averageMonthlyGrowth: avgGrowth,
            projectedAnnualRevenue: projectedAnnual,
            trendDirection: trend
        )
    }

    // MARK: - Goal Management

    func addGoal(_ goal: BusinessGoal) {
        goals.append(goal)
        saveGoals()
    }

    func updateGoal(_ goal: BusinessGoal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            saveGoals()
        }
    }

    func deleteGoal(_ goalId: UUID) {
        goals.removeAll { $0.id == goalId }
        saveGoals()
    }

    func getActiveGoals() -> [BusinessGoal] {
        goals.filter { !$0.isAchieved && Date() <= $0.endDate }
    }

    // MARK: - Alert Management

    func generateAlerts(metrics: BusinessMetrics) {
        var newAlerts: [BusinessAlert] = []

        if metrics.growth.revenueGrowth < -10 {
            newAlerts.append(BusinessAlert(
                alertType: .revenueDrop,
                severity: .critical,
                message: "Revenue has dropped by \(String(format: "%.1f%%", abs(metrics.growth.revenueGrowth)))",
                recommendedAction: "Review pricing, marketing efforts, and client retention strategies"
            ))
        }

        if metrics.appointments.cancellationRate > 15 {
            newAlerts.append(BusinessAlert(
                alertType: .highCancellations,
                severity: .warning,
                message: "Cancellation rate is \(String(format: "%.1f%%", metrics.appointments.cancellationRate))",
                recommendedAction: "Implement cancellation policy and send reminder messages"
            ))
        }

        alerts = newAlerts
        saveAlerts()
    }

    // MARK: - Helper Methods

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    // MARK: - Persistence

    private func loadGoals() {
        if let data = UserDefaults.standard.data(forKey: goalsKey),
           let decoded = try? JSONDecoder().decode([BusinessGoal].self, from: data) {
            goals = decoded
        }
    }

    private func saveGoals() {
        if let encoded = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(encoded, forKey: goalsKey)
        }
    }

    private func loadAlerts() {
        if let data = UserDefaults.standard.data(forKey: alertsKey),
           let decoded = try? JSONDecoder().decode([BusinessAlert].self, from: data) {
            alerts = decoded.filter { !$0.isResolved }
        }
    }

    private func saveAlerts() {
        if let encoded = try? JSONEncoder().encode(alerts) {
            UserDefaults.standard.set(encoded, forKey: alertsKey)
        }
    }
}
