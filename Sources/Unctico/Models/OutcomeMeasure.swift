import Foundation

/// Standardized outcome measurement tools for tracking treatment efficacy
struct OutcomeMeasure: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    let measureType: MeasureType
    let administeredDate: Date
    var responses: [String: Int] // Question ID to score
    var totalScore: Int
    var interpretation: String
    var notes: String?

    init(
        id: UUID = UUID(),
        clientId: UUID,
        measureType: MeasureType,
        administeredDate: Date = Date(),
        responses: [String: Int] = [:],
        totalScore: Int = 0,
        interpretation: String = "",
        notes: String? = nil
    ) {
        self.id = id
        self.clientId = clientId
        self.measureType = measureType
        self.administeredDate = administeredDate
        self.responses = responses
        self.totalScore = totalScore
        self.interpretation = interpretation
        self.notes = notes
    }

    /// Calculate score based on responses
    mutating func calculateScore() {
        let scale = OutcomeScale.getScale(for: measureType)
        totalScore = responses.values.reduce(0, +)
        interpretation = scale.interpretScore(totalScore)
    }
}

// MARK: - Measure Types

enum MeasureType: String, Codable, CaseIterable {
    // Pain & Disability Scales
    case ndi = "Neck Disability Index (NDI)"
    case odi = "Oswestry Disability Index (ODI)"
    case dash = "DASH - Disability of Arm, Shoulder & Hand"
    case lefs = "Lower Extremity Functional Scale (LEFS)"
    case psfs = "Patient-Specific Functional Scale (PSFS)"

    // Pain Scales
    case vas = "Visual Analog Scale (VAS)"
    case nprs = "Numeric Pain Rating Scale (NPRS)"
    case mcgillPain = "McGill Pain Questionnaire (Short Form)"
    case painDiagram = "Pain Diagram"

    // Quality of Life
    case sf36 = "SF-36 Health Survey"
    case eq5d = "EQ-5D Quality of Life"

    // Mental Health & Stress
    case dass21 = "DASS-21 (Depression, Anxiety, Stress)"
    case pss = "Perceived Stress Scale (PSS-10)"
    case gad7 = "GAD-7 Anxiety"
    case phq9 = "PHQ-9 Depression"

    // Sleep
    case isi = "Insomnia Severity Index (ISI)"
    case psqi = "Pittsburgh Sleep Quality Index"

    // Treatment Satisfaction
    case groc = "Global Rating of Change (GROC)"
    case csi = "Client Satisfaction Index"
    case nps = "Net Promoter Score"

    var category: MeasureCategory {
        switch self {
        case .ndi, .odi, .dash, .lefs, .psfs:
            return .painDisability
        case .vas, .nprs, .mcgillPain, .painDiagram:
            return .pain
        case .sf36, .eq5d:
            return .qualityOfLife
        case .dass21, .pss, .gad7, .phq9:
            return .mentalHealth
        case .isi, .psqi:
            return .sleep
        case .groc, .csi, .nps:
            return .satisfaction
        }
    }

    var icon: String {
        switch category {
        case .painDisability: return "figure.walk.motion"
        case .pain: return "bolt.heart.fill"
        case .qualityOfLife: return "heart.fill"
        case .mentalHealth: return "brain.head.profile"
        case .sleep: return "bed.double.fill"
        case .satisfaction: return "star.fill"
        }
    }

    var description: String {
        switch self {
        case .ndi:
            return "Assesses neck pain and related disability. 10 items, each scored 0-5. Higher scores indicate greater disability."
        case .odi:
            return "Measures low back pain disability. 10 sections, each scored 0-5. Assesses impact on daily activities."
        case .dash:
            return "Evaluates upper extremity function and symptoms. 30 items measuring difficulty with daily tasks."
        case .lefs:
            return "Assesses lower extremity function. 20 items measuring difficulty with functional activities."
        case .psfs:
            return "Patient identifies 3-5 activities limited by condition and rates difficulty. Personalized to individual."
        case .vas:
            return "Visual line from 'no pain' to 'worst pain imaginable'. Client marks level. Simple, quick assessment."
        case .nprs:
            return "0-10 numeric scale for pain intensity. 0 = no pain, 10 = worst pain. Widely used and validated."
        case .mcgillPain:
            return "Assesses sensory and affective dimensions of pain. 15 descriptors rated on intensity."
        case .painDiagram:
            return "Body diagram where client marks pain locations. Can indicate type (sharp, dull, burning, etc.)."
        case .sf36:
            return "Comprehensive health survey. 36 items across 8 domains: physical function, pain, general health, etc."
        case .eq5d:
            return "Quality of life measure. 5 dimensions: mobility, self-care, activities, pain, anxiety/depression."
        case .dass21:
            return "Assesses depression, anxiety, and stress. 21 items, 7 per scale. Identifies emotional states."
        case .pss:
            return "Measures perceived stress. 10 items about feelings and thoughts during past month."
        case .gad7:
            return "Screens for generalized anxiety. 7 items scored 0-3. Quick, validated tool."
        case .phq9:
            return "Screens for depression. 9 items matching DSM-5 criteria. Widely used in healthcare."
        case .isi:
            return "Assesses insomnia severity. 7 items about sleep difficulties and their impact."
        case .psqi:
            return "Measures sleep quality over past month. 19 items across 7 components."
        case .groc:
            return "Single-item scale asking 'How much has your condition changed?' from -7 (much worse) to +7 (much better)."
        case .csi:
            return "Measures client satisfaction with treatment. Multiple items assessing various aspects of care."
        case .nps:
            return "Single question: 'How likely are you to recommend our practice?' Scored 0-10."
        }
    }
}

enum MeasureCategory: String, Codable, CaseIterable {
    case painDisability = "Pain & Disability"
    case pain = "Pain Assessment"
    case qualityOfLife = "Quality of Life"
    case mentalHealth = "Mental Health"
    case sleep = "Sleep"
    case satisfaction = "Satisfaction"

    var icon: String {
        switch self {
        case .painDisability: return "figure.walk"
        case .pain: return "bolt.heart.fill"
        case .qualityOfLife: return "heart.fill"
        case .mentalHealth: return "brain.head.profile"
        case .sleep: return "bed.double.fill"
        case .satisfaction: return "star.fill"
        }
    }
}

// MARK: - Outcome Scales

struct OutcomeScale {
    let measureType: MeasureType
    let questions: [OutcomeQuestion]
    let scoringInstructions: String
    let interpretationGuidelines: [ScoreInterpretation]

    static func getScale(for type: MeasureType) -> OutcomeScale {
        switch type {
        case .ndi:
            return neckDisabilityIndex
        case .odi:
            return oswestryDisabilityIndex
        case .psfs:
            return patientSpecificFunctionalScale
        case .nprs:
            return numericPainRatingScale
        case .groc:
            return globalRatingOfChange
        case .gad7:
            return gad7Scale
        case .pss:
            return perceivedStressScale
        default:
            return defaultScale(for: type)
        }
    }

    func interpretScore(_ score: Int) -> String {
        for interpretation in interpretationGuidelines.sorted(by: { $0.minScore > $1.minScore }) {
            if score >= interpretation.minScore {
                return interpretation.interpretation
            }
        }
        return "Score out of range"
    }

    // MARK: - Neck Disability Index

    static let neckDisabilityIndex = OutcomeScale(
        measureType: .ndi,
        questions: [
            OutcomeQuestion(
                id: "ndi1",
                text: "Pain Intensity",
                options: [
                    "I have no pain at the moment",
                    "The pain is very mild at the moment",
                    "The pain is moderate at the moment",
                    "The pain is fairly severe at the moment",
                    "The pain is very severe at the moment",
                    "The pain is the worst imaginable at the moment"
                ]
            ),
            OutcomeQuestion(
                id: "ndi2",
                text: "Personal Care (washing, dressing, etc.)",
                options: [
                    "I can look after myself normally without causing extra pain",
                    "I can look after myself normally but it causes extra pain",
                    "It is painful to look after myself and I am slow and careful",
                    "I need some help but manage most of my personal care",
                    "I need help every day in most aspects of self care",
                    "I do not get dressed, wash with difficulty, and stay in bed"
                ]
            ),
            OutcomeQuestion(
                id: "ndi3",
                text: "Lifting",
                options: [
                    "I can lift heavy weights without extra pain",
                    "I can lift heavy weights but it gives extra pain",
                    "Pain prevents me from lifting heavy weights off the floor, but I can manage if they are conveniently positioned",
                    "Pain prevents me from lifting heavy weights, but I can manage light to medium weights if they are conveniently positioned",
                    "I can lift very light weights",
                    "I cannot lift or carry anything at all"
                ]
            ),
            OutcomeQuestion(
                id: "ndi4",
                text: "Reading",
                options: [
                    "I can read as much as I want with no pain in my neck",
                    "I can read as much as I want with slight pain in my neck",
                    "I can read as much as I want with moderate pain in my neck",
                    "I cannot read as much as I want because of moderate pain in my neck",
                    "I can hardly read at all because of severe pain in my neck",
                    "I cannot read at all"
                ]
            ),
            OutcomeQuestion(
                id: "ndi5",
                text: "Headaches",
                options: [
                    "I have no headaches at all",
                    "I have slight headaches which come infrequently",
                    "I have moderate headaches which come infrequently",
                    "I have moderate headaches which come frequently",
                    "I have severe headaches which come frequently",
                    "I have headaches almost all the time"
                ]
            ),
            OutcomeQuestion(
                id: "ndi6",
                text: "Concentration",
                options: [
                    "I can concentrate fully when I want with no difficulty",
                    "I can concentrate fully when I want with slight difficulty",
                    "I have a fair degree of difficulty concentrating when I want",
                    "I have a lot of difficulty concentrating when I want",
                    "I have a great deal of difficulty concentrating when I want",
                    "I cannot concentrate at all"
                ]
            ),
            OutcomeQuestion(
                id: "ndi7",
                text: "Work",
                options: [
                    "I can do as much work as I want",
                    "I can only do my usual work but no more",
                    "I can do most of my usual work but no more",
                    "I cannot do my usual work",
                    "I can hardly do any work at all",
                    "I cannot do any work at all"
                ]
            ),
            OutcomeQuestion(
                id: "ndi8",
                text: "Driving",
                options: [
                    "I can drive my car without any neck pain",
                    "I can drive my car as long as I want with slight pain in my neck",
                    "I can drive my car as long as I want with moderate pain in my neck",
                    "I cannot drive my car as long as I want because of moderate pain in my neck",
                    "I can hardly drive at all because of severe pain in my neck",
                    "I cannot drive my car at all"
                ]
            ),
            OutcomeQuestion(
                id: "ndi9",
                text: "Sleeping",
                options: [
                    "I have no trouble sleeping",
                    "My sleep is slightly disturbed (less than 1 hour sleepless)",
                    "My sleep is mildly disturbed (1-2 hours sleepless)",
                    "My sleep is moderately disturbed (2-3 hours sleepless)",
                    "My sleep is greatly disturbed (3-5 hours sleepless)",
                    "My sleep is completely disturbed (5-7 hours sleepless)"
                ]
            ),
            OutcomeQuestion(
                id: "ndi10",
                text: "Recreation",
                options: [
                    "I am able to engage in all my recreation activities with no neck pain at all",
                    "I am able to engage in all my recreation activities with some pain in my neck",
                    "I am able to engage in most but not all of my usual recreation activities because of pain in my neck",
                    "I am able to engage in a few of my usual recreation activities because of pain in my neck",
                    "I can hardly do any recreation activities because of pain in my neck",
                    "I cannot do any recreation activities at all"
                ]
            )
        ],
        scoringInstructions: "Each section scored 0-5 with first option = 0 and last option = 5. Total score = sum of all 10 sections. Maximum score = 50.",
        interpretationGuidelines: [
            ScoreInterpretation(minScore: 0, maxScore: 4, interpretation: "No Disability", severity: .none),
            ScoreInterpretation(minScore: 5, maxScore: 14, interpretation: "Mild Disability", severity: .mild),
            ScoreInterpretation(minScore: 15, maxScore: 24, interpretation: "Moderate Disability", severity: .moderate),
            ScoreInterpretation(minScore: 25, maxScore: 34, interpretation: "Severe Disability", severity: .severe),
            ScoreInterpretation(minScore: 35, maxScore: 50, interpretation: "Complete Disability", severity: .complete)
        ]
    )

    // MARK: - Oswestry Disability Index

    static let oswestryDisabilityIndex = OutcomeScale(
        measureType: .odi,
        questions: [
            OutcomeQuestion(
                id: "odi1",
                text: "Pain Intensity",
                options: [
                    "I have no pain at the moment",
                    "The pain is very mild at the moment",
                    "The pain is moderate at the moment",
                    "The pain is fairly severe at the moment",
                    "The pain is very severe at the moment",
                    "The pain is the worst imaginable at the moment"
                ]
            ),
            OutcomeQuestion(
                id: "odi2",
                text: "Personal Care (washing, dressing, etc.)",
                options: [
                    "I can look after myself normally without causing extra pain",
                    "I can look after myself normally but it causes extra pain",
                    "It is painful to look after myself and I am slow and careful",
                    "I need some help but manage most of my personal care",
                    "I need help every day in most aspects of self care",
                    "I do not get dressed, I wash with difficulty and stay in bed"
                ]
            ),
            OutcomeQuestion(
                id: "odi3",
                text: "Lifting",
                options: [
                    "I can lift heavy weights without extra pain",
                    "I can lift heavy weights but it gives extra pain",
                    "Pain prevents me from lifting heavy weights off the floor, but I can manage if they are conveniently placed",
                    "Pain prevents me from lifting heavy weights, but I can manage light to medium weights if conveniently positioned",
                    "I can only lift very light weights",
                    "I cannot lift or carry anything at all"
                ]
            ),
            OutcomeQuestion(
                id: "odi4",
                text: "Walking",
                options: [
                    "Pain does not prevent me walking any distance",
                    "Pain prevents me from walking more than 1 mile",
                    "Pain prevents me from walking more than 1/2 mile",
                    "Pain prevents me from walking more than 100 yards",
                    "I can only walk using a stick or crutches",
                    "I am in bed most of the time"
                ]
            ),
            OutcomeQuestion(
                id: "odi5",
                text: "Sitting",
                options: [
                    "I can sit in any chair as long as I like",
                    "I can only sit in my favorite chair as long as I like",
                    "Pain prevents me sitting more than one hour",
                    "Pain prevents me from sitting more than 30 minutes",
                    "Pain prevents me from sitting more than 10 minutes",
                    "Pain prevents me from sitting at all"
                ]
            ),
            OutcomeQuestion(
                id: "odi6",
                text: "Standing",
                options: [
                    "I can stand as long as I want without extra pain",
                    "I can stand as long as I want but it gives me extra pain",
                    "Pain prevents me from standing for more than 1 hour",
                    "Pain prevents me from standing for more than 30 minutes",
                    "Pain prevents me from standing for more than 10 minutes",
                    "Pain prevents me from standing at all"
                ]
            ),
            OutcomeQuestion(
                id: "odi7",
                text: "Sleeping",
                options: [
                    "My sleep is never disturbed by pain",
                    "My sleep is occasionally disturbed by pain",
                    "Because of pain I have less than 6 hours sleep",
                    "Because of pain I have less than 4 hours sleep",
                    "Because of pain I have less than 2 hours sleep",
                    "Pain prevents me from sleeping at all"
                ]
            ),
            OutcomeQuestion(
                id: "odi8",
                text: "Sex Life (if applicable)",
                options: [
                    "My sex life is normal and causes no extra pain",
                    "My sex life is normal but causes some extra pain",
                    "My sex life is nearly normal but is very painful",
                    "My sex life is severely restricted by pain",
                    "My sex life is nearly absent because of pain",
                    "Pain prevents any sex life at all"
                ]
            ),
            OutcomeQuestion(
                id: "odi9",
                text: "Social Life",
                options: [
                    "My social life is normal and gives me no extra pain",
                    "My social life is normal but increases the degree of pain",
                    "Pain has no significant effect on my social life apart from limiting my more energetic interests",
                    "Pain has restricted my social life and I do not go out as often",
                    "Pain has restricted my social life to my home",
                    "I have no social life because of pain"
                ]
            ),
            OutcomeQuestion(
                id: "odi10",
                text: "Traveling",
                options: [
                    "I can travel anywhere without pain",
                    "I can travel anywhere but it gives me extra pain",
                    "Pain is bad but I manage journeys over two hours",
                    "Pain restricts me to journeys of less than one hour",
                    "Pain restricts me to short necessary journeys under 30 minutes",
                    "Pain prevents me from traveling except to receive treatment"
                ]
            )
        ],
        scoringInstructions: "Each section scored 0-5. Total score = sum/50 × 100 to get percentage disability.",
        interpretationGuidelines: [
            ScoreInterpretation(minScore: 0, maxScore: 20, interpretation: "Minimal Disability", severity: .mild),
            ScoreInterpretation(minScore: 21, maxScore: 40, interpretation: "Moderate Disability", severity: .moderate),
            ScoreInterpretation(minScore: 41, maxScore: 60, interpretation: "Severe Disability", severity: .severe),
            ScoreInterpretation(minScore: 61, maxScore: 80, interpretation: "Crippling Back Pain", severity: .severe),
            ScoreInterpretation(minScore: 81, maxScore: 100, interpretation: "Bed-bound or Exaggerating", severity: .complete)
        ]
    )

    // MARK: - Patient-Specific Functional Scale

    static let patientSpecificFunctionalScale = OutcomeScale(
        measureType: .psfs,
        questions: [
            OutcomeQuestion(
                id: "psfs_instructions",
                text: "Identify up to 5 important activities that you are unable to do or have difficulty doing because of your problem. Rate your ability to perform each activity on a scale of 0-10 (0 = unable to perform, 10 = able to perform at prior level).",
                options: []
            )
        ],
        scoringInstructions: "Client identifies 3-5 activities. Each rated 0-10. Average all scores for total. Higher = better function.",
        interpretationGuidelines: [
            ScoreInterpretation(minScore: 0, maxScore: 3, interpretation: "Severe Limitation", severity: .severe),
            ScoreInterpretation(minScore: 4, maxScore: 6, interpretation: "Moderate Limitation", severity: .moderate),
            ScoreInterpretation(minScore: 7, maxScore: 9, interpretation: "Mild Limitation", severity: .mild),
            ScoreInterpretation(minScore: 10, maxScore: 10, interpretation: "No Limitation", severity: .none)
        ]
    )

    // MARK: - Numeric Pain Rating Scale

    static let numericPainRatingScale = OutcomeScale(
        measureType: .nprs,
        questions: [
            OutcomeQuestion(
                id: "nprs_current",
                text: "On a scale of 0-10, how would you rate your pain RIGHT NOW?",
                options: Array(0...10).map { "\($0)" }
            ),
            OutcomeQuestion(
                id: "nprs_best",
                text: "On a scale of 0-10, what is your pain level at its BEST (least pain)?",
                options: Array(0...10).map { "\($0)" }
            ),
            OutcomeQuestion(
                id: "nprs_worst",
                text: "On a scale of 0-10, what is your pain level at its WORST (most pain)?",
                options: Array(0...10).map { "\($0)" }
            ),
            OutcomeQuestion(
                id: "nprs_average",
                text: "On a scale of 0-10, what is your AVERAGE pain level?",
                options: Array(0...10).map { "\($0)" }
            )
        ],
        scoringInstructions: "0 = No Pain, 10 = Worst Pain Imaginable. Record each rating separately or calculate average.",
        interpretationGuidelines: [
            ScoreInterpretation(minScore: 0, maxScore: 0, interpretation: "No Pain", severity: .none),
            ScoreInterpretation(minScore: 1, maxScore: 3, interpretation: "Mild Pain", severity: .mild),
            ScoreInterpretation(minScore: 4, maxScore: 6, interpretation: "Moderate Pain", severity: .moderate),
            ScoreInterpretation(minScore: 7, maxScore: 10, interpretation: "Severe Pain", severity: .severe)
        ]
    )

    // MARK: - Global Rating of Change

    static let globalRatingOfChange = OutcomeScale(
        measureType: .groc,
        questions: [
            OutcomeQuestion(
                id: "groc",
                text: "Compared to when you first started treatment, how would you describe your condition now?",
                options: [
                    "A very great deal worse",
                    "A great deal worse",
                    "Quite a bit worse",
                    "Somewhat worse",
                    "A little bit worse",
                    "Almost the same / Hardly any change",
                    "A little bit better",
                    "Somewhat better",
                    "Quite a bit better",
                    "A great deal better",
                    "A very great deal better"
                ]
            )
        ],
        scoringInstructions: "Single rating from -5 (much worse) to +5 (much better). 0 = no change. ±2 or greater considered clinically meaningful.",
        interpretationGuidelines: [
            ScoreInterpretation(minScore: -5, maxScore: -3, interpretation: "Much Worse", severity: .severe),
            ScoreInterpretation(minScore: -2, maxScore: -1, interpretation: "Somewhat Worse", severity: .moderate),
            ScoreInterpretation(minScore: 0, maxScore: 0, interpretation: "No Change", severity: .mild),
            ScoreInterpretation(minScore: 1, maxScore: 2, interpretation: "Somewhat Better", severity: .mild),
            ScoreInterpretation(minScore: 3, maxScore: 5, interpretation: "Much Better", severity: .none)
        ]
    )

    // MARK: - GAD-7

    static let gad7Scale = OutcomeScale(
        measureType: .gad7,
        questions: [
            OutcomeQuestion(
                id: "gad1",
                text: "Feeling nervous, anxious, or on edge",
                options: ["Not at all", "Several days", "More than half the days", "Nearly every day"]
            ),
            OutcomeQuestion(
                id: "gad2",
                text: "Not being able to stop or control worrying",
                options: ["Not at all", "Several days", "More than half the days", "Nearly every day"]
            ),
            OutcomeQuestion(
                id: "gad3",
                text: "Worrying too much about different things",
                options: ["Not at all", "Several days", "More than half the days", "Nearly every day"]
            ),
            OutcomeQuestion(
                id: "gad4",
                text: "Trouble relaxing",
                options: ["Not at all", "Several days", "More than half the days", "Nearly every day"]
            ),
            OutcomeQuestion(
                id: "gad5",
                text: "Being so restless that it's hard to sit still",
                options: ["Not at all", "Several days", "More than half the days", "Nearly every day"]
            ),
            OutcomeQuestion(
                id: "gad6",
                text: "Becoming easily annoyed or irritable",
                options: ["Not at all", "Several days", "More than half the days", "Nearly every day"]
            ),
            OutcomeQuestion(
                id: "gad7",
                text: "Feeling afraid as if something awful might happen",
                options: ["Not at all", "Several days", "More than half the days", "Nearly every day"]
            )
        ],
        scoringInstructions: "Over the past 2 weeks, how often have you been bothered by the following? Each item scored 0-3. Total = 0-21.",
        interpretationGuidelines: [
            ScoreInterpretation(minScore: 0, maxScore: 4, interpretation: "Minimal Anxiety", severity: .none),
            ScoreInterpretation(minScore: 5, maxScore: 9, interpretation: "Mild Anxiety", severity: .mild),
            ScoreInterpretation(minScore: 10, maxScore: 14, interpretation: "Moderate Anxiety", severity: .moderate),
            ScoreInterpretation(minScore: 15, maxScore: 21, interpretation: "Severe Anxiety", severity: .severe)
        ]
    )

    // MARK: - Perceived Stress Scale

    static let perceivedStressScale = OutcomeScale(
        measureType: .pss,
        questions: [
            OutcomeQuestion(
                id: "pss1",
                text: "Been upset because of something that happened unexpectedly?",
                options: ["Never", "Almost Never", "Sometimes", "Fairly Often", "Very Often"]
            ),
            OutcomeQuestion(
                id: "pss2",
                text: "Felt that you were unable to control the important things in your life?",
                options: ["Never", "Almost Never", "Sometimes", "Fairly Often", "Very Often"]
            ),
            OutcomeQuestion(
                id: "pss3",
                text: "Felt nervous and stressed?",
                options: ["Never", "Almost Never", "Sometimes", "Fairly Often", "Very Often"]
            ),
            OutcomeQuestion(
                id: "pss4",
                text: "Felt confident about your ability to handle your personal problems?",
                options: ["Never", "Almost Never", "Sometimes", "Fairly Often", "Very Often"]
            ),
            OutcomeQuestion(
                id: "pss5",
                text: "Felt that things were going your way?",
                options: ["Never", "Almost Never", "Sometimes", "Fairly Often", "Very Often"]
            ),
            OutcomeQuestion(
                id: "pss6",
                text: "Found that you could not cope with all the things that you had to do?",
                options: ["Never", "Almost Never", "Sometimes", "Fairly Often", "Very Often"]
            ),
            OutcomeQuestion(
                id: "pss7",
                text: "Been able to control irritations in your life?",
                options: ["Never", "Almost Never", "Sometimes", "Fairly Often", "Very Often"]
            ),
            OutcomeQuestion(
                id: "pss8",
                text: "Felt that you were on top of things?",
                options: ["Never", "Almost Never", "Sometimes", "Fairly Often", "Very Often"]
            ),
            OutcomeQuestion(
                id: "pss9",
                text: "Been angered because of things that were outside of your control?",
                options: ["Never", "Almost Never", "Sometimes", "Fairly Often", "Very Often"]
            ),
            OutcomeQuestion(
                id: "pss10",
                text: "Felt difficulties were piling up so high that you could not overcome them?",
                options: ["Never", "Almost Never", "Sometimes", "Fairly Often", "Very Often"]
            )
        ],
        scoringInstructions: "In the past month, how often have you... Items 4,5,7,8 are reverse scored. Total = 0-40. Higher = more stress.",
        interpretationGuidelines: [
            ScoreInterpretation(minScore: 0, maxScore: 13, interpretation: "Low Stress", severity: .none),
            ScoreInterpretation(minScore: 14, maxScore: 26, interpretation: "Moderate Stress", severity: .moderate),
            ScoreInterpretation(minScore: 27, maxScore: 40, interpretation: "High Perceived Stress", severity: .severe)
        ]
    )

    static func defaultScale(for type: MeasureType) -> OutcomeScale {
        OutcomeScale(
            measureType: type,
            questions: [],
            scoringInstructions: "Refer to standardized administration instructions",
            interpretationGuidelines: []
        )
    }
}

// MARK: - Supporting Models

struct OutcomeQuestion: Identifiable, Codable {
    let id: String
    let text: String
    let options: [String]
}

struct ScoreInterpretation: Codable {
    let minScore: Int
    let maxScore: Int
    let interpretation: String
    let severity: Severity

    enum Severity: String, Codable {
        case none = "None"
        case mild = "Mild"
        case moderate = "Moderate"
        case severe = "Severe"
        case complete = "Complete"

        var color: String {
            switch self {
            case .none: return "green"
            case .mild: return "blue"
            case .moderate: return "yellow"
            case .severe: return "orange"
            case .complete: return "red"
            }
        }
    }
}
