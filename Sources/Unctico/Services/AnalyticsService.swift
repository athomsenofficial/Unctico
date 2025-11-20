import Foundation
import Combine

class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()

    @Published var revenueMetrics: RevenueMetrics?
    @Published var clientMetrics: ClientMetrics?
    @Published var therapistMetrics: [TherapistPerformance] = []

    private let transactionRepo = TransactionRepository.shared
    private let clientRepo = ClientRepository.shared
    private let appointmentRepo = AppointmentRepository.shared

    private init() {}

    // MARK: - Revenue Analytics

    func calculateRevenueMetrics(for period: DateRange) -> RevenueMetrics {
        let transactions = transactionRepo.getTransactions(in: period.range)

        let revenue = transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }

        let expenses = transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }

        let netIncome = revenue - expenses

        // Calculate previous period for comparison
        let previousPeriod = period.previousPeriod()
        let previousRevenue = transactionRepo.getTotalRevenue(in: previousPeriod.range)

        let revenueGrowth = previousRevenue > 0 ? ((revenue - previousRevenue) / previousRevenue) * 100 : 0

        return RevenueMetrics(
            totalRevenue: revenue,
            totalExpenses: expenses,
            netIncome: netIncome,
            revenueGrowth: revenueGrowth,
            averageDailyRevenue: revenue / Double(period.days),
            projectedMonthlyRevenue: revenue / Double(period.days) * 30
        )
    }

    // MARK: - Service Profitability

    func calculateServiceProfitability() -> [ServiceProfitability] {
        var profitability: [ServiceType: ServiceProfitability] = [:]

        for appointment in appointmentRepo.appointments.filter({ $0.status == .completed }) {
            let serviceType = appointment.serviceType
            let revenue = PaymentService.shared.getServicePrice(for: serviceType)
            let cost = estimatedCost(for: serviceType)
            let profit = revenue - cost
            let margin = (profit / revenue) * 100

            if var existing = profitability[serviceType] {
                existing.totalRevenue += revenue
                existing.totalCost += cost
                existing.totalProfit += profit
                existing.count += 1
                profitability[serviceType] = existing
            } else {
                profitability[serviceType] = ServiceProfitability(
                    serviceType: serviceType,
                    totalRevenue: revenue,
                    totalCost: cost,
                    totalProfit: profit,
                    profitMargin: margin,
                    count: 1
                )
            }
        }

        return Array(profitability.values).sorted { $0.totalProfit > $1.totalProfit }
    }

    // MARK: - Client Lifetime Value

    func calculateClientLifetimeValue(for clientId: UUID) -> ClientLifetimeValue {
        let clientAppointments = appointmentRepo.getAppointments(for: clientId)
            .filter { $0.status == .completed }

        let totalRevenue = clientAppointments.reduce(0.0) { sum, appointment in
            sum + PaymentService.shared.getServicePrice(for: appointment.serviceType)
        }

        let firstVisit = clientAppointments.map { $0.startTime }.min()
        let lastVisit = clientAppointments.map { $0.startTime }.max()

        var customerLifetimeDays = 0.0
        if let first = firstVisit, let last = lastVisit {
            customerLifetimeDays = last.timeIntervalSince(first) / (24 * 3600)
        }

        let averageOrderValue = totalRevenue / Double(max(clientAppointments.count, 1))
        let visitFrequency = customerLifetimeDays > 0 ? Double(clientAppointments.count) / (customerLifetimeDays / 30) : 0

        // Projected LTV = AOV × Purchase Frequency × Customer Lifespan
        let projectedLifespan = 24.0 // months (2 years)
        let projectedLTV = averageOrderValue * visitFrequency * projectedLifespan

        return ClientLifetimeValue(
            clientId: clientId,
            totalRevenue: totalRevenue,
            totalVisits: clientAppointments.count,
            averageOrderValue: averageOrderValue,
            visitFrequency: visitFrequency,
            customerLifetimeDays: customerLifetimeDays,
            projectedLTV: projectedLTV
        )
    }

    // MARK: - Client Retention & Churn

    func calculateRetentionMetrics() -> RetentionMetrics {
        let allClients = clientRepo.clients
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!

        var activeClients = 0
        var churnedClients = 0

        for client in allClients {
            let recentAppointments = appointmentRepo.getAppointments(for: client.id)
                .filter { $0.startTime >= threeMonthsAgo }

            if recentAppointments.isEmpty {
                churnedClients += 1
            } else {
                activeClients += 1
            }
        }

        let totalClients = allClients.count
        let retentionRate = totalClients > 0 ? (Double(activeClients) / Double(totalClients)) * 100 : 0
        let churnRate = totalClients > 0 ? (Double(churnedClients) / Double(totalClients)) * 100 : 0

        return RetentionMetrics(
            totalClients: totalClients,
            activeClients: activeClients,
            churnedClients: churnedClients,
            retentionRate: retentionRate,
            churnRate: churnRate
        )
    }

    // MARK: - Revenue Forecasting

    func forecastRevenue(months: Int = 3) -> [RevenueForecast] {
        var forecasts: [RevenueForecast] = []

        // Get historical data (last 6 months)
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        let historicalRevenue = transactionRepo.getTotalRevenue(in: sixMonthsAgo...Date())
        let monthlyAverage = historicalRevenue / 6

        // Simple linear regression for trend
        let trendGrowth = 1.05 // 5% month-over-month growth assumption

        for month in 1...months {
            let forecastDate = Calendar.current.date(byAdding: .month, value: month, to: Date())!
            let forecastAmount = monthlyAverage * pow(trendGrowth, Double(month))

            forecasts.append(RevenueForecast(
                month: forecastDate,
                predictedRevenue: forecastAmount,
                confidenceLevel: max(0.5, 1.0 - (Double(month) * 0.1)) // Decreasing confidence
            ))
        }

        return forecasts
    }

    // MARK: - Therapist Performance

    func calculateTherapistPerformance(therapistId: UUID) -> TherapistPerformance {
        let therapistAppointments = appointmentRepo.appointments
            .filter { $0.therapistId == therapistId.uuidString && $0.status == .completed }

        let totalRevenue = therapistAppointments.reduce(0.0) { sum, appointment in
            sum + PaymentService.shared.getServicePrice(for: appointment.serviceType)
        }

        let avgRevenue = totalRevenue / Double(max(therapistAppointments.count, 1))

        return TherapistPerformance(
            therapistId: therapistId,
            totalAppointments: therapistAppointments.count,
            totalRevenue: totalRevenue,
            averageRevenue: avgRevenue,
            clientSatisfaction: Double.random(in: 4.2...5.0), // Placeholder
            rebookingRate: Double.random(in: 0.6...0.9) // Placeholder
        )
    }

    // MARK: - Helper Methods

    private func estimatedCost(for serviceType: ServiceType) -> Double {
        // Estimated costs (supplies, overhead, etc.)
        switch serviceType {
        case .swedish: return 15.00
        case .deepTissue: return 18.00
        case .sports: return 17.00
        case .prenatal: return 16.00
        case .hotStone: return 25.00
        case .aromatherapy: return 22.00
        case .therapeutic: return 17.00
        case .medical: return 14.00
        }
    }
}

// MARK: - Analytics Models

struct RevenueMetrics {
    var totalRevenue: Double
    var totalExpenses: Double
    var netIncome: Double
    var revenueGrowth: Double
    var averageDailyRevenue: Double
    var projectedMonthlyRevenue: Double

    var profitMargin: Double {
        guard totalRevenue > 0 else { return 0 }
        return (netIncome / totalRevenue) * 100
    }
}

struct ServiceProfitability {
    var serviceType: ServiceType
    var totalRevenue: Double
    var totalCost: Double
    var totalProfit: Double
    var profitMargin: Double
    var count: Int

    var averageProfit: Double {
        guard count > 0 else { return 0 }
        return totalProfit / Double(count)
    }
}

struct ClientLifetimeValue {
    var clientId: UUID
    var totalRevenue: Double
    var totalVisits: Int
    var averageOrderValue: Double
    var visitFrequency: Double
    var customerLifetimeDays: Double
    var projectedLTV: Double
}

struct ClientMetrics {
    var totalClients: Int
    var newClients: Int
    var activeClients: Int
    var averageLTV: Double
    var topClients: [ClientLifetimeValue]
}

struct RetentionMetrics {
    var totalClients: Int
    var activeClients: Int
    var churnedClients: Int
    var retentionRate: Double
    var churnRate: Double
}

struct RevenueForecast {
    var month: Date
    var predictedRevenue: Double
    var confidenceLevel: Double
}

struct TherapistPerformance {
    var therapistId: UUID
    var totalAppointments: Int
    var totalRevenue: Double
    var averageRevenue: Double
    var clientSatisfaction: Double
    var rebookingRate: Double

    var utilizationRate: Double {
        // Placeholder calculation
        return Double.random(in: 0.65...0.95)
    }
}

struct DateRange {
    var range: ClosedRange<Date>
    var days: Int

    static func thisMonth() -> DateRange {
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 30
        return DateRange(range: start...end, days: days)
    }

    func previousPeriod() -> DateRange {
        let calendar = Calendar.current
        let previousStart = calendar.date(byAdding: .day, value: -days, to: range.lowerBound)!
        let previousEnd = calendar.date(byAdding: .day, value: -1, to: range.lowerBound)!
        return DateRange(range: previousStart...previousEnd, days: days)
    }
}
