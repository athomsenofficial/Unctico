import Foundation

/// Analytics and reporting models for comprehensive business insights

// MARK: - Business Metrics

/// Key performance indicators for the practice
struct BusinessMetrics: Codable {
    let period: DateRange
    let revenue: RevenueMetrics
    let clients: ClientMetrics
    let appointments: AppointmentMetrics
    let services: ServiceMetrics
    let financial: FinancialMetrics
    let growth: GrowthMetrics

    var profitMargin: Double {
        guard revenue.total > 0 else { return 0 }
        return (revenue.total - financial.totalExpenses) / revenue.total * 100
    }

    var averageRevenuePerClient: Double {
        guard clients.activeClients > 0 else { return 0 }
        return revenue.total / Double(clients.activeClients)
    }
}

struct DateRange: Codable {
    let startDate: Date
    let endDate: Date
    let label: String

    init(startDate: Date, endDate: Date, label: String = "") {
        self.startDate = startDate
        self.endDate = endDate
        self.label = label.isEmpty ? "\(startDate.formatted(date: .abbreviated, time: .omitted)) - \(endDate.formatted(date: .abbreviated, time: .omitted))" : label
    }

    var dayCount: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
}

// MARK: - Revenue Metrics

struct RevenueMetrics: Codable {
    let total: Double
    let byService: [UUID: Double] // Service ID -> Revenue
    let byPaymentMethod: [String: Double]
    let averageTransactionValue: Double
    let totalTransactions: Int
    let refunds: Double
    let netRevenue: Double

    var growthRate: Double?
    var previousPeriodTotal: Double?

    var refundRate: Double {
        guard total > 0 else { return 0 }
        return (refunds / total) * 100
    }

    func calculateGrowth(previous: Double) -> Double {
        guard previous > 0 else { return 0 }
        return ((total - previous) / previous) * 100
    }
}

// MARK: - Client Metrics

struct ClientMetrics: Codable {
    let totalClients: Int
    let newClients: Int
    let activeClients: Int
    let returningClients: Int
    let inactiveClients: Int
    let clientRetentionRate: Double
    let averageLifetimeValue: Double
    let topClients: [ClientRanking]

    var newClientRate: Double {
        guard totalClients > 0 else { return 0 }
        return (Double(newClients) / Double(totalClients)) * 100
    }

    var activeClientRate: Double {
        guard totalClients > 0 else { return 0 }
        return (Double(activeClients) / Double(totalClients)) * 100
    }
}

struct ClientRanking: Codable, Identifiable {
    let id: UUID
    let name: String
    let totalSpent: Double
    let visitCount: Int
    let lastVisit: Date
    let rank: Int
}

// MARK: - Appointment Metrics

struct AppointmentMetrics: Codable {
    let totalAppointments: Int
    let completedAppointments: Int
    let cancelledAppointments: Int
    let noShowAppointments: Int
    let completionRate: Double
    let cancellationRate: Double
    let noShowRate: Double
    let averageBookingLeadTime: Double // Days in advance
    let peakDays: [String: Int] // Day of week -> Count
    let peakHours: [Int: Int] // Hour -> Count
    let utilizationRate: Double // % of available slots filled

    var showUpRate: Double {
        return 100 - (cancellationRate + noShowRate)
    }
}

// MARK: - Service Metrics

struct ServiceMetrics: Codable {
    let totalServices: Int
    let servicePerformance: [ServicePerformance]
    let mostPopularService: String?
    let highestRevenueService: String?
    let averageServiceDuration: Double

    func topServices(by metric: ServiceRankingMetric, limit: Int = 5) -> [ServicePerformance] {
        let sorted: [ServicePerformance]

        switch metric {
        case .revenue:
            sorted = servicePerformance.sorted { $0.revenue > $1.revenue }
        case .bookings:
            sorted = servicePerformance.sorted { $0.bookingCount > $1.bookingCount }
        case .growth:
            sorted = servicePerformance.sorted { ($0.growthRate ?? 0) > ($1.growthRate ?? 0) }
        }

        return Array(sorted.prefix(limit))
    }
}

struct ServicePerformance: Codable, Identifiable {
    let id: UUID
    let name: String
    let bookingCount: Int
    let revenue: Double
    let averagePrice: Double
    let utilizationRate: Double
    let growthRate: Double?

    var revenuePerBooking: Double {
        guard bookingCount > 0 else { return 0 }
        return revenue / Double(bookingCount)
    }
}

enum ServiceRankingMetric {
    case revenue
    case bookings
    case growth
}

// MARK: - Financial Metrics

struct FinancialMetrics: Codable {
    let totalIncome: Double
    let totalExpenses: Double
    let netProfit: Double
    let profitMargin: Double
    let expensesByCategory: [String: Double]
    let taxableIncome: Double
    let estimatedTaxLiability: Double
    let outstandingInvoices: Double
    let accountsReceivable: Double

    var operatingExpenseRatio: Double {
        guard totalIncome > 0 else { return 0 }
        return (totalExpenses / totalIncome) * 100
    }
}

// MARK: - Growth Metrics

struct GrowthMetrics: Codable {
    let revenueGrowth: Double // % change
    let clientGrowth: Double // % change
    let appointmentGrowth: Double // % change
    let averageMonthlyGrowth: Double
    let projectedAnnualRevenue: Double
    let trendDirection: TrendDirection

    var isGrowing: Bool {
        return revenueGrowth > 0
    }
}

enum TrendDirection: String, Codable {
    case stronglyUp = "Strongly Increasing"
    case up = "Increasing"
    case stable = "Stable"
    case down = "Decreasing"
    case stronglyDown = "Strongly Decreasing"

    static func from(growthRate: Double) -> TrendDirection {
        switch growthRate {
        case 10...: return .stronglyUp
        case 3..<10: return .up
        case -3..<3: return .stable
        case -10..<(-3): return .down
        default: return .stronglyDown
        }
    }
}

// MARK: - Report Types

enum ReportType: String, CaseIterable {
    case revenue = "Revenue Report"
    case clients = "Client Report"
    case services = "Service Performance"
    case financial = "Financial Summary"
    case tax = "Tax Report"
    case appointments = "Appointment Analysis"
    case comprehensive = "Comprehensive Business Report"

    var icon: String {
        switch self {
        case .revenue: return "dollarsign.circle.fill"
        case .clients: return "person.3.fill"
        case .services: return "list.bullet.rectangle.fill"
        case .financial: return "chart.line.uptrend.xyaxis"
        case .tax: return "doc.text.fill"
        case .appointments: return "calendar.fill"
        case .comprehensive: return "doc.richtext.fill"
        }
    }

    var description: String {
        switch self {
        case .revenue: return "Revenue breakdown by service, payment method, and time period"
        case .clients: return "Client acquisition, retention, and lifetime value analysis"
        case .services: return "Service popularity, revenue, and utilization rates"
        case .financial: return "Income, expenses, profit margins, and financial health"
        case .tax: return "Tax deductions, 1099 forms, and quarterly payments"
        case .appointments: return "Booking patterns, cancellations, and utilization"
        case .comprehensive: return "Complete business overview with all key metrics"
        }
    }
}

// MARK: - Time Period

enum TimePeriod: String, CaseIterable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case quarter = "This Quarter"
    case year = "This Year"
    case custom = "Custom Range"

    func dateRange(from date: Date = Date()) -> DateRange {
        let calendar = Calendar.current

        switch self {
        case .today:
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return DateRange(startDate: start, endDate: end, label: "Today")

        case .week:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            return DateRange(startDate: start, endDate: end, label: "This Week")

        case .month:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return DateRange(startDate: start, endDate: end, label: "This Month")

        case .quarter:
            let month = calendar.component(.month, from: date)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year], from: date)
            components.month = quarterStartMonth
            components.day = 1
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: .month, value: 3, to: start)!
            return DateRange(startDate: start, endDate: end, label: "This Quarter")

        case .year:
            let start = calendar.date(from: calendar.dateComponents([.year], from: date))!
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return DateRange(startDate: start, endDate: end, label: "This Year")

        case .custom:
            // Return current month as default for custom
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return DateRange(startDate: start, endDate: end, label: "Custom Range")
        }
    }
}

// MARK: - Chart Data

struct ChartData: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: String?
    let metadata: [String: Any]?

    init(label: String, value: Double, color: String? = nil, metadata: [String: Any]? = nil) {
        self.label = label
        self.value = value
        self.color = color
        self.metadata = metadata
    }
}

struct TimeSeriesData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let category: String?

    init(date: Date, value: Double, category: String? = nil) {
        self.date = date
        self.value = value
        self.category = category
    }
}

// MARK: - Dashboard Widgets

enum DashboardWidget: String, CaseIterable {
    case todayRevenue = "Today's Revenue"
    case weekRevenue = "Week Revenue"
    case monthRevenue = "Month Revenue"
    case activeClients = "Active Clients"
    case newClients = "New Clients"
    case todayAppointments = "Today's Appointments"
    case weekAppointments = "Week Appointments"
    case completionRate = "Completion Rate"
    case cancellationRate = "Cancellation Rate"
    case topService = "Top Service"
    case profitMargin = "Profit Margin"
    case upcomingDeadlines = "Tax Deadlines"

    var icon: String {
        switch self {
        case .todayRevenue, .weekRevenue, .monthRevenue: return "dollarsign.circle.fill"
        case .activeClients, .newClients: return "person.3.fill"
        case .todayAppointments, .weekAppointments: return "calendar.fill"
        case .completionRate: return "checkmark.circle.fill"
        case .cancellationRate: return "xmark.circle.fill"
        case .topService: return "star.fill"
        case .profitMargin: return "chart.line.uptrend.xyaxis"
        case .upcomingDeadlines: return "clock.fill"
        }
    }

    var color: String {
        switch self {
        case .todayRevenue, .weekRevenue, .monthRevenue: return "green"
        case .activeClients, .newClients: return "blue"
        case .todayAppointments, .weekAppointments: return "purple"
        case .completionRate: return "green"
        case .cancellationRate: return "red"
        case .topService: return "orange"
        case .profitMargin: return "blue"
        case .upcomingDeadlines: return "red"
        }
    }
}

// MARK: - Benchmark Metrics

struct BenchmarkMetrics: Codable {
    let category: BenchmarkCategory
    let actualValue: Double
    let industryAverage: Double
    let difference: Double
    let percentile: Int // Where you rank (1-100)

    var isAboveAverage: Bool {
        return actualValue > industryAverage
    }

    var performanceRating: PerformanceRating {
        if percentile >= 90 { return .excellent }
        if percentile >= 75 { return .good }
        if percentile >= 50 { return .average }
        if percentile >= 25 { return .belowAverage }
        return .poor
    }
}

enum BenchmarkCategory: String, Codable {
    case clientRetention = "Client Retention Rate"
    case averageBookingValue = "Average Booking Value"
    case utilizationRate = "Utilization Rate"
    case noShowRate = "No-Show Rate"
    case profitMargin = "Profit Margin"
    case revenuePerClient = "Revenue Per Client"

    var industryAverage: Double {
        switch self {
        case .clientRetention: return 75.0 // 75%
        case .averageBookingValue: return 85.0 // $85
        case .utilizationRate: return 70.0 // 70%
        case .noShowRate: return 5.0 // 5%
        case .profitMargin: return 35.0 // 35%
        case .revenuePerClient: return 450.0 // $450 annually
        }
    }
}

enum PerformanceRating: String, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case average = "Average"
    case belowAverage = "Below Average"
    case poor = "Poor"

    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .average: return "orange"
        case .belowAverage: return "red"
        case .poor: return "red"
        }
    }
}

// MARK: - Goals & Targets

struct BusinessGoal: Identifiable, Codable {
    let id: UUID
    let name: String
    let targetValue: Double
    let currentValue: Double
    let startDate: Date
    let endDate: Date
    let category: GoalCategory
    let metric: String
    let notes: String

    init(
        id: UUID = UUID(),
        name: String,
        targetValue: Double,
        currentValue: Double,
        startDate: Date,
        endDate: Date,
        category: GoalCategory,
        metric: String,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.startDate = startDate
        self.endDate = endDate
        self.category = category
        self.metric = metric
        self.notes = notes
    }

    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return (currentValue / targetValue) * 100
    }

    var isAchieved: Bool {
        return currentValue >= targetValue
    }

    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }

    var status: GoalStatus {
        if isAchieved { return .achieved }
        if Date() > endDate { return .expired }
        if progress >= 75 { return .onTrack }
        if progress >= 50 { return .atRisk }
        return .behindSchedule
    }
}

enum GoalCategory: String, Codable, CaseIterable {
    case revenue = "Revenue"
    case clients = "Clients"
    case bookings = "Bookings"
    case retention = "Retention"
    case growth = "Growth"
    case profit = "Profit"

    var icon: String {
        switch self {
        case .revenue: return "dollarsign.circle.fill"
        case .clients: return "person.3.fill"
        case .bookings: return "calendar.fill"
        case .retention: return "arrow.clockwise"
        case .growth: return "chart.line.uptrend.xyaxis"
        case .profit: return "chart.bar.fill"
        }
    }
}

enum GoalStatus: String, Codable {
    case achieved = "Achieved"
    case onTrack = "On Track"
    case atRisk = "At Risk"
    case behindSchedule = "Behind Schedule"
    case expired = "Expired"

    var color: String {
        switch self {
        case .achieved: return "green"
        case .onTrack: return "blue"
        case .atRisk: return "orange"
        case .behindSchedule: return "red"
        case .expired: return "gray"
        }
    }
}

// MARK: - Alert Conditions

struct BusinessAlert: Identifiable, Codable {
    let id: UUID
    let alertType: AlertType
    let severity: AlertSeverity
    let message: String
    let recommendedAction: String
    let detectedDate: Date
    let isResolved: Bool

    init(
        id: UUID = UUID(),
        alertType: AlertType,
        severity: AlertSeverity,
        message: String,
        recommendedAction: String,
        detectedDate: Date = Date(),
        isResolved: Bool = false
    ) {
        self.id = id
        self.alertType = alertType
        self.severity = severity
        self.message = message
        self.recommendedAction = recommendedAction
        self.detectedDate = detectedDate
        self.isResolved = isResolved
    }
}

enum AlertType: String, Codable {
    case revenueDrop = "Revenue Drop"
    case highCancellations = "High Cancellation Rate"
    case lowRetention = "Low Client Retention"
    case cashFlowIssue = "Cash Flow Issue"
    case taxDeadline = "Tax Deadline Approaching"
    case lowUtilization = "Low Booking Utilization"
    case expiredLicense = "License Expiring"
    case missedGoal = "Goal Behind Schedule"
}

enum AlertSeverity: String, Codable {
    case critical = "Critical"
    case warning = "Warning"
    case info = "Info"

    var color: String {
        switch self {
        case .critical: return "red"
        case .warning: return "orange"
        case .info: return "blue"
        }
    }
}
