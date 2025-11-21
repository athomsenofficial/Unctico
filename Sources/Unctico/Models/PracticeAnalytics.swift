import Foundation

/// Analytics and metrics for practice performance tracking
struct PracticeAnalytics: Codable {
    let periodStart: Date
    let periodEnd: Date
    var clientMetrics: ClientMetrics
    var revenueMetrics: RevenueMetrics
    var appointmentMetrics: AppointmentMetrics
    var treatmentMetrics: TreatmentMetrics
    var outcomeMetrics: OutcomeMetrics

    init(
        periodStart: Date,
        periodEnd: Date,
        clientMetrics: ClientMetrics = ClientMetrics(),
        revenueMetrics: RevenueMetrics = RevenueMetrics(),
        appointmentMetrics: AppointmentMetrics = AppointmentMetrics(),
        treatmentMetrics: TreatmentMetrics = TreatmentMetrics(),
        outcomeMetrics: OutcomeMetrics = OutcomeMetrics()
    ) {
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.clientMetrics = clientMetrics
        self.revenueMetrics = revenueMetrics
        self.appointmentMetrics = appointmentMetrics
        self.treatmentMetrics = treatmentMetrics
        self.outcomeMetrics = outcomeMetrics
    }
}

// MARK: - Client Metrics

struct ClientMetrics: Codable {
    var totalClients: Int = 0
    var newClients: Int = 0
    var activeClients: Int = 0
    var inactiveClients: Int = 0
    var retentionRate: Double = 0.0
    var averageLifetimeValue: Double = 0.0
    var clientsBySource: [String: Int] = [:]
    var clientsByAgeGroup: [AgeGroup: Int] = [:]
    var clientsByGender: [String: Int] = [:]

    enum AgeGroup: String, Codable, CaseIterable {
        case under18 = "Under 18"
        case age18to30 = "18-30"
        case age31to45 = "31-45"
        case age46to60 = "46-60"
        case age61to75 = "61-75"
        case over75 = "Over 75"

        static func group(for age: Int) -> AgeGroup {
            switch age {
            case 0..<18: return .under18
            case 18..<31: return .age18to30
            case 31..<46: return .age31to45
            case 46..<61: return .age46to60
            case 61..<76: return .age61to75
            default: return .over75
            }
        }
    }
}

// MARK: - Revenue Metrics

struct RevenueMetrics: Codable {
    var totalRevenue: Double = 0.0
    var projectedRevenue: Double = 0.0
    var averageTransactionValue: Double = 0.0
    var revenueByService: [String: Double] = [:]
    var revenueByTherapist: [String: Double] = [:]
    var revenueByPaymentMethod: [PaymentMethod: Double] = [:]
    var outstandingBalance: Double = 0.0
    var collectionRate: Double = 0.0
    var revenueGrowthRate: Double = 0.0
    var dailyAverageRevenue: Double = 0.0
    var topRevenueDay: Date?
    var topRevenueAmount: Double = 0.0

    enum PaymentMethod: String, Codable, CaseIterable {
        case cash = "Cash"
        case creditCard = "Credit Card"
        case debitCard = "Debit Card"
        case check = "Check"
        case insurance = "Insurance"
        case hsa = "HSA/FSA"
        case other = "Other"

        var icon: String {
            switch self {
            case .cash: return "dollarsign.circle.fill"
            case .creditCard: return "creditcard.fill"
            case .debitCard: return "cre ditcard"
            case .check: return "doc.text.fill"
            case .insurance: return "cross.case.fill"
            case .hsa: return "heart.text.square.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }
}

// MARK: - Appointment Metrics

struct AppointmentMetrics: Codable {
    var totalAppointments: Int = 0
    var completedAppointments: Int = 0
    var cancelledAppointments: Int = 0
    var noShowAppointments: Int = 0
    var rescheduledAppointments: Int = 0
    var completionRate: Double = 0.0
    var cancellationRate: Double = 0.0
    var noShowRate: Double = 0.0
    var averageAppointmentsPerClient: Double = 0.0
    var appointmentsByDayOfWeek: [Int: Int] = [:] // 1 = Sunday, 7 = Saturday
    var appointmentsByHourOfDay: [Int: Int] = [:]
    var appointmentsByService: [String: Int] = [:]
    var appointmentsByTherapist: [String: Int] = [:]
    var averageSessionDuration: TimeInterval = 0
    var utilizationRate: Double = 0.0 // Booked hours / Available hours
    var peakBookingTime: String = ""
    var slowestBookingTime: String = ""

    var busiestDay: String {
        guard let maxDay = appointmentsByDayOfWeek.max(by: { $0.value < $1.value }) else {
            return "Unknown"
        }
        return dayName(for: maxDay.key)
    }

    var busiestHour: String {
        guard let maxHour = appointmentsByHourOfDay.max(by: { $0.value < $1.value }) else {
            return "Unknown"
        }
        return "\(maxHour.key):00"
    }

    private func dayName(for day: Int) -> String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[day - 1]
    }
}

// MARK: - Treatment Metrics

struct TreatmentMetrics: Codable {
    var totalTreatmentSessions: Int = 0
    var treatmentsByType: [String: Int] = [:]
    var treatmentsByBodyRegion: [String: Int] = [:]
    var averageTreatmentDuration: TimeInterval = 0
    var mostCommonConditions: [String: Int] = [:]
    var techniqueUtilization: [String: Int] = [:]
    var modalityUtilization: [String: Int] = [:]
    var averagePainReduction: Double = 0.0
    var clientSatisfactionScore: Double = 0.0
    var referralsMade: Int = 0
    var adverseEvents: Int = 0
    var protocolsUsed: [String: Int] = [:]
}

// MARK: - Outcome Metrics

struct OutcomeMetrics: Codable {
    var totalOutcomeAssessments: Int = 0
    var assessmentsByType: [String: Int] = [:]
    var averageScoreImprovement: [String: Double] = [:] // Measure type -> improvement
    var clientsShowingImprovement: Int = 0
    var clientsShowingNoChange: Int = 0
    var clientsShowingDeclne: Int = 0
    var improvementRate: Double = 0.0
    var averageTimeToImprovement: TimeInterval = 0
    var goalAttainmentRate: Double = 0.0
}

// MARK: - Time Period Presets

enum AnalyticsPeriod: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case thisQuarter = "This Quarter"
    case thisYear = "This Year"
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case last90Days = "Last 90 Days"
    case lastYear = "Last Year"
    case custom = "Custom Range"

    var dateRange: (start: Date, end: Date) {
        let now = Date()
        let calendar = Calendar.current

        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            return (start, now)

        case .thisWeek:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return (start, now)

        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return (start, now)

        case .thisQuarter:
            let month = calendar.component(.month, from: now)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year], from: now)
            components.month = quarterStartMonth
            components.day = 1
            let start = calendar.date(from: components)!
            return (start, now)

        case .thisYear:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return (start, now)

        case .last7Days:
            let start = calendar.date(byAdding: .day, value: -7, to: now)!
            return (start, now)

        case .last30Days:
            let start = calendar.date(byAdding: .day, value: -30, to: now)!
            return (start, now)

        case .last90Days:
            let start = calendar.date(byAdding: .day, value: -90, to: now)!
            return (start, now)

        case .lastYear:
            let start = calendar.date(byAdding: .year, value: -1, to: now)!
            return (start, now)

        case .custom:
            return (now, now) // Should be overridden
        }
    }

    var icon: String {
        switch self {
        case .today: return "calendar.badge.clock"
        case .thisWeek: return "calendar"
        case .thisMonth: return "calendar.circle"
        case .thisQuarter: return "calendar.badge.exclamationmark"
        case .thisYear: return "calendar.badge.clock"
        case .last7Days: return "7.circle"
        case .last30Days: return "30.circle"
        case .last90Days: return "90.circle"
        case .lastYear: return "calendar"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - Chart Data Models

struct ChartDataPoint: Identifiable, Codable {
    let id: UUID
    let date: Date
    let value: Double
    let label: String?

    init(
        id: UUID = UUID(),
        date: Date,
        value: Double,
        label: String? = nil
    ) {
        self.id = id
        self.date = date
        self.value = value
        self.label = label
    }
}

struct CategoryChartData: Identifiable, Codable {
    let id: UUID
    let category: String
    let value: Double
    let percentage: Double?

    init(
        id: UUID = UUID(),
        category: String,
        value: Double,
        percentage: Double? = nil
    ) {
        self.id = id
        self.category = category
        self.value = value
        self.percentage = percentage
    }
}

// MARK: - KPI (Key Performance Indicator)

struct KPI: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let change: Double? // Percentage change from previous period
    let trend: Trend
    let icon: String
    let color: String
    let subtitle: String?

    enum Trend {
        case up
        case down
        case stable

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }

        var color: String {
            switch self {
            case .up: return "green"
            case .down: return "red"
            case .stable: return "gray"
            }
        }
    }

    init(
        title: String,
        value: String,
        change: Double? = nil,
        trend: Trend = .stable,
        icon: String,
        color: String,
        subtitle: String? = nil
    ) {
        self.title = title
        self.value = value
        self.change = change
        self.trend = trend
        self.icon = icon
        self.color = color
        self.subtitle = subtitle
    }
}

// MARK: - Analytics Service

@MainActor
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()

    private init() {}

    /// Generate analytics for a specific period
    func generateAnalytics(
        for period: AnalyticsPeriod,
        customStart: Date? = nil,
        customEnd: Date? = nil
    ) -> PracticeAnalytics {
        let (start, end) = period == .custom && customStart != nil && customEnd != nil
            ? (customStart!, customEnd!)
            : period.dateRange

        // TODO: Fetch actual data from repositories
        // This is a placeholder implementation with mock data

        var analytics = PracticeAnalytics(
            periodStart: start,
            periodEnd: end
        )

        // Calculate metrics
        analytics.clientMetrics = calculateClientMetrics(start: start, end: end)
        analytics.revenueMetrics = calculateRevenueMetrics(start: start, end: end)
        analytics.appointmentMetrics = calculateAppointmentMetrics(start: start, end: end)
        analytics.treatmentMetrics = calculateTreatmentMetrics(start: start, end: end)
        analytics.outcomeMetrics = calculateOutcomeMetrics(start: start, end: end)

        return analytics
    }

    /// Generate KPIs for dashboard
    func generateKPIs(from analytics: PracticeAnalytics) -> [KPI] {
        return [
            KPI(
                title: "Total Revenue",
                value: formatCurrency(analytics.revenueMetrics.totalRevenue),
                change: analytics.revenueMetrics.revenueGrowthRate,
                trend: analytics.revenueMetrics.revenueGrowthRate > 0 ? .up : .down,
                icon: "dollarsign.circle.fill",
                color: "green",
                subtitle: "vs. previous period"
            ),
            KPI(
                title: "Active Clients",
                value: "\(analytics.clientMetrics.activeClients)",
                change: nil,
                trend: .stable,
                icon: "person.3.fill",
                color: "blue",
                subtitle: "\(analytics.clientMetrics.newClients) new this period"
            ),
            KPI(
                title: "Appointments",
                value: "\(analytics.appointmentMetrics.completedAppointments)",
                change: nil,
                trend: .stable,
                icon: "calendar.badge.checkmark",
                color: "purple",
                subtitle: "\(analytics.appointmentMetrics.completionRate.formatted(.percent.precision(.fractionLength(0)))) completion rate"
            ),
            KPI(
                title: "Retention Rate",
                value: analytics.clientMetrics.retentionRate.formatted(.percent.precision(.fractionLength(0))),
                change: nil,
                trend: analytics.clientMetrics.retentionRate >= 0.8 ? .up : .down,
                icon: "arrow.clockwise.circle.fill",
                color: "orange",
                subtitle: "client retention"
            ),
            KPI(
                title: "Avg. Transaction",
                value: formatCurrency(analytics.revenueMetrics.averageTransactionValue),
                change: nil,
                trend: .stable,
                icon: "chart.bar.fill",
                color: "teal",
                subtitle: "per appointment"
            ),
            KPI(
                title: "Utilization",
                value: analytics.appointmentMetrics.utilizationRate.formatted(.percent.precision(.fractionLength(0))),
                change: nil,
                trend: analytics.appointmentMetrics.utilizationRate >= 0.7 ? .up : .down,
                icon: "gauge.high",
                color: "indigo",
                subtitle: "schedule utilization"
            )
        ]
    }

    // MARK: - Private Calculation Methods

    private func calculateClientMetrics(start: Date, end: Date) -> ClientMetrics {
        // TODO: Implement actual calculation from client repository
        var metrics = ClientMetrics()
        metrics.totalClients = 150
        metrics.newClients = 12
        metrics.activeClients = 98
        metrics.inactiveClients = 52
        metrics.retentionRate = 0.85
        metrics.averageLifetimeValue = 1250.0
        metrics.clientsBySource = [
            "Referral": 45,
            "Google Search": 32,
            "Social Media": 28,
            "Walk-in": 18,
            "Insurance Network": 27
        ]
        metrics.clientsByAgeGroup = [
            .under18: 5,
            .age18to30: 25,
            .age31to45: 48,
            .age46to60: 42,
            .age61to75: 25,
            .over75: 5
        ]
        return metrics
    }

    private func calculateRevenueMetrics(start: Date, end: Date) -> RevenueMetrics {
        // TODO: Implement actual calculation
        var metrics = RevenueMetrics()
        metrics.totalRevenue = 42500.0
        metrics.projectedRevenue = 48000.0
        metrics.averageTransactionValue = 125.0
        metrics.revenueByService = [
            "60-min Massage": 18000.0,
            "90-min Massage": 15000.0,
            "30-min Massage": 4500.0,
            "Cupping": 3000.0,
            "Hot Stone": 2000.0
        ]
        metrics.revenueByPaymentMethod = [
            .creditCard: 28000.0,
            .cash: 8500.0,
            .insurance: 4000.0,
            .hsa: 2000.0
        ]
        metrics.revenueGrowthRate = 0.15
        metrics.dailyAverageRevenue = 1416.67
        return metrics
    }

    private func calculateAppointmentMetrics(start: Date, end: Date) -> AppointmentMetrics {
        // TODO: Implement actual calculation
        var metrics = AppointmentMetrics()
        metrics.totalAppointments = 350
        metrics.completedAppointments = 320
        metrics.cancelledAppointments = 25
        metrics.noShowAppointments = 5
        metrics.completionRate = 0.914
        metrics.cancellationRate = 0.071
        metrics.noShowRate = 0.014
        metrics.averageAppointmentsPerClient = 3.27
        metrics.appointmentsByDayOfWeek = [
            1: 15, // Sunday
            2: 45, // Monday
            3: 52, // Tuesday
            4: 58, // Wednesday
            5: 55, // Thursday
            6: 48, // Friday
            7: 12  // Saturday
        ]
        metrics.appointmentsByHourOfDay = [
            9: 25, 10: 35, 11: 30, 12: 15, 13: 20, 14: 40, 15: 45, 16: 42, 17: 38, 18: 30
        ]
        metrics.utilizationRate = 0.78
        return metrics
    }

    private func calculateTreatmentMetrics(start: Date, end: Date) -> TreatmentMetrics {
        // TODO: Implement actual calculation
        var metrics = TreatmentMetrics()
        metrics.totalTreatmentSessions = 320
        metrics.treatmentsByType = [
            "Therapeutic Massage": 180,
            "Deep Tissue": 85,
            "Sports Massage": 35,
            "Prenatal": 20
        ]
        metrics.averagePainReduction = 3.5
        metrics.clientSatisfactionScore = 4.7
        metrics.referralsMade = 8
        metrics.adverseEvents = 0
        return metrics
    }

    private func calculateOutcomeMetrics(start: Date, end: Date) -> OutcomeMetrics {
        // TODO: Implement actual calculation
        var metrics = OutcomeMetrics()
        metrics.totalOutcomeAssessments = 45
        metrics.clientsShowingImprovement = 38
        metrics.clientsShowingNoChange = 5
        metrics.clientsShowingDeclne = 2
        metrics.improvementRate = 0.844
        metrics.goalAttainmentRate = 0.78
        return metrics
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}
