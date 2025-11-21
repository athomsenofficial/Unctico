import Foundation
import SwiftUI
import Combine

/// Service for tracking massage session time and auto-documenting treatment details
@MainActor
class SessionTimerService: ObservableObject {
    @Published var isRunning = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentSegment: TreatmentSegment?
    @Published var completedSegments: [TreatmentSegment] = []
    @Published var notes: [TimestampedNote] = []

    private var timer: Timer?
    private var sessionStartTime: Date?
    private var segmentStartTime: Date?

    // MARK: - Session Control

    func startSession() {
        guard !isRunning else { return }

        isRunning = true
        sessionStartTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsedTime()
            }
        }
    }

    func pauseSession() {
        isRunning = false
        timer?.invalidate()
        timer = nil

        if currentSegment != nil {
            endCurrentSegment()
        }
    }

    func resumeSession() {
        guard !isRunning else { return }
        startSession()
    }

    func endSession() -> SessionSummary {
        pauseSession()

        let summary = SessionSummary(
            totalDuration: elapsedTime,
            segments: completedSegments,
            notes: notes,
            startTime: sessionStartTime ?? Date(),
            endTime: Date()
        )

        // Reset for next session
        reset()

        return summary
    }

    private func reset() {
        elapsedTime = 0
        currentSegment = nil
        completedSegments = []
        notes = []
        sessionStartTime = nil
        segmentStartTime = nil
    }

    private func updateElapsedTime() {
        guard let startTime = sessionStartTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime)

        // Update current segment duration
        if let segment = currentSegment, let segmentStart = segmentStartTime {
            let segmentDuration = Date().timeIntervalSince(segmentStart)
            currentSegment = TreatmentSegment(
                id: segment.id,
                bodyArea: segment.bodyArea,
                technique: segment.technique,
                pressure: segment.pressure,
                duration: segmentDuration,
                startTime: segment.startTime,
                notes: segment.notes
            )
        }
    }

    // MARK: - Segment Management

    func startSegment(
        bodyArea: BodyLocation,
        technique: MassageTechnique,
        pressure: PressureLevel
    ) {
        // End current segment if exists
        if currentSegment != nil {
            endCurrentSegment()
        }

        segmentStartTime = Date()
        currentSegment = TreatmentSegment(
            bodyArea: bodyArea,
            technique: technique,
            pressure: pressure,
            duration: 0,
            startTime: segmentStartTime ?? Date(),
            notes: ""
        )
    }

    func endCurrentSegment() {
        guard var segment = currentSegment else { return }

        // Calculate final duration
        if let segmentStart = segmentStartTime {
            segment.duration = Date().timeIntervalSince(segmentStart)
        }

        completedSegments.append(segment)
        currentSegment = nil
        segmentStartTime = nil
    }

    func addNoteToCurrentSegment(_ note: String) {
        guard var segment = currentSegment else { return }
        segment.notes = note
        currentSegment = segment
    }

    // MARK: - Notes

    func addNote(_ text: String, timestamp: Date = Date()) {
        let note = TimestampedNote(
            text: text,
            timestamp: timestamp,
            elapsedTime: elapsedTime
        )
        notes.append(note)
    }

    // MARK: - Statistics

    func getSegmentStatistics() -> SegmentStatistics {
        let totalTime = completedSegments.reduce(0) { $0 + $1.duration }

        let byArea = Dictionary(grouping: completedSegments) { $0.bodyArea }
            .mapValues { segments in
                segments.reduce(0) { $0 + $1.duration }
            }

        let byTechnique = Dictionary(grouping: completedSegments) { $0.technique }
            .mapValues { segments in
                segments.reduce(0) { $0 + $1.duration }
            }

        let byPressure = Dictionary(grouping: completedSegments) { $0.pressure }
            .mapValues { segments in
                segments.reduce(0) { $0 + $1.duration }
            }

        return SegmentStatistics(
            totalTime: totalTime,
            segmentCount: completedSegments.count,
            timeByArea: byArea,
            timeByTechnique: byTechnique,
            timeByPressure: byPressure
        )
    }
}

// MARK: - Supporting Models

struct TreatmentSegment: Identifiable, Codable {
    let id: UUID
    let bodyArea: BodyLocation
    let technique: MassageTechnique
    let pressure: PressureLevel
    var duration: TimeInterval
    let startTime: Date
    var notes: String

    init(
        id: UUID = UUID(),
        bodyArea: BodyLocation,
        technique: MassageTechnique,
        pressure: PressureLevel,
        duration: TimeInterval,
        startTime: Date,
        notes: String = ""
    ) {
        self.id = id
        self.bodyArea = bodyArea
        self.technique = technique
        self.pressure = pressure
        self.duration = duration
        self.startTime = startTime
        self.notes = notes
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

enum MassageTechnique: String, Codable, CaseIterable {
    case swedish = "Swedish"
    case deepTissue = "Deep Tissue"
    case triggerPoint = "Trigger Point Therapy"
    case myofascialRelease = "Myofascial Release"
    case stretchingAndROM = "Stretching & ROM"
    case cupping = "Cupping"
    case hotStone = "Hot Stone"
    case sports = "Sports Massage"
    case prenatal = "Prenatal"
    case reflexology = "Reflexology"
    case lymphatic = "Lymphatic Drainage"
    case shiatsu = "Shiatsu"

    var icon: String {
        switch self {
        case .swedish: return "hand.raised.fill"
        case .deepTissue: return "flame.fill"
        case .triggerPoint: return "circle.fill"
        case .myofascialRelease: return "waveform"
        case .stretchingAndROM: return "arrow.up.and.down.and.arrow.left.and.right"
        case .cupping: return "circle.circle"
        case .hotStone: return "flame.circle.fill"
        case .sports: return "figure.run"
        case .prenatal: return "figure.walk"
        case .reflexology: return "hand.thumbsup.fill"
        case .lymphatic: return "drop.fill"
        case .shiatsu: return "hand.point.up.left.fill"
        }
    }
}

enum PressureLevel: String, Codable, CaseIterable {
    case light = "Light"
    case lightToModerate = "Light to Moderate"
    case moderate = "Moderate"
    case moderateToFirm = "Moderate to Firm"
    case firm = "Firm"
    case veryFirm = "Very Firm"

    var color: Color {
        switch self {
        case .light: return .green
        case .lightToModerate: return .blue
        case .moderate: return .cyan
        case .moderateToFirm: return .orange
        case .firm: return .red
        case .veryFirm: return .purple
        }
    }

    var numericValue: Int {
        switch self {
        case .light: return 1
        case .lightToModerate: return 2
        case .moderate: return 3
        case .moderateToFirm: return 4
        case .firm: return 5
        case .veryFirm: return 6
        }
    }
}

struct TimestampedNote: Identifiable, Codable {
    let id: UUID
    let text: String
    let timestamp: Date
    let elapsedTime: TimeInterval

    init(
        id: UUID = UUID(),
        text: String,
        timestamp: Date,
        elapsedTime: TimeInterval
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.elapsedTime = elapsedTime
    }

    var formattedTimestamp: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct SessionSummary: Codable {
    let totalDuration: TimeInterval
    let segments: [TreatmentSegment]
    let notes: [TimestampedNote]
    let startTime: Date
    let endTime: Date

    var formattedDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = Int(totalDuration) / 60 % 60
        let seconds = Int(totalDuration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Generate SOAP note objective section from session
    func generateObjectiveFindings() -> String {
        var findings: [String] = []

        // Areas worked
        let areas = segments.map { $0.bodyArea.rawValue }
        let uniqueAreas = Set(areas).sorted()
        findings.append("Areas worked: \(uniqueAreas.joined(separator: ", "))")

        // Techniques used
        let techniques = segments.map { $0.technique.rawValue }
        let uniqueTechniques = Set(techniques).sorted()
        findings.append("Techniques: \(uniqueTechniques.joined(separator: ", "))")

        // Pressure levels
        let pressures = segments.map { $0.pressure.rawValue }
        let uniquePressures = Set(pressures).sorted()
        findings.append("Pressure: \(uniquePressures.joined(separator: ", "))")

        // Time distribution
        let areaTime = Dictionary(grouping: segments) { $0.bodyArea }
            .mapValues { segments in
                segments.reduce(0) { $0 + $1.duration }
            }
            .sorted { $0.value > $1.value }

        if !areaTime.isEmpty {
            findings.append("\nTime distribution:")
            for (area, duration) in areaTime.prefix(5) {
                let minutes = Int(duration) / 60
                findings.append("- \(area.rawValue): \(minutes) min")
            }
        }

        // Notes
        if !notes.isEmpty {
            findings.append("\nSession notes:")
            for note in notes {
                findings.append("- [\(note.formattedTimestamp)] \(note.text)")
            }
        }

        return findings.joined(separator: "\n")
    }
}

struct SegmentStatistics {
    let totalTime: TimeInterval
    let segmentCount: Int
    let timeByArea: [BodyLocation: TimeInterval]
    let timeByTechnique: [MassageTechnique: TimeInterval]
    let timeByPressure: [PressureLevel: TimeInterval]

    func formattedTime(for area: BodyLocation) -> String {
        guard let time = timeByArea[area] else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func percentage(for area: BodyLocation) -> Double {
        guard let time = timeByArea[area], totalTime > 0 else { return 0 }
        return (time / totalTime) * 100
    }
}
