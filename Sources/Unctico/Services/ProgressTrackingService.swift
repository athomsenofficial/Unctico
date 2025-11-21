import Foundation
import SwiftUI

/// Service for tracking client progress over time
/// Analyzes trends in pain levels, treatment response, and functional improvements
@MainActor
class ProgressTrackingService: ObservableObject {
    @Published var progressReports: [ProgressReport] = []

    private let soapNoteRepository: SOAPNoteRepository
    private let repository: ProgressReportRepository

    init(
        soapNoteRepository: SOAPNoteRepository = .shared,
        repository: ProgressReportRepository = .shared
    ) {
        self.soapNoteRepository = soapNoteRepository
        self.repository = repository
        loadData()
    }

    private func loadData() {
        self.progressReports = repository.getAllProgressReports()
    }

    // MARK: - Progress Report Generation

    /// Generate a comprehensive progress report for a client
    func generateProgressReport(
        for clientId: UUID,
        startDate: Date,
        endDate: Date = Date()
    ) -> ProgressReport {
        let notes = soapNoteRepository.getNotesForClient(clientId)
            .filter { $0.date >= startDate && $0.date <= endDate }
            .sorted { $0.date < $1.date }

        let metrics = calculateProgressMetrics(from: notes)
        let trends = analyzeTrends(from: notes)
        let recommendations = generateRecommendations(based: on: metrics, trends: trends)

        let report = ProgressReport(
            clientId: clientId,
            startDate: startDate,
            endDate: endDate,
            sessionCount: notes.count,
            metrics: metrics,
            trends: trends,
            recommendations: recommendations,
            generatedDate: Date()
        )

        repository.saveProgressReport(report)
        progressReports.append(report)

        return report
    }

    // MARK: - Metrics Calculation

    private func calculateProgressMetrics(from notes: [SOAPNote]) -> ProgressMetrics {
        guard !notes.isEmpty else {
            return ProgressMetrics()
        }

        // Pain levels
        let painLevels = notes.map { $0.subjective.painLevel }
        let initialPain = painLevels.first ?? 0
        let currentPain = painLevels.last ?? 0
        let averagePain = painLevels.reduce(0, +) / painLevels.count
        let painImprovement = initialPain - currentPain

        // Sleep quality
        let sleepQualities = notes.map { $0.subjective.sleepQuality }
        let initialSleep = sleepQualities.first?.numericValue ?? 0
        let currentSleep = sleepQualities.last?.numericValue ?? 0
        let sleepImprovement = currentSleep - initialSleep

        // Stress levels
        let stressLevels = notes.map { $0.subjective.stressLevel }
        let initialStress = stressLevels.first ?? 0
        let currentStress = stressLevels.last ?? 0
        let averageStress = stressLevels.reduce(0, +) / stressLevels.count
        let stressReduction = initialStress - currentStress

        // Treatment response
        let treatments = notes.map { $0.assessment.treatmentResponse }
        let improvingCount = treatments.filter { $0 == .improving }.count
        let responseRate = Double(improvingCount) / Double(treatments.count) * 100

        // Functional improvements
        let romAssessments = notes.flatMap { $0.objective.rangeOfMotion }
        let romImprovement = calculateROMImprovement(romAssessments)

        return ProgressMetrics(
            initialPainLevel: initialPain,
            currentPainLevel: currentPain,
            averagePainLevel: averagePain,
            painReduction: painImprovement,
            painReductionPercentage: initialPain > 0 ? Double(painImprovement) / Double(initialPain) * 100 : 0,
            sleepQualityImprovement: sleepImprovement,
            stressReduction: stressReduction,
            averageStressLevel: averageStress,
            treatmentResponseRate: responseRate,
            functionalImprovement: romImprovement,
            sessionAttendance: notes.count
        )
    }

    // MARK: - Trend Analysis

    private func analyzeTrends(from notes: [SOAPNote]) -> ProgressTrends {
        guard notes.count >= 2 else {
            return ProgressTrends()
        }

        // Pain trend
        let painTrend = calculateTrend(
            values: notes.map { Double($0.subjective.painLevel) }
        )

        // Stress trend
        let stressTrend = calculateTrend(
            values: notes.map { Double($0.subjective.stressLevel) }
        )

        // Sleep trend
        let sleepTrend = calculateTrend(
            values: notes.map { Double($0.subjective.sleepQuality.numericValue) }
        )

        // Muscle tension trend
        let tensionTrend = calculateMuscleTensionTrend(from: notes)

        // Treatment response progression
        let responseTrend = analyzeResponseProgression(from: notes)

        return ProgressTrends(
            painTrend: painTrend,
            stressTrend: stressTrend,
            sleepTrend: sleepTrend,
            muscleTensionTrend: tensionTrend,
            treatmentResponseTrend: responseTrend
        )
    }

    // MARK: - Recommendations

    private func generateRecommendations(
        based metrics: ProgressMetrics,
        trends: ProgressTrends
    ) -> [ProgressRecommendation] {
        var recommendations: [ProgressRecommendation] = []

        // Pain management
        if metrics.painReductionPercentage < 25 && metrics.sessionAttendance >= 4 {
            recommendations.append(
                ProgressRecommendation(
                    category: .treatment,
                    priority: .high,
                    title: "Limited Pain Improvement",
                    description: "Pain has improved by less than 25% after \(metrics.sessionAttendance) sessions. Consider: adjusting treatment approach, increasing session frequency, or consulting with physician.",
                    actionItems: [
                        "Review and modify treatment techniques",
                        "Consider additional modalities (heat, cupping, etc.)",
                        "Evaluate home care compliance",
                        "Physician consultation recommended"
                    ]
                )
            )
        } else if metrics.painReductionPercentage >= 50 {
            recommendations.append(
                ProgressRecommendation(
                    category: .treatment,
                    priority: .medium,
                    title: "Excellent Pain Reduction",
                    description: "Pain has improved by \(Int(metrics.painReductionPercentage))%. Consider transitioning to maintenance care.",
                    actionItems: [
                        "Discuss maintenance schedule with client",
                        "Focus on prevention strategies",
                        "Emphasize continued home care"
                    ]
                )
            )
        }

        // Sleep quality
        if metrics.sleepQualityImprovement < 0 {
            recommendations.append(
                ProgressRecommendation(
                    category: .lifestyle,
                    priority: .high,
                    title: "Sleep Quality Declining",
                    description: "Client's sleep quality has worsened. Poor sleep can impede recovery.",
                    actionItems: [
                        "Discuss sleep hygiene strategies",
                        "Consider evening massage sessions",
                        "Recommend relaxation techniques",
                        "Consider physician referral if severe"
                    ]
                )
            )
        }

        // Stress management
        if metrics.averageStressLevel >= 7 && trends.stressTrend != .improving {
            recommendations.append(
                ProgressRecommendation(
                    category: .lifestyle,
                    priority: .medium,
                    title: "Elevated Stress Levels",
                    description: "Client maintains high stress levels (\(metrics.averageStressLevel)/10). Stress can contribute to muscle tension.",
                    actionItems: [
                        "Incorporate stress-relief techniques in sessions",
                        "Recommend meditation or yoga",
                        "Consider referral to counselor or therapist",
                        "Discuss stress management strategies"
                    ]
                )
            )
        }

        // Treatment compliance
        if metrics.sessionAttendance < 4 && trends.painTrend != .improving {
            recommendations.append(
                ProgressRecommendation(
                    category: .compliance,
                    priority: .high,
                    title: "Insufficient Session Frequency",
                    description: "Only \(metrics.sessionAttendance) sessions completed. More frequent treatment may be needed for progress.",
                    actionItems: [
                        "Discuss treatment frequency with client",
                        "Address any barriers to attendance",
                        "Review treatment goals and expectations",
                        "Consider shorter, more frequent sessions"
                    ]
                )
            )
        }

        // Positive progress
        if trends.painTrend == .improving &&
           trends.sleepTrend == .improving &&
           trends.stressTrend == .improving {
            recommendations.append(
                ProgressRecommendation(
                    category: .treatment,
                    priority: .low,
                    title: "Excellent Overall Progress",
                    description: "Client showing improvement across all metrics. Continue current treatment approach.",
                    actionItems: [
                        "Maintain current treatment plan",
                        "Continue home care program",
                        "Plan for transition to maintenance",
                        "Celebrate progress with client"
                    ]
                )
            )
        }

        return recommendations
    }

    // MARK: - Helper Methods

    private func calculateTrend(values: [Double]) -> TrendDirection {
        guard values.count >= 2 else { return .stable }

        let firstHalf = values.prefix(values.count / 2)
        let secondHalf = values.suffix(values.count / 2)

        let firstAverage = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0, +) / Double(secondHalf.count)

        let difference = secondAverage - firstAverage

        if difference < -0.5 {
            return .improving
        } else if difference > 0.5 {
            return .worsening
        } else {
            return .stable
        }
    }

    private func calculateMuscleTensionTrend(from notes: [SOAPNote]) -> TrendDirection {
        let tensions = notes.flatMap { note in
            note.objective.muscleTension.map { Double($0.tensionLevel) }
        }

        return calculateTrend(values: tensions)
    }

    private func analyzeResponseProgression(from notes: [SOAPNote]) -> TrendDirection {
        let responses = notes.map { $0.assessment.treatmentResponse }
        let values = responses.map { response -> Double in
            switch response {
            case .declining: return 1.0
            case .stable: return 2.0
            case .improving: return 3.0
            case .resolved: return 4.0
            }
        }

        return calculateTrend(values: values)
    }

    private func calculateROMImprovement(_ assessments: [Objective.ROMAssessment]) -> Double {
        // Simplified: count how many have no limitations
        let withoutLimitations = assessments.filter { $0.limitations == nil }.count
        return assessments.isEmpty ? 0 : Double(withoutLimitations) / Double(assessments.count) * 100
    }

    // MARK: - Data Access

    func getProgressReportsForClient(_ clientId: UUID) -> [ProgressReport] {
        progressReports.filter { $0.clientId == clientId }
            .sorted { $0.generatedDate > $1.generatedDate }
    }

    func getLatestProgressReport(for clientId: UUID) -> ProgressReport? {
        getProgressReportsForClient(clientId).first
    }

    func deleteProgressReport(id: UUID) {
        repository.deleteProgressReport(id: id)
        progressReports.removeAll { $0.id == id }
    }
}

// MARK: - Supporting Models

struct ProgressReport: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    let startDate: Date
    let endDate: Date
    let sessionCount: Int
    let metrics: ProgressMetrics
    let trends: ProgressTrends
    let recommendations: [ProgressRecommendation]
    let generatedDate: Date

    init(
        id: UUID = UUID(),
        clientId: UUID,
        startDate: Date,
        endDate: Date,
        sessionCount: Int,
        metrics: ProgressMetrics,
        trends: ProgressTrends,
        recommendations: [ProgressRecommendation],
        generatedDate: Date
    ) {
        self.id = id
        self.clientId = clientId
        self.startDate = startDate
        self.endDate = endDate
        self.sessionCount = sessionCount
        self.metrics = metrics
        self.trends = trends
        self.recommendations = recommendations
        self.generatedDate = generatedDate
    }
}

struct ProgressMetrics: Codable {
    let initialPainLevel: Int
    let currentPainLevel: Int
    let averagePainLevel: Int
    let painReduction: Int
    let painReductionPercentage: Double
    let sleepQualityImprovement: Int
    let stressReduction: Int
    let averageStressLevel: Int
    let treatmentResponseRate: Double
    let functionalImprovement: Double
    let sessionAttendance: Int

    init(
        initialPainLevel: Int = 0,
        currentPainLevel: Int = 0,
        averagePainLevel: Int = 0,
        painReduction: Int = 0,
        painReductionPercentage: Double = 0,
        sleepQualityImprovement: Int = 0,
        stressReduction: Int = 0,
        averageStressLevel: Int = 0,
        treatmentResponseRate: Double = 0,
        functionalImprovement: Double = 0,
        sessionAttendance: Int = 0
    ) {
        self.initialPainLevel = initialPainLevel
        self.currentPainLevel = currentPainLevel
        self.averagePainLevel = averagePainLevel
        self.painReduction = painReduction
        self.painReductionPercentage = painReductionPercentage
        self.sleepQualityImprovement = sleepQualityImprovement
        self.stressReduction = stressReduction
        self.averageStressLevel = averageStressLevel
        self.treatmentResponseRate = treatmentResponseRate
        self.functionalImprovement = functionalImprovement
        self.sessionAttendance = sessionAttendance
    }
}

struct ProgressTrends: Codable {
    let painTrend: TrendDirection
    let stressTrend: TrendDirection
    let sleepTrend: TrendDirection
    let muscleTensionTrend: TrendDirection
    let treatmentResponseTrend: TrendDirection

    init(
        painTrend: TrendDirection = .stable,
        stressTrend: TrendDirection = .stable,
        sleepTrend: TrendDirection = .stable,
        muscleTensionTrend: TrendDirection = .stable,
        treatmentResponseTrend: TrendDirection = .stable
    ) {
        self.painTrend = painTrend
        self.stressTrend = stressTrend
        self.sleepTrend = sleepTrend
        self.muscleTensionTrend = muscleTensionTrend
        self.treatmentResponseTrend = treatmentResponseTrend
    }
}

enum TrendDirection: String, Codable {
    case improving = "Improving"
    case stable = "Stable"
    case worsening = "Worsening"

    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .blue
        case .worsening: return .red
        }
    }

    var icon: String {
        switch self {
        case .improving: return "arrow.down.right"
        case .stable: return "arrow.right"
        case .worsening: return "arrow.up.right"
        }
    }
}

struct ProgressRecommendation: Identifiable, Codable {
    let id: UUID
    let category: Category
    let priority: Priority
    let title: String
    let description: String
    let actionItems: [String]

    init(
        id: UUID = UUID(),
        category: Category,
        priority: Priority,
        title: String,
        description: String,
        actionItems: [String]
    ) {
        self.id = id
        self.category = category
        self.priority = priority
        self.title = title
        self.description = description
        self.actionItems = actionItems
    }

    enum Category: String, Codable {
        case treatment = "Treatment"
        case lifestyle = "Lifestyle"
        case compliance = "Compliance"
        case referral = "Referral"
    }

    enum Priority: String, Codable {
        case high = "High"
        case medium = "Medium"
        case low = "Low"

        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }
    }
}

// MARK: - Repository

class ProgressReportRepository {
    static let shared = ProgressReportRepository()

    private let key = "progress_reports"

    private init() {}

    func getAllProgressReports() -> [ProgressReport] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let reports = try? JSONDecoder().decode([ProgressReport].self, from: data) else {
            return []
        }
        return reports
    }

    func saveProgressReport(_ report: ProgressReport) {
        var all = getAllProgressReports()
        all.append(report)
        save(reports: all)
    }

    func deleteProgressReport(id: UUID) {
        var all = getAllProgressReports()
        all.removeAll { $0.id == id }
        save(reports: all)
    }

    private func save(reports: [ProgressReport]) {
        if let data = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Extensions

extension Subjective.SleepQuality {
    var numericValue: Int {
        switch self {
        case .poor: return 1
        case .fair: return 2
        case .good: return 3
        case .excellent: return 4
        }
    }
}
