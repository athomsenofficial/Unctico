// SOAPNoteDetailView.swift
// Detailed view of a SOAP note
// QA Note: Shows complete clinical documentation for a session

import SwiftUI

struct SOAPNoteDetailView: View {

    // MARK: - Properties

    let note: SOAPNote

    // MARK: - Environment

    @EnvironmentObject var dataManager: DataManager

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Header Section
                headerSection

                // Subjective Section
                soapSection(
                    title: "Subjective",
                    subtitle: "What the client reports",
                    color: .blue
                ) {
                    subjectiveContent
                }

                // Objective Section
                soapSection(
                    title: "Objective",
                    subtitle: "What you observed",
                    color: .green
                ) {
                    objectiveContent
                }

                // Assessment Section
                soapSection(
                    title: "Assessment",
                    subtitle: "Your professional judgment",
                    color: .orange
                ) {
                    assessmentContent
                }

                // Plan Section
                soapSection(
                    title: "Plan",
                    subtitle: "Treatment plan and recommendations",
                    color: .purple
                ) {
                    planContent
                }
            }
            .padding()
        }
        .navigationTitle("SOAP Note")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Client name
            if let client = dataManager.getClient(id: note.clientId) {
                Text(client.fullName)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            // Date and time
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text(note.createdDate, formatter: DateFormatter.fullDateTime)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)

            // Session duration
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("\(note.sessionDuration) minutes")
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)

            // Therapist
            if let therapist = dataManager.getTherapist(id: note.therapistId) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.secondary)
                    Text(therapist.fullName)
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - SOAP Section Builder

    @ViewBuilder
    private func soapSection<Content: View>(
        title: String,
        subtitle: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .background(color)

            // Section content
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3)
    }

    // MARK: - Subjective Content

    private var subjectiveContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Chief complaint
            if !note.subjective.chiefComplaint.isEmpty {
                InfoSection(title: "Chief Complaint", icon: "exclamationmark.bubble") {
                    Text(note.subjective.chiefComplaint)
                }
            }

            // Pain level
            if note.subjective.painLevel > 0 {
                InfoSection(title: "Pain Level", icon: "bolt.fill") {
                    HStack {
                        Text("\(note.subjective.painLevel)/10")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(painColor(note.subjective.painLevel))

                        Spacer()

                        // Pain bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(painColor(note.subjective.painLevel))
                                    .frame(width: geometry.size.width * CGFloat(note.subjective.painLevel) / 10, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }

            // Stress level
            if note.subjective.stressLevel > 0 {
                InfoSection(title: "Stress Level", icon: "brain") {
                    Text("\(note.subjective.stressLevel)/10")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }

            // Pain locations
            if !note.subjective.painLocations.isEmpty {
                InfoSection(title: "Pain Locations", icon: "mappin.and.ellipse") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(note.subjective.painLocations) { location in
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                Text("\(location.area.rawValue) (\(location.side.rawValue))")
                            }
                        }
                    }
                }
            }

            // Sleep quality
            InfoSection(title: "Sleep Quality", icon: "moon.fill") {
                Text(note.subjective.sleepQuality.rawValue)
            }

            // Voice notes
            if !note.subjective.voiceNotes.isEmpty {
                InfoSection(title: "Voice Transcription", icon: "waveform") {
                    Text(note.subjective.voiceNotes)
                        .italic()
                }
            }

            // Goals
            if !note.subjective.goals.isEmpty {
                InfoSection(title: "Client Goals", icon: "target") {
                    Text(note.subjective.goals)
                }
            }
        }
    }

    // MARK: - Objective Content

    private var objectiveContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Observations
            if !note.objective.observations.isEmpty {
                InfoSection(title: "Observations", icon: "eye") {
                    Text(note.objective.observations)
                }
            }

            // Posture
            if !note.objective.posture.isEmpty {
                InfoSection(title: "Posture", icon: "figure.stand") {
                    Text(note.objective.posture)
                }
            }

            // Muscle tension
            if !note.objective.muscleTension.isEmpty {
                InfoSection(title: "Muscle Tension", icon: "fiberchannel") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(note.objective.muscleTension) { tension in
                            HStack {
                                Text(tension.muscle)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("Grade \(tension.grade.rawValue)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(tensionColor(tension.grade).opacity(0.2))
                                    .foregroundColor(tensionColor(tension.grade))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }

            // Trigger points
            if !note.objective.triggerPoints.isEmpty {
                InfoSection(title: "Trigger Points", icon: "target") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(note.objective.triggerPoints) { point in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(point.muscle)
                                    .fontWeight(.medium)
                                if !point.referralPattern.isEmpty {
                                    Text("Refers to: \(point.referralPattern)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            // ROM tests
            if !note.objective.rangeOfMotion.isEmpty {
                InfoSection(title: "Range of Motion", icon: "arrow.triangle.2.circlepath") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(note.objective.rangeOfMotion) { rom in
                            HStack {
                                Text("\(rom.joint) - \(rom.movement)")
                                Spacer()
                                Text(rom.limitation.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Assessment Content

    private var assessmentContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Clinical reasoning
            if !note.assessment.clinicalReasoning.isEmpty {
                InfoSection(title: "Clinical Reasoning", icon: "brain") {
                    Text(note.assessment.clinicalReasoning)
                }
            }

            // Diagnosis
            if !note.assessment.diagnosis.isEmpty {
                InfoSection(title: "Diagnosis", icon: "stethoscope") {
                    Text(note.assessment.diagnosis)
                }
            }

            // Progress
            InfoSection(title: "Progress", icon: "chart.line.uptrend.xyaxis") {
                Text(note.assessment.progress.rawValue)
                    .fontWeight(.medium)
                    .foregroundColor(progressColor(note.assessment.progress))
            }

            // Red flags
            if !note.assessment.redFlags.isEmpty {
                InfoSection(title: "Red Flags", icon: "exclamationmark.triangle.fill") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(note.assessment.redFlags, id: \.self) { flag in
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(flag)
                            }
                        }
                    }
                }
            }

            // Contraindications
            if !note.assessment.contraindications.isEmpty {
                InfoSection(title: "Contraindications", icon: "hand.raised.fill") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(note.assessment.contraindications, id: \.self) { contra in
                            HStack {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 6, height: 6)
                                Text(contra)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Plan Content

    private var planContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Treatment plan
            if !note.plan.treatmentPlan.isEmpty {
                InfoSection(title: "Treatment Plan", icon: "list.clipboard") {
                    Text(note.plan.treatmentPlan)
                }
            }

            // Frequency
            if !note.plan.frequency.isEmpty {
                InfoSection(title: "Recommended Frequency", icon: "calendar.badge.clock") {
                    Text(note.plan.frequency)
                }
            }

            // Homecare
            if !note.plan.homecare.isEmpty {
                InfoSection(title: "Home Care Instructions", icon: "house.fill") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(note.plan.homecare) { instruction in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(instruction.type.rawValue)
                                    .fontWeight(.semibold)
                                Text(instruction.description)
                                    .font(.subheadline)
                                Text("\(instruction.frequency) - \(instruction.duration)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.bottom, 4)
                        }
                    }
                }
            }

            // Referrals
            if !note.plan.referrals.isEmpty {
                InfoSection(title: "Referrals", icon: "arrow.turn.up.right") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(note.plan.referrals) { referral in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(referral.providerType)
                                        .fontWeight(.medium)
                                    Text(referral.reason)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if referral.urgent {
                                    Text("URGENT")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }

            // Follow-up date
            if let followUpDate = note.plan.followUpDate {
                InfoSection(title: "Follow-Up", icon: "calendar.badge.clock") {
                    Text(followUpDate, formatter: DateFormatter.mediumDate)
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Get color for pain level
    private func painColor(_ level: Int) -> Color {
        switch level {
        case 0...3:
            return .green
        case 4...6:
            return .yellow
        case 7...8:
            return .orange
        case 9...10:
            return .red
        default:
            return .gray
        }
    }

    /// Get color for muscle tension
    private func tensionColor(_ grade: TensionGrade) -> Color {
        switch grade.rawValue {
        case 1...2:
            return .green
        case 3:
            return .yellow
        case 4:
            return .orange
        case 5:
            return .red
        default:
            return .gray
        }
    }

    /// Get color for progress level
    private func progressColor(_ progress: ProgressLevel) -> Color {
        switch progress {
        case .worsened:
            return .red
        case .noChange:
            return .orange
        case .slightImprovement:
            return .yellow
        case .goodImprovement:
            return .green
        case .significantImprovement, .resolved:
            return .blue
        }
    }
}

// MARK: - Info Section Component

struct InfoSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            content()
        }
    }
}

// MARK: - Preview

struct SOAPNoteDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SOAPNoteDetailView(
                note: SOAPNote(
                    clientId: UUID(),
                    sessionId: UUID(),
                    therapistId: UUID()
                )
            )
        }
        .environmentObject(DataManager())
    }
}
