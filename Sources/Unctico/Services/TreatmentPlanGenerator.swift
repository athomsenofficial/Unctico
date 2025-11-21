import Foundation

/// Intelligent treatment plan generator based on SOAP note findings
/// Provides evidence-based recommendations for frequency, exercises, and home care
@MainActor
class TreatmentPlanGenerator: ObservableObject {
    static let shared = TreatmentPlanGenerator()

    private init() {}

    // MARK: - Treatment Plan Generation

    /// Generate a complete treatment plan from SOAP note findings
    func generateTreatmentPlan(
        subjective: Subjective,
        objective: Objective,
        assessment: Assessment
    ) -> Plan {
        var plan = Plan()

        // Generate treatment frequency recommendation
        plan.treatmentFrequency = recommendTreatmentFrequency(
            subjective: subjective,
            assessment: assessment
        )

        // Generate home care instructions
        plan.homeCareInstructions = generateHomeCareInstructions(
            subjective: subjective,
            objective: objective
        )

        // Generate recommended exercises
        plan.recommendedExercises = generateExercises(
            subjective: subjective,
            objective: objective
        )

        // Generate product recommendations
        plan.productRecommendations = generateProductRecommendations(
            subjective: subjective,
            objective: objective
        )

        // Set follow-up date
        plan.followUpDate = calculateFollowUpDate(
            frequency: plan.treatmentFrequency,
            response: assessment.treatmentResponse
        )

        // Generate referrals if needed
        plan.referrals = generateReferralRecommendations(
            subjective: subjective,
            assessment: assessment
        )

        // Set next session focus
        plan.nextSessionFocus = generateNextSessionFocus(
            objective: objective,
            assessment: assessment
        )

        return plan
    }

    // MARK: - Treatment Frequency

    func recommendTreatmentFrequency(
        subjective: Subjective,
        assessment: Assessment
    ) -> String {
        let painLevel = subjective.painLevel

        // Acute conditions (recent onset)
        if subjective.symptomDuration.lowercased().contains("day") ||
           subjective.symptomDuration.lowercased().contains("week") {
            if painLevel >= 8 {
                return "2-3 times per week for 2-3 weeks, then re-evaluate"
            } else if painLevel >= 6 {
                return "2 times per week for 3-4 weeks"
            } else {
                return "1-2 times per week for 4 weeks"
            }
        }

        // Chronic conditions
        if subjective.symptomDuration.lowercased().contains("month") ||
           subjective.symptomDuration.lowercased().contains("year") {
            switch assessment.treatmentResponse {
            case .improving:
                return "1 time per week, gradually transition to maintenance (every 2-4 weeks)"
            case .stable:
                return "1-2 times per week for ongoing management"
            case .declining:
                return "2 times per week with physician consultation recommended"
            case .resolved:
                return "Maintenance schedule: every 3-4 weeks for prevention"
            }
        }

        // Maintenance
        if assessment.treatmentResponse == .resolved {
            return "Maintenance schedule: every 3-4 weeks"
        }

        // Default recommendation
        return "1 time per week for 4-6 weeks, then re-evaluate"
    }

    // MARK: - Home Care Instructions

    func generateHomeCareInstructions(
        subjective: Subjective,
        objective: Objective
    ) -> [String] {
        var instructions: [String] = []

        // Hydration (always recommended)
        instructions.append("Drink plenty of water (8-10 glasses daily) to help flush metabolic waste")

        // Rest recommendations based on pain level
        if subjective.painLevel >= 7 {
            instructions.append("Rest affected area and avoid aggravating activities for 24-48 hours")
        }

        // Ice or heat recommendations
        if objective.triggerPoints.count > 3 {
            instructions.append("Apply ice for 15-20 minutes to reduce inflammation after activity")
            instructions.append("Use heat (warm bath or heating pad) before stretching to relax muscles")
        } else {
            instructions.append("Use heat therapy (warm bath, heating pad) for 15-20 minutes to relax muscles")
        }

        // Stress management
        if subjective.stressLevel >= 7 {
            instructions.append("Practice stress reduction techniques: deep breathing, meditation, or yoga")
            instructions.append("Ensure adequate sleep (7-9 hours) to support recovery")
        }

        // Sleep recommendations
        switch subjective.sleepQuality {
        case .poor:
            instructions.append("Improve sleep hygiene: consistent bedtime, dark room, avoid screens before bed")
            instructions.append("Consider supportive pillow for proper neck alignment")
        case .fair:
            instructions.append("Maintain consistent sleep schedule to support tissue healing")
        default:
            break
        }

        // Activity modifications
        if !subjective.activities.isEmpty {
            instructions.append("Modify activities that aggravate symptoms; take frequent breaks")
            instructions.append("Use proper ergonomics: adjust workstation, maintain good posture")
        }

        // Gentle movement
        if objective.muscleTension.count > 2 {
            instructions.append("Perform gentle stretching 2-3 times daily (hold each stretch 30 seconds)")
            instructions.append("Take movement breaks every 30-60 minutes if sitting for extended periods")
        }

        return instructions
    }

    // MARK: - Exercise Recommendations

    func generateExercises(
        subjective: Subjective,
        objective: Objective
    ) -> [Plan.Exercise] {
        var exercises: [Plan.Exercise] = []

        // Neck exercises
        if hasNeckIssues(subjective: subjective, objective: objective) {
            exercises.append(contentsOf: neckExercises)
        }

        // Shoulder exercises
        if hasShoulderIssues(subjective: subjective, objective: objective) {
            exercises.append(contentsOf: shoulderExercises)
        }

        // Back exercises
        if hasBackIssues(subjective: subjective, objective: objective) {
            exercises.append(contentsOf: backExercises)
        }

        // Lower back exercises
        if hasLowerBackIssues(subjective: subjective, objective: objective) {
            exercises.append(contentsOf: lowerBackExercises)
        }

        // Hip/leg exercises
        if hasHipLegIssues(subjective: subjective, objective: objective) {
            exercises.append(contentsOf: hipLegExercises)
        }

        // General flexibility if low tension
        if exercises.isEmpty {
            exercises.append(contentsOf: generalFlexibilityExercises)
        }

        return exercises
    }

    // MARK: - Product Recommendations

    func generateProductRecommendations(
        subjective: Subjective,
        objective: Objective
    ) -> [String] {
        var products: [String] = []

        // Pain management
        if subjective.painLevel >= 6 {
            products.append("Topical analgesic cream (menthol/capsaicin) for pain relief")
            products.append("Hot/cold therapy packs")
        }

        // Muscle tension
        if objective.muscleTension.count > 3 {
            products.append("Foam roller for self-myofascial release")
            products.append("Massage balls (tennis/lacrosse ball) for trigger point therapy")
        }

        // Sleep issues
        if subjective.sleepQuality == .poor || subjective.sleepQuality == .fair {
            products.append("Cervical support pillow for proper neck alignment")
            products.append("Magnesium supplement (consult physician) to aid muscle relaxation and sleep")
        }

        // Stress management
        if subjective.stressLevel >= 7 {
            products.append("Essential oils (lavender, eucalyptus) for aromatherapy")
            products.append("Epsom salt for relaxing baths")
        }

        // Posture support
        if !subjective.activities.isEmpty && subjective.activities.lowercased().contains("desk") {
            products.append("Lumbar support cushion for office chair")
            products.append("Ergonomic keyboard and mouse")
        }

        return products
    }

    // MARK: - Referral Recommendations

    func generateReferralRecommendations(
        subjective: Subjective,
        assessment: Assessment
    ) -> [String] {
        var referrals: [String] = []

        // Declining response
        if assessment.treatmentResponse == .declining {
            referrals.append("Physician evaluation for underlying conditions")
        }

        // High pain with no improvement
        if subjective.painLevel >= 8 {
            referrals.append("Pain management specialist for comprehensive evaluation")
        }

        // Neurological symptoms
        if subjective.chiefComplaint.lowercased().contains("numbness") ||
           subjective.chiefComplaint.lowercased().contains("tingling") {
            referrals.append("Neurologist for assessment of nerve involvement")
        }

        // Limited range of motion
        if !objective.rangeOfMotion.isEmpty &&
           objective.rangeOfMotion.contains(where: { $0.limitations != nil }) {
            referrals.append("Physical therapist for targeted rehabilitation")
        }

        // Chronic conditions requiring monitoring
        if !assessment.contraindications.isEmpty {
            referrals.append("Primary care physician for ongoing medical management")
        }

        return referrals
    }

    // MARK: - Next Session Focus

    func generateNextSessionFocus(
        objective: Objective,
        assessment: Assessment
    ) -> String {
        var focus: [String] = []

        // Priority areas from objective findings
        let highTensionAreas = objective.muscleTension
            .filter { $0.tensionLevel >= 7 }
            .map { $0.location.rawValue }

        if !highTensionAreas.isEmpty {
            focus.append("Focus on high-tension areas: \(highTensionAreas.joined(separator: ", "))")
        }

        // Trigger points
        if objective.triggerPoints.count > 0 {
            let tpAreas = objective.triggerPoints
                .map { $0.location.rawValue }
                .prefix(3)
                .joined(separator: ", ")
            focus.append("Continue trigger point therapy for \(tpAreas)")
        }

        // ROM limitations
        if !objective.rangeOfMotion.isEmpty {
            focus.append("Work on improving range of motion and flexibility")
        }

        // Treatment response
        switch assessment.treatmentResponse {
        case .improving:
            focus.append("Continue current treatment approach")
        case .stable:
            focus.append("Maintain current progress and prevent regression")
        case .declining:
            focus.append("Re-evaluate treatment approach and consider referral")
        case .resolved:
            focus.append("Transition to maintenance care and prevention")
        }

        return focus.joined(separator: ". ")
    }

    // MARK: - Follow-up Date

    func calculateFollowUpDate(
        frequency: String,
        response: Assessment.TreatmentResponse
    ) -> Date? {
        let calendar = Calendar.current

        // Parse frequency to determine days
        var daysUntilFollowUp = 7 // Default: 1 week

        if frequency.contains("2-3 times per week") {
            daysUntilFollowUp = 3
        } else if frequency.contains("2 times per week") {
            daysUntilFollowUp = 3
        } else if frequency.contains("1-2 times per week") {
            daysUntilFollowUp = 5
        } else if frequency.contains("1 time per week") {
            daysUntilFollowUp = 7
        } else if frequency.contains("every 2") {
            daysUntilFollowUp = 14
        } else if frequency.contains("every 3") {
            daysUntilFollowUp = 21
        } else if frequency.contains("every 4") {
            daysUntilFollowUp = 28
        }

        // Adjust based on treatment response
        switch response {
        case .declining:
            daysUntilFollowUp = min(daysUntilFollowUp, 7) // Sooner follow-up
        case .resolved:
            daysUntilFollowUp = max(daysUntilFollowUp, 21) // Less frequent
        default:
            break
        }

        return calendar.date(byAdding: .day, value: daysUntilFollowUp, to: Date())
    }

    // MARK: - Helper Methods

    private func hasNeckIssues(subjective: Subjective, objective: Objective) -> Bool {
        let neckLocations: [BodyLocation] = [.neck, .cervical, .upperTrapezius]
        return subjective.symptomLocations.contains(where: { neckLocations.contains($0) }) ||
               objective.areasWorked.contains(where: { neckLocations.contains($0) }) ||
               objective.muscleTension.contains(where: { neckLocations.contains($0.location) })
    }

    private func hasShoulderIssues(subjective: Subjective, objective: Objective) -> Bool {
        let shoulderLocations: [BodyLocation] = [.shoulder, .upperBack, .upperTrapezius]
        return subjective.symptomLocations.contains(where: { shoulderLocations.contains($0) }) ||
               objective.areasWorked.contains(where: { shoulderLocations.contains($0) })
    }

    private func hasBackIssues(subjective: Subjective, objective: Objective) -> Bool {
        let backLocations: [BodyLocation] = [.upperBack, .midBack, .thoracic]
        return subjective.symptomLocations.contains(where: { backLocations.contains($0) }) ||
               objective.areasWorked.contains(where: { backLocations.contains($0) })
    }

    private func hasLowerBackIssues(subjective: Subjective, objective: Objective) -> Bool {
        let lowerBackLocations: [BodyLocation] = [.lowerBack, .lumbar, .sacrum]
        return subjective.symptomLocations.contains(where: { lowerBackLocations.contains($0) }) ||
               objective.areasWorked.contains(where: { lowerBackLocations.contains($0) })
    }

    private func hasHipLegIssues(subjective: Subjective, objective: Objective) -> Bool {
        let hipLegLocations: [BodyLocation] = [.hip, .glutes, .thigh, .calf]
        return subjective.symptomLocations.contains(where: { hipLegLocations.contains($0) }) ||
               objective.areasWorked.contains(where: { hipLegLocations.contains($0) })
    }

    // MARK: - Exercise Library

    private var neckExercises: [Plan.Exercise] {
        [
            Plan.Exercise(
                name: "Chin Tucks",
                description: "Sit or stand with good posture. Gently draw your chin straight back (like making a double chin). Hold for 5 seconds. This strengthens deep neck flexors and improves posture.",
                frequency: "10 repetitions, 3 times daily"
            ),
            Plan.Exercise(
                name: "Neck Rotations",
                description: "Slowly turn your head to look over your right shoulder, hold for 10 seconds. Return to center. Repeat on left side. This improves rotational mobility.",
                frequency: "5 repetitions each side, 2-3 times daily"
            ),
            Plan.Exercise(
                name: "Upper Trapezius Stretch",
                description: "Sit upright. Gently tilt your head to the right, bringing your ear toward your shoulder. For a deeper stretch, place your right hand on the left side of your head. Hold 30 seconds each side.",
                frequency: "3 repetitions each side, 2 times daily"
            )
        ]
    }

    private var shoulderExercises: [Plan.Exercise] {
        [
            Plan.Exercise(
                name: "Shoulder Rolls",
                description: "Roll shoulders backward in a circular motion 10 times, then forward 10 times. This promotes blood flow and reduces tension.",
                frequency: "2-3 sets, 3 times daily"
            ),
            Plan.Exercise(
                name: "Doorway Pec Stretch",
                description: "Stand in a doorway with forearm on doorframe at 90 degrees. Step forward with one foot until you feel a stretch across your chest. Hold 30 seconds.",
                frequency: "3 repetitions each side, 2 times daily"
            ),
            Plan.Exercise(
                name: "Wall Angels",
                description: "Stand with back against wall. Slowly raise arms overhead in a 'snow angel' motion, keeping contact with wall. This improves shoulder mobility and posture.",
                frequency: "10 repetitions, 2 times daily"
            )
        ]
    }

    private var backExercises: [Plan.Exercise] {
        [
            Plan.Exercise(
                name: "Cat-Cow Stretch",
                description: "On hands and knees, alternate arching your back (cow) and rounding it (cat). Move slowly with your breath. This mobilizes the entire spine.",
                frequency: "10 repetitions, 2 times daily"
            ),
            Plan.Exercise(
                name: "Thoracic Extension",
                description: "Sit in chair. Place hands behind head. Gently arch backward over the back of the chair, looking up. Hold 5-10 seconds. Improves upper back mobility.",
                frequency: "5-8 repetitions, 2-3 times daily"
            ),
            Plan.Exercise(
                name: "Child's Pose",
                description: "Kneel and sit back on heels. Extend arms forward and lower chest toward floor. Hold for 30-60 seconds. Gently stretches entire back.",
                frequency: "Hold 30-60 seconds, 2-3 times daily"
            )
        ]
    }

    private var lowerBackExercises: [Plan.Exercise] {
        [
            Plan.Exercise(
                name: "Pelvic Tilts",
                description: "Lie on back with knees bent. Gently flatten your lower back against the floor by tightening your abdominal muscles. Hold 5 seconds. Strengthens core.",
                frequency: "10-15 repetitions, 2 times daily"
            ),
            Plan.Exercise(
                name: "Knee to Chest Stretch",
                description: "Lie on back. Bring one knee to chest, holding with both hands. Hold 30 seconds. Repeat other side. Gently stretches lower back and glutes.",
                frequency: "3 repetitions each side, 2 times daily"
            ),
            Plan.Exercise(
                name: "Bridge Exercise",
                description: "Lie on back with knees bent, feet flat. Lift hips toward ceiling, squeezing glutes. Hold 5-10 seconds. Strengthens glutes and lower back.",
                frequency: "10-15 repetitions, 2 times daily"
            )
        ]
    }

    private var hipLegExercises: [Plan.Exercise] {
        [
            Plan.Exercise(
                name: "Hip Flexor Stretch",
                description: "Kneel on one knee (like proposing). Push hips forward until you feel stretch in front of back hip. Hold 30 seconds each side.",
                frequency: "3 repetitions each side, 2 times daily"
            ),
            Plan.Exercise(
                name: "Piriformis Stretch",
                description: "Lie on back. Cross one ankle over opposite knee (figure 4). Pull the uncrossed leg toward chest. Hold 30 seconds. Stretches deep hip rotators.",
                frequency: "3 repetitions each side, 2 times daily"
            ),
            Plan.Exercise(
                name: "Hamstring Stretch",
                description: "Lie on back. Raise one leg straight up, holding behind thigh. Keep knee straight. Hold 30 seconds. Stretches back of thigh.",
                frequency: "3 repetitions each side, 2 times daily"
            )
        ]
    }

    private var generalFlexibilityExercises: [Plan.Exercise] {
        [
            Plan.Exercise(
                name: "Full Body Stretch",
                description: "Lie on back. Extend arms overhead and legs straight, reaching in opposite directions. Hold 10 seconds. Lengthens entire body.",
                frequency: "3-5 repetitions, morning and evening"
            ),
            Plan.Exercise(
                name: "Seated Spinal Twist",
                description: "Sit with legs extended. Bend one knee and place foot outside opposite thigh. Twist toward bent knee. Hold 30 seconds each side. Improves spinal rotation.",
                frequency: "2-3 repetitions each side, 2 times daily"
            ),
            Plan.Exercise(
                name: "Standing Forward Fold",
                description: "Stand with feet hip-width apart. Slowly fold forward from hips, letting head and arms hang. Hold 30 seconds. Stretches entire posterior chain.",
                frequency: "Hold 30-60 seconds, 2-3 times daily"
            )
        ]
    }
}
