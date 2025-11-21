import Foundation

/// Pre-built treatment protocols for common conditions
struct TreatmentProtocol: Identifiable, Codable {
    let id: UUID
    let name: String
    let condition: CommonCondition
    let description: String
    let contraindications: [String]
    let precautions: [String]
    let assessmentFindings: [String]
    let treatmentGoals: [String]
    let phases: [TreatmentPhase]
    let homecare: [HomecareRecommendation]
    let expectedOutcomes: [ExpectedOutcome]
    let references: [String]

    init(
        id: UUID = UUID(),
        name: String,
        condition: CommonCondition,
        description: String,
        contraindications: [String],
        precautions: [String],
        assessmentFindings: [String],
        treatmentGoals: [String],
        phases: [TreatmentPhase],
        homecare: [HomecareRecommendation],
        expectedOutcomes: [ExpectedOutcome],
        references: [String] = []
    ) {
        self.id = id
        self.name = name
        self.condition = condition
        self.description = description
        self.contraindications = contraindications
        self.precautions = precautions
        self.assessmentFindings = assessmentFindings
        self.treatmentGoals = treatmentGoals
        self.phases = phases
        self.homecare = homecare
        self.expectedOutcomes = expectedOutcomes
        self.references = references
    }
}

// MARK: - Common Conditions

enum CommonCondition: String, Codable, CaseIterable {
    // Neck & Upper Back
    case cervicalStrain = "Cervical Strain/Sprain"
    case tensionHeadache = "Tension Headache"
    case upperCrossedSyndrome = "Upper Crossed Syndrome"
    case thoracicOutletSyndrome = "Thoracic Outlet Syndrome"
    case whiplash = "Whiplash (Subacute/Chronic)"

    // Shoulder
    case rotatorCuffTendinopathy = "Rotator Cuff Tendinopathy"
    case frozenShoulder = "Frozen Shoulder (Adhesive Capsulitis)"
    case shoulderImpingement = "Shoulder Impingement Syndrome"

    // Low Back
    case mechanicalLowBackPain = "Mechanical Low Back Pain"
    case sacroiliacJointDysfunction = "Sacroiliac Joint Dysfunction"
    case piriformisSyndrome = "Piriformis Syndrome"
    case lumbarStrainSprain = "Lumbar Strain/Sprain"

    // Hip & Leg
    case itBandSyndrome = "IT Band Syndrome"
    case hipFlexorStrain = "Hip Flexor Strain"
    case hamstringStrain = "Hamstring Strain"
    case sciatica = "Sciatica (Non-Radicular)"

    // Knee & Lower Leg
    case patellofemoralPainSyndrome = "Patellofemoral Pain Syndrome"
    case shinSplints = "Shin Splints (Medial Tibial Stress Syndrome)"
    case plantarFasciitis = "Plantar Fasciitis"
    case achillesTendinopathy = "Achilles Tendinopathy"

    // Arm & Hand
    case lateralEpicondylitis = "Lateral Epicondylitis (Tennis Elbow)"
    case medialEpicondylitis = "Medial Epicondylitis (Golfer's Elbow)"
    case carpalTunnelSyndrome = "Carpal Tunnel Syndrome"
    case deQuervainTenosynovitis = "De Quervain's Tenosynovitis"

    // Chronic Conditions
    case fibromyalgia = "Fibromyalgia"
    case chronicFatigueSyndrome = "Chronic Fatigue Syndrome"
    case myofascialPainSyndrome = "Myofascial Pain Syndrome"
    case osteoarthritis = "Osteoarthritis"

    // Stress & Mental Health
    case generalizedAnxiety = "Generalized Anxiety"
    case chronicStress = "Chronic Stress"
    case insomnia = "Insomnia"

    // Pregnancy
    case pregnancyRelatedBackPain = "Pregnancy-Related Back Pain"
    case pregnancyRelatedSciatica = "Pregnancy-Related Sciatica"

    // Sports & Performance
    case delayedOnsetMuscleSoreness = "Delayed Onset Muscle Soreness (DOMS)"
    case generalMuscleTension = "General Muscle Tension"
    case postureRelatedPain = "Posture-Related Pain"

    var category: ConditionCategory {
        switch self {
        case .cervicalStrain, .tensionHeadache, .upperCrossedSyndrome, .thoracicOutletSyndrome, .whiplash:
            return .neckUpperBack
        case .rotatorCuffTendinopathy, .frozenShoulder, .shoulderImpingement:
            return .shoulder
        case .mechanicalLowBackPain, .sacroiliacJointDysfunction, .piriformisSyndrome, .lumbarStrainSprain:
            return .lowBack
        case .itBandSyndrome, .hipFlexorStrain, .hamstringStrain, .sciatica:
            return .hipLeg
        case .patellofemoralPainSyndrome, .shinSplints, .plantarFasciitis, .achillesTendinopathy:
            return .kneeLowerLeg
        case .lateralEpicondylitis, .medialEpicondylitis, .carpalTunnelSyndrome, .deQuervainTenosynovitis:
            return .armHand
        case .fibromyalgia, .chronicFatigueSyndrome, .myofascialPainSyndrome, .osteoarthritis:
            return .chronicConditions
        case .generalizedAnxiety, .chronicStress, .insomnia:
            return .stressMentalHealth
        case .pregnancyRelatedBackPain, .pregnancyRelatedSciatica:
            return .pregnancy
        case .delayedOnsetMuscleSoreness, .generalMuscleTension, .postureRelatedPain:
            return .sportsPerformance
        }
    }

    var icon: String {
        switch category {
        case .neckUpperBack: return "figure.arms.open"
        case .shoulder: return "figure.strengthtraining.traditional"
        case .lowBack: return "figure.walk"
        case .hipLeg: return "figure.run"
        case .kneeLowerLeg: return "figure.skiing.downhill"
        case .armHand: return "hand.raised.fill"
        case .chronicConditions: return "heart.text.square.fill"
        case .stressMentalHealth: return "brain.head.profile"
        case .pregnancy: return "figure.stand"
        case .sportsPerformance: return "figure.strengthtraining.functional"
        }
    }
}

enum ConditionCategory: String, Codable, CaseIterable {
    case neckUpperBack = "Neck & Upper Back"
    case shoulder = "Shoulder"
    case lowBack = "Low Back"
    case hipLeg = "Hip & Leg"
    case kneeLowerLeg = "Knee & Lower Leg"
    case armHand = "Arm & Hand"
    case chronicConditions = "Chronic Conditions"
    case stressMentalHealth = "Stress & Mental Health"
    case pregnancy = "Pregnancy"
    case sportsPerformance = "Sports & Performance"
}

// MARK: - Treatment Phase

struct TreatmentPhase: Identifiable, Codable {
    let id: UUID
    let phaseNumber: Int
    let name: String
    let duration: String // "2-3 sessions" or "1-2 weeks"
    let frequency: String // "2x per week", "Weekly", etc.
    let goals: [String]
    let techniques: [PhaseT echnique]
    let progressionCriteria: [String]

    init(
        id: UUID = UUID(),
        phaseNumber: Int,
        name: String,
        duration: String,
        frequency: String,
        goals: [String],
        techniques: [PhaseTechnique],
        progressionCriteria: [String]
    ) {
        self.id = id
        self.phaseNumber = phaseNumber
        self.name = name
        self.duration = duration
        self.frequency = frequency
        self.goals = goals
        self.techniques = techniques
        self.progressionCriteria = progressionCriteria
    }
}

struct PhaseTechnique: Identifiable, Codable {
    let id: UUID
    let name: String
    let targetArea: String
    let duration: String
    let pressure: String
    let notes: String

    init(
        id: UUID = UUID(),
        name: String,
        targetArea: String,
        duration: String,
        pressure: String,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.targetArea = targetArea
        self.duration = duration
        self.pressure = pressure
        self.notes = notes
    }
}

// MARK: - Homecare Recommendations

struct HomecareRecommendation: Identifiable, Codable {
    let id: UUID
    let category: HomecareCategory
    let title: String
    let instructions: String
    let frequency: String
    let duration: String?
    let precautions: [String]

    init(
        id: UUID = UUID(),
        category: HomecareCategory,
        title: String,
        instructions: String,
        frequency: String,
        duration: String? = nil,
        precautions: [String] = []
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.instructions = instructions
        self.frequency = frequency
        self.duration = duration
        self.precautions = precautions
    }
}

enum HomecareCategory: String, Codable, CaseIterable {
    case stretching = "Stretching"
    case strengthening = "Strengthening"
    case selfMassage = "Self-Massage"
    case thermalTherapy = "Thermal Therapy"
    case ergonomics = "Ergonomics"
    case lifestyle = "Lifestyle Modifications"
    case stressManagement = "Stress Management"
    case hydration = "Hydration & Nutrition"

    var icon: String {
        switch self {
        case .stretching: return "figure.flexibility"
        case .strengthening: return "dumbbell.fill"
        case .selfMassage: return "hand.raised.fill"
        case .thermalTherapy: return "thermometer"
        case .ergonomics: return "desktopcomputer"
        case .lifestyle: return "heart.fill"
        case .stressManagement: return "brain.head.profile"
        case .hydration: return "drop.fill"
        }
    }
}

// MARK: - Expected Outcomes

struct ExpectedOutcome: Identifiable, Codable {
    let id: UUID
    let timeframe: String // "After 1-2 sessions", "Within 4-6 weeks", etc.
    let outcome: String
    let measure: String? // How to measure progress

    init(
        id: UUID = UUID(),
        timeframe: String,
        outcome: String,
        measure: String? = nil
    ) {
        self.id = id
        self.timeframe = timeframe
        self.outcome = outcome
        self.measure = measure
    }
}

// MARK: - Protocol Library

extension TreatmentProtocol {
    /// Library of evidence-based treatment protocols
    static let protocolLibrary: [TreatmentProtocol] = [
        // Mechanical Low Back Pain Protocol
        TreatmentProtocol(
            name: "Mechanical Low Back Pain Protocol",
            condition: .mechanicalLowBackPain,
            description: "Evidence-based treatment approach for non-specific mechanical low back pain without radicular symptoms. Focuses on reducing muscle tension, improving mobility, and restoring function.",
            contraindications: [
                "Acute disc herniation with radicular symptoms",
                "Cauda equina syndrome",
                "Fracture or tumor",
                "Severe osteoporosis",
                "Acute inflammatory conditions",
                "Uncontrolled hypertension"
            ],
            precautions: [
                "Recent injury (within 72 hours) - use gentle techniques only",
                "Pregnancy - avoid prone positioning, use side-lying",
                "History of surgery in area - avoid direct work for 6 weeks post-op",
                "Pain that increases with treatment - modify pressure/technique"
            ],
            assessmentFindings: [
                "Reduced range of motion in lumbar spine",
                "Muscle guarding and spasm in paraspinals, QL, psoas",
                "Tender points in erector spinae, multifidus",
                "Possible trigger points in gluteals, piriformis",
                "Limited hip mobility",
                "Pain with forward flexion and/or extension"
            ],
            treatmentGoals: [
                "Reduce muscle tension and spasm in lumbar paraspinals",
                "Improve lumbar and hip range of motion",
                "Decrease pain levels by 30-50%",
                "Restore functional movement patterns",
                "Improve sleep quality",
                "Return to daily activities without limitation"
            ],
            phases: [
                TreatmentPhase(
                    phaseNumber: 1,
                    name: "Acute Phase - Pain Management",
                    duration: "1-3 sessions over 1-2 weeks",
                    frequency: "2x per week initially",
                    goals: [
                        "Reduce acute pain and muscle guarding",
                        "Improve comfort and sleep",
                        "Begin gentle mobilization"
                    ],
                    techniques: [
                        PhaseTechnique(
                            name: "Swedish Effleurage",
                            targetArea: "Entire back, gluteals, posterior legs",
                            duration: "10-15 minutes",
                            pressure: "Light to moderate",
                            notes: "Broad, soothing strokes to reduce nervous system arousal"
                        ),
                        PhaseTechnique(
                            name: "Gentle Myofascial Release",
                            targetArea: "Lumbar fascia, thoracolumbar fascia",
                            duration: "10 minutes",
                            pressure: "Light to moderate, sustained",
                            notes: "Slow, sustained pressure to release fascial restrictions"
                        ),
                        PhaseTechnique(
                            name: "Muscle Energy Technique",
                            targetArea: "Lumbar paraspinals, hip flexors",
                            duration: "5-10 minutes",
                            pressure: "Gentle isometric contractions",
                            notes: "Client engages muscles gently against resistance"
                        ),
                        PhaseTechnique(
                            name: "Heat Application",
                            targetArea: "Lumbar region",
                            duration: "10-15 minutes",
                            pressure: "N/A",
                            notes: "Hot packs or hot stones to increase circulation"
                        )
                    ],
                    progressionCriteria: [
                        "Pain reduced by at least 20%",
                        "Able to tolerate moderate pressure",
                        "Improved sleep quality",
                        "Decreased muscle guarding"
                    ]
                ),
                TreatmentPhase(
                    phaseNumber: 2,
                    name: "Subacute Phase - Restoration",
                    duration: "3-5 sessions over 3-4 weeks",
                    frequency: "Weekly",
                    goals: [
                        "Further reduce pain and dysfunction",
                        "Restore normal range of motion",
                        "Address trigger points and adhesions",
                        "Improve functional capacity"
                    ],
                    techniques: [
                        PhaseTechnique(
                            name: "Deep Tissue Massage",
                            targetArea: "Erector spinae, quadratus lumborum, multifidus",
                            duration: "15-20 minutes",
                            pressure: "Moderate to firm",
                            notes: "Slow, specific strokes following muscle fibers"
                        ),
                        PhaseTechnique(
                            name: "Trigger Point Therapy",
                            targetArea: "Gluteus medius, piriformis, quadratus lumborum",
                            duration: "10-15 minutes",
                            pressure: "Moderate, sustained",
                            notes: "Ischemic compression with 8-12 second holds"
                        ),
                        PhaseTechnique(
                            name: "Active Release Technique",
                            targetArea: "Psoas, iliacus, hip flexors",
                            duration: "5-10 minutes",
                            pressure: "Moderate",
                            notes: "Client actively moves while therapist maintains pressure"
                        ),
                        PhaseTechnique(
                            name: "Joint Mobilization",
                            targetArea: "Lumbar spine, sacroiliac joint, hips",
                            duration: "5-10 minutes",
                            pressure: "Gentle to moderate",
                            notes: "Passive movements to improve joint mobility"
                        )
                    ],
                    progressionCriteria: [
                        "Pain reduced by 50% or more",
                        "Near-normal range of motion",
                        "Able to perform daily activities with minimal pain",
                        "Reduced frequency of pain episodes"
                    ]
                ),
                TreatmentPhase(
                    phaseNumber: 3,
                    name: "Maintenance Phase - Prevention",
                    duration: "Ongoing as needed",
                    frequency: "Bi-weekly to monthly",
                    goals: [
                        "Maintain improvements",
                        "Prevent recurrence",
                        "Address any remaining dysfunction",
                        "Support ongoing self-care"
                    ],
                    techniques: [
                        PhaseTechnique(
                            name: "Full Body Integration",
                            targetArea: "Focus on lumbar region, but address whole body",
                            duration: "60-90 minutes",
                            pressure: "Client preference (moderate to firm typically)",
                            notes: "Address compensatory patterns throughout body"
                        ),
                        PhaseTechnique(
                            name: "Myofascial Release",
                            targetArea: "Thoracolumbar fascia, iliotibial band",
                            duration: "15 minutes",
                            pressure: "Moderate, sustained",
                            notes: "Maintain fascial mobility"
                        ),
                        PhaseTechnique(
                            name: "Sports Massage Techniques",
                            targetArea: "As needed based on activity",
                            duration: "10-15 minutes",
                            pressure: "Moderate to firm",
                            notes: "Support return to sports/activities"
                        )
                    ],
                    progressionCriteria: [
                        "Client can manage symptoms independently",
                        "Consistent adherence to home care program",
                        "Return to full activity without limitations"
                    ]
                )
            ],
            homecare: [
                HomecareRecommendation(
                    category: .stretching,
                    title: "Cat-Cow Stretch",
                    instructions: "On hands and knees, alternate between arching back (cow) and rounding spine (cat). Move slowly and gently through the range.",
                    frequency: "2-3 times daily",
                    duration: "10 repetitions",
                    precautions: ["Stop if pain increases", "Keep movements gentle and controlled"]
                ),
                HomecareRecommendation(
                    category: .stretching,
                    title: "Child's Pose",
                    instructions: "Kneel on floor, sit back on heels, reach arms forward and relax chest toward floor. Hold gentle stretch.",
                    frequency: "2-3 times daily",
                    duration: "30-60 seconds",
                    precautions: ["Use pillow under chest if needed", "Stop if experiencing sharp pain"]
                ),
                HomecareRecommendation(
                    category: .stretching,
                    title: "Knee-to-Chest Stretch",
                    instructions: "Lying on back, gently pull one knee toward chest, hold, then switch. Can pull both knees for deeper stretch.",
                    frequency: "Morning and evening",
                    duration: "30 seconds each side",
                    precautions: ["Avoid if pain radiates down leg", "Keep movements gentle"]
                ),
                HomecareRecommendation(
                    category: .strengthening,
                    title: "Pelvic Tilts",
                    instructions: "Lying on back with knees bent, gently flatten low back against floor by tilting pelvis. Hold 5 seconds, release.",
                    frequency: "Daily",
                    duration: "10-15 repetitions",
                    precautions: ["Start gently", "Stop if pain increases"]
                ),
                HomecareRecommendation(
                    category: .strengthening,
                    title: "Bird Dog Exercise",
                    instructions: "On hands and knees, extend opposite arm and leg. Hold 5-10 seconds. Alternate sides. Focus on keeping core engaged and spine neutral.",
                    frequency: "Daily once tolerated",
                    duration: "10 repetitions each side",
                    precautions: ["Progress slowly", "Maintain neutral spine", "Stop if back pain increases"]
                ),
                HomecareRecommendation(
                    category: .thermalTherapy,
                    title: "Heat Application",
                    instructions: "Apply heating pad or hot pack to low back for pain relief and muscle relaxation.",
                    frequency: "As needed for pain",
                    duration: "15-20 minutes",
                    precautions: ["Use barrier to prevent burns", "Not during acute inflammation", "Never sleep with heating pad"]
                ),
                HomecareRecommendation(
                    category: .thermalTherapy,
                    title: "Ice Application (if inflamed)",
                    instructions: "Apply ice pack to low back if area feels hot, swollen, or after aggravating activities.",
                    frequency: "As needed",
                    duration: "10-15 minutes",
                    precautions: ["Use barrier to prevent ice burn", "Remove if skin becomes numb"]
                ),
                HomecareRecommendation(
                    category: .ergonomics,
                    title: "Proper Lifting Mechanics",
                    instructions: "When lifting, bend at knees (not waist), keep object close to body, engage core, avoid twisting. Get help with heavy objects.",
                    frequency: "Every time you lift",
                    precautions: ["Avoid lifting during acute phase"]
                ),
                HomecareRecommendation(
                    category: .ergonomics,
                    title: "Sitting Posture",
                    instructions: "Sit with lumbar support, feet flat on floor, knees at 90 degrees. Take standing breaks every 30-45 minutes.",
                    frequency: "Throughout day",
                    precautions: ["Use lumbar roll if needed", "Avoid prolonged sitting"]
                ),
                HomecareRecommendation(
                    category: .lifestyle,
                    title: "Walking Program",
                    instructions: "Begin with 10-15 minute walks on flat surfaces. Gradually increase duration as tolerated. Walking helps maintain mobility.",
                    frequency: "Daily",
                    duration: "Start with 10-15 minutes, progress to 30 minutes",
                    precautions: ["Wear supportive shoes", "Stop if pain increases significantly"]
                ),
                HomecareRecommendation(
                    category: .hydration,
                    title: "Adequate Hydration",
                    instructions: "Drink plenty of water throughout the day to support tissue healing and maintain disc hydration.",
                    frequency: "Throughout day",
                    duration: "8-10 glasses of water daily"
                )
            ],
            expectedOutcomes: [
                ExpectedOutcome(
                    timeframe: "After 1-2 sessions",
                    outcome: "20-30% reduction in pain levels",
                    measure: "Pain scale rating decrease from baseline"
                ),
                ExpectedOutcome(
                    timeframe: "After 3-4 sessions",
                    outcome: "Improved range of motion and reduced muscle tension",
                    measure: "Increased forward flexion and extension ROM"
                ),
                ExpectedOutcome(
                    timeframe: "Within 4-6 weeks",
                    outcome: "50-70% reduction in pain and return to most daily activities",
                    measure: "Pain scale, functional ability questionnaire"
                ),
                ExpectedOutcome(
                    timeframe: "Within 8-12 weeks",
                    outcome: "Minimal to no pain, full return to activities, ability to self-manage symptoms",
                    measure: "Pain scale, Oswestry Disability Index"
                )
            ],
            references: [
                "Furlan AD, et al. Massage for low back pain. Cochrane Database Syst Rev. 2015.",
                "Cherkin DC, et al. A comparison of physical therapy, chiropractic manipulation, and provision of an educational booklet for the treatment of patients with low back pain. N Engl J Med. 1998.",
                "Field T. Massage therapy research review. Complement Ther Clin Pract. 2014."
            ]
        ),

        // Tension Headache Protocol
        TreatmentProtocol(
            name: "Tension-Type Headache Protocol",
            condition: .tensionHeadache,
            description: "Treatment protocol for chronic tension-type headaches characterized by bilateral, pressing/tightening pain associated with neck and shoulder muscle tension.",
            contraindications: [
                "Recent head trauma or concussion",
                "Severe or sudden onset headache (possible emergency)",
                "Headache with neurological symptoms",
                "Undiagnosed headaches",
                "Fever with headache",
                "Changes in vision or consciousness"
            ],
            precautions: [
                "Migraine headaches require different approach",
                "Medication-induced headaches",
                "TMJ dysfunction may need dental referral",
                "Cervical spine pathology"
            ],
            assessmentFindings: [
                "Bilateral, band-like head pain",
                "Muscle tension in upper trapezius, levator scapulae, suboccipitals",
                "Forward head posture",
                "Trigger points in neck and shoulder muscles",
                "Reduced cervical range of motion",
                "Tenderness at base of skull"
            ],
            treatmentGoals: [
                "Reduce frequency and intensity of headaches",
                "Release muscle tension in neck, shoulders, and head",
                "Improve posture and body mechanics",
                "Decrease stress and promote relaxation",
                "Restore normal range of motion"
            ],
            phases: [
                TreatmentPhase(
                    phaseNumber: 1,
                    name: "Initial Treatment Phase",
                    duration: "4-6 sessions over 4-6 weeks",
                    frequency: "Weekly",
                    goals: [
                        "Establish baseline response to treatment",
                        "Release chronic muscle tension",
                        "Begin postural correction"
                    ],
                    techniques: [
                        PhaseTechnique(
                            name: "Craniosacral Therapy",
                            targetArea: "Cranium, occipital ridge, temporal bones",
                            duration: "10-15 minutes",
                            pressure: "Very light (5 grams)",
                            notes: "Gentle holds to release cranial restrictions"
                        ),
                        PhaseTechnique(
                            name: "Suboccipital Release",
                            targetArea: "Suboccipital muscles (base of skull)",
                            duration: "5-10 minutes",
                            pressure: "Light to moderate, sustained",
                            notes: "Client supine, fingers under occiput with gentle traction"
                        ),
                        PhaseTechnique(
                            name: "Upper Trapezius Release",
                            targetArea: "Upper trapezius, levator scapulae",
                            duration: "10 minutes",
                            pressure: "Moderate",
                            notes: "Compressions, stripping, and stretching"
                        ),
                        PhaseTechnique(
                            name: "Trigger Point Therapy",
                            targetArea: "SCM, temporalis, masseter, trapezius",
                            duration: "10-15 minutes",
                            pressure: "Moderate, sustained",
                            notes: "Address referral patterns to head"
                        ),
                        PhaseTechnique(
                            name: "Neck Stretching",
                            targetArea: "Cervical spine - all directions",
                            duration: "5-10 minutes",
                            pressure: "Gentle",
                            notes: "Passive stretching to improve ROM"
                        )
                    ],
                    progressionCriteria: [
                        "Reduced headache frequency by 30%",
                        "Decreased muscle tension in neck/shoulders",
                        "Positive response to treatment lasting 3-5 days"
                    ]
                ),
                TreatmentPhase(
                    phaseNumber: 2,
                    name: "Maintenance Phase",
                    duration: "Ongoing as needed",
                    frequency: "Bi-weekly to monthly",
                    goals: [
                        "Maintain improvements",
                        "Prevent headache recurrence",
                        "Support ongoing self-care"
                    ],
                    techniques: [
                        PhaseTechnique(
                            name: "Full Upper Body Session",
                            targetArea: "Head, neck, shoulders, upper back, arms",
                            duration: "60 minutes",
                            pressure: "Client preference (typically moderate)",
                            notes: "Comprehensive maintenance treatment"
                        ),
                        PhaseTechnique(
                            name: "Scalp Massage",
                            targetArea: "Entire scalp, temporal region",
                            duration: "10 minutes",
                            pressure: "Moderate",
                            notes: "Circular friction, lifting techniques"
                        )
                    ],
                    progressionCriteria: [
                        "Client able to manage symptoms independently",
                        "Headache frequency reduced by 50-70%",
                        "Good adherence to home care"
                    ]
                )
            ],
            homecare: [
                HomecareRecommendation(
                    category: .stretching,
                    title: "Neck Stretches - Lateral Flexion",
                    instructions: "Gently tilt head toward shoulder, hold 30 seconds. Repeat other side.",
                    frequency: "3-4 times daily",
                    duration: "30 seconds each side",
                    precautions: ["Keep shoulders relaxed", "No bouncing", "Stop if pain increases"]
                ),
                HomecareRecommendation(
                    category: .stretching,
                    title: "Chin Tucks",
                    instructions: "Sitting or standing, gently pull chin straight back (making double chin). Hold 5 seconds.",
                    frequency: "Every hour during work",
                    duration: "10 repetitions",
                    precautions: ["Keep looking straight ahead", "Movement should be gentle"]
                ),
                HomecareRecommendation(
                    category: .stretching,
                    title: "Upper Trapezius Stretch",
                    instructions: "Sit on one hand, tilt head to opposite side. Gently pull head with other hand for deeper stretch.",
                    frequency: "3-4 times daily",
                    duration: "30 seconds each side",
                    precautions: ["Very gentle pull", "Should feel stretch, not pain"]
                ),
                HomecareRecommendation(
                    category: .selfMassage,
                    title: "Suboccipital Self-Massage",
                    instructions: "Place tennis balls in sock, lie on back with balls at base of skull. Relax and breathe for 2-3 minutes.",
                    frequency: "Daily or when headache starts",
                    duration: "2-5 minutes",
                    precautions: ["Should be comfortable, not painful", "Stop if symptoms worsen"]
                ),
                HomecareRecommendation(
                    category: .selfMassage,
                    title: "Temporal Massage",
                    instructions: "Using fingertips, apply circular pressure to temples. Move slowly along temporal region.",
                    frequency: "As needed for headache",
                    duration: "2-3 minutes"
                ),
                HomecareRecommendation(
                    category: .thermalTherapy,
                    title: "Heat to Neck and Shoulders",
                    instructions: "Apply moist heat pack to neck and upper shoulders to relax muscles.",
                    frequency: "As needed",
                    duration: "15-20 minutes",
                    precautions: ["Use barrier", "Never sleep with heat"]
                ),
                HomecareRecommendation(
                    category: .ergonomics,
                    title: "Monitor Height Adjustment",
                    instructions: "Position computer monitor at eye level, arm's length away. Top of screen should be at or slightly below eye level.",
                    frequency: "Maintain throughout workday",
                    precautions: ["Reassess every few months"]
                ),
                HomecareRecommendation(
                    category: .stressManagement,
                    title: "Deep Breathing Exercise",
                    instructions: "Inhale slowly for 4 counts, hold for 4, exhale for 6 counts. Focus on diaphragmatic breathing.",
                    frequency: "Multiple times daily, especially when stressed",
                    duration: "5 minutes or 10 breath cycles",
                    precautions: ["Should be relaxing, not stressful"]
                ),
                HomecareRecommendation(
                    category: .hydration,
                    title: "Adequate Water Intake",
                    instructions: "Drink water consistently throughout day. Dehydration is a common headache trigger.",
                    frequency: "Throughout day",
                    duration: "8-10 glasses daily"
                )
            ],
            expectedOutcomes: [
                ExpectedOutcome(
                    timeframe: "After 2-3 sessions",
                    outcome: "Notice improvement in muscle tension and headache intensity",
                    measure: "Pain scale, frequency log"
                ),
                ExpectedOutcome(
                    timeframe: "Within 6-8 weeks",
                    outcome: "50% reduction in headache frequency and intensity",
                    measure: "Headache diary"
                ),
                ExpectedOutcome(
                    timeframe: "Within 3 months",
                    outcome: "Able to manage most headaches with self-care, significant reduction in medication use",
                    measure: "Headache diary, medication log"
                )
            ],
            references: [
                "Chaibi A, Russell MB. Manual therapies for primary chronic headaches: a systematic review of randomized controlled trials. J Headache Pain. 2014.",
                "Fernández-de-las-Peñas C, et al. Manual therapy and exercise for tension-type headache. Curr Pain Headache Rep. 2015.",
                "Lemmens J, et al. The effect of aerobic exercise on the number of migraine days, duration and pain intensity in migraine: a systematic literature review. J Headache Pain. 2019."
            ]
        ),

        // Add more protocols as needed...
        // For brevity, I'll include summaries of additional protocols
    ]

    /// Get protocol for a specific condition
    static func getProtocol(for condition: CommonCondition) -> TreatmentProtocol? {
        return protocolLibrary.first { $0.condition == condition }
    }

    /// Search protocols by name or condition
    static func search(_ query: String) -> [TreatmentProtocol] {
        let lowercased = query.lowercased()
        return protocolLibrary.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.condition.rawValue.lowercased().contains(lowercased) ||
            $0.description.lowercased().contains(lowercased)
        }
    }

    /// Get protocols by category
    static func getProtocols(for category: ConditionCategory) -> [TreatmentProtocol] {
        return protocolLibrary.filter { $0.condition.category == category }
    }
}
