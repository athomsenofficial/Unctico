import SwiftUI

/// Advanced SOAP notes components - Red flag alerts, photo capture, ROM, treatment plans, etc.

// MARK: - Red Flag Symptom Alert System (CRITICAL SAFETY)
struct RedFlagAlertView: View {
    let redFlags: [RedFlagSymptom]
    @State private var showingDetailAlert = false

    var body: some View {
        if !redFlags.isEmpty {
            VStack(spacing: 12) {
                Button(action: { showingDetailAlert = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .font(.title2)
                            .foregroundColor(.red)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("⚠️ RED FLAG SYMPTOMS DETECTED")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.red)

                            Text("\(redFlags.count) serious symptom\(redFlags.count > 1 ? "s" : "") requiring immediate attention")
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 3)
                    )
                }
                .buttonStyle(.plain)
            }
            .alert("🚨 RED FLAG SYMPTOMS", isPresented: $showingDetailAlert) {
                Button("Understood", role: .cancel) {}
                Button("Refer to MD", role: .destructive) {
                    // TODO: Create referral
                }
            } message: {
                Text(redFlags.map { "• \($0.symptom): \($0.reason)" }.joined(separator: "\n\n"))
            }
        }
    }
}

struct RedFlagSymptom: Identifiable {
    let id = UUID()
    let symptom: String
    let reason: String
    let severity: RedFlagSeverity
    let recommendedAction: String

    enum RedFlagSeverity: String {
        case emergency = "Call 911"
        case urgent = "Refer to MD Today"
        case serious = "Refer to MD This Week"
    }
}

/// Red flag detection engine
class RedFlagDetector {
    static func detectRedFlags(subjective: Subjective, objective: Objective) -> [RedFlagSymptom] {
        var flags: [RedFlagSymptom] = []

        // Check for emergency symptoms
        if subjective.chiefComplaint.localizedCaseInsensitiveContains("chest pain") ||
           subjective.chiefComplaint.localizedCaseInsensitiveContains("difficulty breathing") {
            flags.append(RedFlagSymptom(
                symptom: "Chest Pain / Difficulty Breathing",
                reason: "Possible cardiac or pulmonary emergency",
                severity: .emergency,
                recommendedAction: "Call 911 immediately"
            ))
        }

        // Severe headache with vision changes
        if subjective.chiefComplaint.localizedCaseInsensitiveContains("severe headache") &&
           subjective.chiefComplaint.localizedCaseInsensitiveContains("vision") {
            flags.append(RedFlagSymptom(
                symptom: "Severe Headache with Vision Changes",
                reason: "Possible stroke, aneurysm, or neurological emergency",
                severity: .emergency,
                recommendedAction: "Refer to emergency care immediately"
            ))
        }

        // Sudden severe pain
        if subjective.painLevel >= 9 && subjective.symptomDuration.localizedCaseInsensitiveContains("sudden") {
            flags.append(RedFlagSymptom(
                symptom: "Sudden Severe Pain (9-10/10)",
                reason: "Possible acute injury, fracture, or medical emergency",
                severity: .urgent,
                recommendedAction: "Refer to physician today"
            ))
        }

        // Fever with pain
        if subjective.chiefComplaint.localizedCaseInsensitiveContains("fever") {
            flags.append(RedFlagSymptom(
                symptom: "Fever with Pain",
                reason: "Possible infection or systemic illness",
                severity: .urgent,
                recommendedAction: "Refer to physician - contraindication for massage"
            ))
        }

        // Numbness/tingling with weakness
        if (subjective.chiefComplaint.localizedCaseInsensitiveContains("numbness") ||
            subjective.chiefComplaint.localizedCaseInsensitiveContains("tingling")) &&
           subjective.chiefComplaint.localizedCaseInsensitiveContains("weak") {
            flags.append(RedFlagSymptom(
                symptom: "Numbness/Tingling with Weakness",
                reason: "Possible nerve compression or neurological issue",
                severity: .urgent,
                recommendedAction: "Refer to physician for neurological evaluation"
            ))
        }

        // Unexplained weight loss with pain
        if subjective.chiefComplaint.localizedCaseInsensitiveContains("weight loss") {
            flags.append(RedFlagSymptom(
                symptom: "Unexplained Weight Loss",
                reason: "Possible systemic disease or cancer",
                severity: .serious,
                recommendedAction: "Refer to physician for evaluation"
            ))
        }

        // Night pain that wakes client
        if subjective.chiefComplaint.localizedCaseInsensitiveContains("night") &&
           subjective.chiefComplaint.localizedCaseInsensitiveContains("wake") {
            flags.append(RedFlagSymptom(
                symptom: "Night Pain (Wakes from Sleep)",
                reason: "Possible serious pathology - not typical musculoskeletal pain",
                severity: .serious,
                recommendedAction: "Refer to physician for evaluation"
            ))
        }

        // Bowel/bladder changes with back pain
        if subjective.chiefComplaint.localizedCaseInsensitiveContains("bladder") ||
           subjective.chiefComplaint.localizedCaseInsensitiveContains("bowel") {
            flags.append(RedFlagSymptom(
                symptom: "Bowel/Bladder Changes with Pain",
                reason: "Possible cauda equina syndrome - surgical emergency",
                severity: .emergency,
                recommendedAction: "Refer to emergency care immediately"
            ))
        }

        // Unrelenting pain (no relief with rest/position change)
        if subjective.chiefComplaint.localizedCaseInsensitiveContains("constant") &&
           subjective.chiefComplaint.localizedCaseInsensitiveContains("no relief") {
            flags.append(RedFlagSymptom(
                symptom: "Unrelenting Constant Pain",
                reason: "Atypical for musculoskeletal pain - possible serious pathology",
                severity: .serious,
                recommendedAction: "Refer to physician for evaluation"
            ))
        }

        // Recent trauma with severe pain
        if subjective.chiefComplaint.localizedCaseInsensitiveContains("fell") ||
           subjective.chiefComplaint.localizedCaseInsensitiveContains("accident") ||
           subjective.chiefComplaint.localizedCaseInsensitiveContains("hit") {
            if subjective.painLevel >= 7 {
                flags.append(RedFlagSymptom(
                    symptom: "Recent Trauma with Severe Pain",
                    reason: "Possible fracture or internal injury",
                    severity: .urgent,
                    recommendedAction: "Refer to physician for imaging"
                ))
            }
        }

        return flags
    }
}

// MARK: - Photo Capture & Comparison System
struct PhotoCaptureView: View {
    @Binding var beforePhoto: UIImage?
    @Binding var afterPhoto: UIImage?
    @State private var showingImagePicker = false
    @State private var photoType: PhotoType = .before

    enum PhotoType {
        case before, after
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Before & After Photos")
                .font(.headline)

            HStack(spacing: 16) {
                // Before Photo
                VStack(spacing: 8) {
                    Text("Before")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let before = beforePhoto {
                        Image(uiImage: before)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.tranquilTeal, lineWidth: 2)
                            )
                    } else {
                        Button(action: {
                            photoType = .before
                            showingImagePicker = true
                        }) {
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.title)
                                Text("Add Photo")
                                    .font(.caption)
                            }
                            .frame(width: 150, height: 150)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }

                // After Photo
                VStack(spacing: 8) {
                    Text("After")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let after = afterPhoto {
                        Image(uiImage: after)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.green, lineWidth: 2)
                            )
                    } else {
                        Button(action: {
                            photoType = .after
                            showingImagePicker = true
                        }) {
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.title)
                                Text("Add Photo")
                                    .font(.caption)
                            }
                            .frame(width: 150, height: 150)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
            }

            // Comparison View
            if beforePhoto != nil && afterPhoto != nil {
                Button(action: {
                    // Show side-by-side comparison
                }) {
                    HStack {
                        Image(systemName: "arrow.left.and.right.square")
                        Text("View Comparison")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.tranquilTeal.opacity(0.1))
                    .foregroundColor(.tranquilTeal)
                    .cornerRadius(10)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: photoType == .before ? $beforePhoto : $afterPhoto)
        }
    }
}

// Simple Image Picker wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
    }
}

// MARK: - Range of Motion Measurement Tool
struct ROMAssessmentView: View {
    @Binding var assessments: [DetailedROMAssessment]
    @State private var showingAddROM = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Range of Motion Assessment")
                    .font(.headline)

                Spacer()

                Button(action: { showingAddROM = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.tranquilTeal)
                }
            }

            if assessments.isEmpty {
                Text("No ROM assessments recorded")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            } else {
                ForEach(assessments) { assessment in
                    ROMCard(assessment: assessment)
                }
            }
        }
        .sheet(isPresented: $showingAddROM) {
            AddROMView(assessments: $assessments)
        }
    }
}

struct ROMCard: View {
    let assessment: DetailedROMAssessment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundColor(.tranquilTeal)

                Text("\(assessment.joint.rawValue) - \(assessment.movement.rawValue)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(assessment.degrees)°")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.tranquilTeal)
            }

            if assessment.painDuring {
                Label("Pain during movement", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if !assessment.limitations.isEmpty {
                Text(assessment.limitations)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("End Feel:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(assessment.endFeel.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct AddROMView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var assessments: [DetailedROMAssessment]

    @State private var joint: Joint = .shoulder
    @State private var movement: Movement = .flexion
    @State private var degrees: Int = 90
    @State private var painDuring = false
    @State private var endFeel: EndFeel = .normal
    @State private var limitations = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Joint & Movement") {
                    Picker("Joint", selection: $joint) {
                        ForEach(Joint.allCases, id: \.self) { j in
                            Text(j.rawValue).tag(j)
                        }
                    }

                    Picker("Movement", selection: $movement) {
                        Text("Flexion").tag(Movement.flexion)
                        Text("Extension").tag(Movement.extension)
                        Text("Abduction").tag(Movement.abduction)
                        Text("Adduction").tag(Movement.adduction)
                        Text("Rotation").tag(Movement.rotation)
                        Text("Lateral Flexion").tag(Movement.lateralFlexion)
                    }
                }

                Section("Measurement") {
                    HStack {
                        Text("Degrees:")
                        Spacer()
                        Text("\(degrees)°")
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    Slider(value: Binding(
                        get: { Double(degrees) },
                        set: { degrees = Int($0) }
                    ), in: 0...180, step: 5)

                    Toggle("Pain During Movement", isOn: $painDuring)

                    Picker("End Feel", selection: $endFeel) {
                        Text("Normal/Soft").tag(EndFeel.normal)
                        Text("Firm").tag(EndFeel.firm)
                        Text("Hard/Bony").tag(EndFeel.hard)
                        Text("Springy").tag(EndFeel.springy)
                        Text("Empty (Pain Stops)").tag(EndFeel.empty)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $limitations)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add ROM Assessment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newAssessment = DetailedROMAssessment(
                            joint: joint,
                            movement: movement,
                            degrees: degrees,
                            painDuring: painDuring,
                            endFeel: endFeel,
                            limitations: limitations,
                            comparedToNormal: ""
                        )
                        assessments.append(newAssessment)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Treatment Plan Generator
struct TreatmentPlanGeneratorView: View {
    let subjective: Subjective
    let objective: Objective
    let assessment: Assessment
    @Binding var plan: Plan

    @State private var showingGenerator = false

    var body: some View {
        VStack(spacing: 16) {
            Button(action: { showingGenerator = true }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .font(.title3)

                    VStack(alignment: .leading) {
                        Text("Generate Treatment Plan")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text("AI-powered recommendations based on assessment")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color.tranquilTeal.opacity(0.1))
                .foregroundColor(.tranquilTeal)
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showingGenerator) {
            TreatmentPlanGeneratorSheet(
                subjective: subjective,
                objective: objective,
                assessment: assessment,
                plan: $plan
            )
        }
    }
}

struct TreatmentPlanGeneratorSheet: View {
    @Environment(\.dismiss) var dismiss
    let subjective: Subjective
    let objective: Objective
    let assessment: Assessment
    @Binding var plan: Plan

    @State private var generatedPlan: GeneratedTreatmentPlan?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let generated = generatedPlan {
                        // Recommended Frequency
                        SectionCard(title: "Recommended Frequency", icon: "calendar") {
                            Text(generated.frequency)
                                .font(.subheadline)
                        }

                        // Recommended Techniques
                        SectionCard(title: "Recommended Techniques", icon: "hand.raised.fill") {
                            ForEach(generated.techniques, id: \.self) { technique in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(technique)
                                        .font(.subheadline)
                                }
                            }
                        }

                        // Home Care Exercises
                        SectionCard(title: "Home Care Exercises", icon: "figure.flexibility") {
                            ForEach(generated.exercises, id: \.self) { exercise in
                                Text("• \(exercise)")
                                    .font(.subheadline)
                            }
                        }

                        // Self-Care Instructions
                        SectionCard(title: "Self-Care Instructions", icon: "heart.text.square") {
                            ForEach(generated.selfCare, id: \.self) { instruction in
                                Text("• \(instruction)")
                                    .font(.subheadline)
                            }
                        }

                        // Apply Button
                        Button(action: applyGeneratedPlan) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Apply This Plan")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.tranquilTeal)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    } else {
                        ProgressView("Generating treatment plan...")
                            .frame(maxWidth: .infinity)
                            .padding(40)
                    }
                }
                .padding()
            }
            .navigationTitle("Treatment Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                generatePlan()
            }
        }
    }

    private func generatePlan() {
        // Simulate AI generation (in real app, this would call an AI service)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            generatedPlan = TreatmentPlanGenerator.generate(
                subjective: subjective,
                objective: objective,
                assessment: assessment
            )
        }
    }

    private func applyGeneratedPlan() {
        if let generated = generatedPlan {
            plan.treatmentFrequency = generated.frequency
            plan.homeCareInstructions = generated.selfCare
            plan.nextSessionFocus = "Continue with \(generated.techniques.first ?? "treatment")"
        }
        dismiss()
    }
}

struct GeneratedTreatmentPlan {
    let frequency: String
    let techniques: [String]
    let exercises: [String]
    let selfCare: [String]
}

class TreatmentPlanGenerator {
    static func generate(subjective: Subjective, objective: Objective, assessment: Assessment) -> GeneratedTreatmentPlan {
        var frequency = "Weekly"
        var techniques: [String] = []
        var exercises: [String] = []
        var selfCare: [String] = []

        // Determine frequency based on pain level
        if subjective.painLevel >= 7 {
            frequency = "2x per week for 4 weeks, then weekly"
        } else if subjective.painLevel >= 4 {
            frequency = "Weekly for 6 weeks"
        } else {
            frequency = "Every 2 weeks for maintenance"
        }

        // Recommend techniques based on findings
        if !objective.muscleTension.isEmpty {
            techniques.append("Deep tissue massage for areas of tension")
            techniques.append("Trigger point therapy")
        }
        techniques.append("Swedish massage for relaxation")
        techniques.append("Myofascial release")

        // Generate exercises
        if objective.areasWorked.contains(where: { $0.region == .neck || $0.region == .shoulders }) {
            exercises.append("Neck stretches - 3x daily, hold 30 seconds")
            exercises.append("Shoulder rolls - 10 reps, 2x daily")
        }
        if objective.areasWorked.contains(where: { $0.region == .lowerBack }) {
            exercises.append("Cat-cow stretch - 10 reps, 2x daily")
            exercises.append("Pelvic tilts - 15 reps, 2x daily")
        }

        // Self-care recommendations
        selfCare.append("Apply ice for 15 minutes after activity if swelling present")
        selfCare.append("Apply heat for 20 minutes before stretching")
        selfCare.append("Stay hydrated - drink 8 glasses of water daily")
        selfCare.append("Maintain good posture throughout the day")

        if subjective.stressLevel >= 7 {
            selfCare.append("Practice deep breathing exercises - 5 minutes, 2x daily")
            selfCare.append("Consider meditation or mindfulness practice")
        }

        return GeneratedTreatmentPlan(
            frequency: frequency,
            techniques: techniques,
            exercises: exercises,
            selfCare: selfCare
        )
    }
}

// MARK: - Supporting View Helper
struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.tranquilTeal)
                Text(title)
                    .font(.headline)
            }

            content
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
