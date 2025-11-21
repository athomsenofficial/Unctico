import Foundation
import SwiftUI

/// ICD-10 diagnosis code for massage therapy billing and documentation
struct ICD10Code: Identifiable, Codable, Hashable {
    let id: UUID
    let code: String
    let description: String
    let category: ICD10Category
    let isCommon: Bool
    let synonyms: [String]

    init(
        id: UUID = UUID(),
        code: String,
        description: String,
        category: ICD10Category,
        isCommon: Bool = false,
        synonyms: [String] = []
    ) {
        self.id = id
        self.code = code
        self.description = description
        self.category = category
        self.isCommon = isCommon
        self.synonyms = synonyms
    }

    var displayText: String {
        "\(code) - \(description)"
    }
}

enum ICD10Category: String, Codable, CaseIterable {
    case musculoskeletal = "Musculoskeletal"
    case pain = "Pain"
    case injury = "Injury"
    case neurologicalDisorders = "Neurological"
    case circulatory = "Circulatory"
    case stressRelated = "Stress-Related"
    case postural = "Postural"
    case rehabilitation = "Rehabilitation"
    case other = "Other"

    var icon: String {
        switch self {
        case .musculoskeletal: return "figure.walk"
        case .pain: return "bolt.fill"
        case .injury: return "bandage.fill"
        case .neurologicalDisorders: return "brain.head.profile"
        case .circulatory: return "heart.fill"
        case .stressRelated: return "cloud.fill"
        case .postural: return "figure.stand"
        case .rehabilitation: return "figure.strengthtraining.traditional"
        case .other: return "cross.case.fill"
        }
    }

    var color: Color {
        switch self {
        case .musculoskeletal: return .blue
        case .pain: return .red
        case .injury: return .orange
        case .neurologicalDisorders: return .purple
        case .circulatory: return .pink
        case .stressRelated: return .yellow
        case .postural: return .green
        case .rehabilitation: return .cyan
        case .other: return .gray
        }
    }
}

// MARK: - Common ICD-10 Codes for Massage Therapy

extension ICD10Code {
    /// Most commonly used ICD-10 codes in massage therapy practice
    static let commonMassageTherapyCodes: [ICD10Code] = [
        // Pain Codes (M79.x)
        ICD10Code(
            code: "M79.1",
            description: "Myalgia (Muscle Pain)",
            category: .pain,
            isCommon: true,
            synonyms: ["muscle pain", "muscle ache", "sore muscles"]
        ),
        ICD10Code(
            code: "M79.2",
            description: "Neuralgia and neuritis, unspecified",
            category: .neurologicalDisorders,
            isCommon: true,
            synonyms: ["nerve pain", "neuralgia"]
        ),
        ICD10Code(
            code: "M79.3",
            description: "Panniculitis, unspecified",
            category: .musculoskeletal,
            isCommon: false
        ),
        ICD10Code(
            code: "M79.7",
            description: "Fibromyalgia",
            category: .pain,
            isCommon: true,
            synonyms: ["fibromyalgia syndrome", "FMS"]
        ),

        // Back Pain (M54.x)
        ICD10Code(
            code: "M54.2",
            description: "Cervicalgia (Neck Pain)",
            category: .pain,
            isCommon: true,
            synonyms: ["neck pain", "cervical pain"]
        ),
        ICD10Code(
            code: "M54.5",
            description: "Low Back Pain",
            category: .pain,
            isCommon: true,
            synonyms: ["lower back pain", "lumbar pain", "lumbago"]
        ),
        ICD10Code(
            code: "M54.6",
            description: "Pain in thoracic spine",
            category: .pain,
            isCommon: true,
            synonyms: ["mid back pain", "thoracic pain", "upper back pain"]
        ),
        ICD10Code(
            code: "M54.81",
            description: "Occipital neuralgia",
            category: .neurologicalDisorders,
            isCommon: false
        ),
        ICD10Code(
            code: "M54.89",
            description: "Other dorsalgia (back pain)",
            category: .pain,
            isCommon: true
        ),
        ICD10Code(
            code: "M54.9",
            description: "Dorsalgia, unspecified",
            category: .pain,
            isCommon: true,
            synonyms: ["back pain unspecified"]
        ),

        // Joint Pain (M25.5x)
        ICD10Code(
            code: "M25.50",
            description: "Pain in unspecified joint",
            category: .pain,
            isCommon: true,
            synonyms: ["joint pain", "arthralgia"]
        ),
        ICD10Code(
            code: "M25.511",
            description: "Pain in right shoulder",
            category: .pain,
            isCommon: true,
            synonyms: ["right shoulder pain"]
        ),
        ICD10Code(
            code: "M25.512",
            description: "Pain in left shoulder",
            category: .pain,
            isCommon: true,
            synonyms: ["left shoulder pain"]
        ),
        ICD10Code(
            code: "M25.551",
            description: "Pain in right hip",
            category: .pain,
            isCommon: true
        ),
        ICD10Code(
            code: "M25.552",
            description: "Pain in left hip",
            category: .pain,
            isCommon: true
        ),
        ICD10Code(
            code: "M25.561",
            description: "Pain in right knee",
            category: .pain,
            isCommon: true
        ),
        ICD10Code(
            code: "M25.562",
            description: "Pain in left knee",
            category: .pain,
            isCommon: true
        ),

        // Muscle Tension & Spasm
        ICD10Code(
            code: "M62.830",
            description: "Muscle spasm of back",
            category: .musculoskeletal,
            isCommon: true,
            synonyms: ["back spasm", "muscle spasm"]
        ),
        ICD10Code(
            code: "M62.838",
            description: "Other muscle spasm",
            category: .musculoskeletal,
            isCommon: true
        ),

        // Headaches
        ICD10Code(
            code: "G44.209",
            description: "Tension-type headache, unspecified",
            category: .neurologicalDisorders,
            isCommon: true,
            synonyms: ["tension headache", "stress headache"]
        ),
        ICD10Code(
            code: "G43.909",
            description: "Migraine, unspecified",
            category: .neurologicalDisorders,
            isCommon: true,
            synonyms: ["migraine headache"]
        ),
        ICD10Code(
            code: "R51.9",
            description: "Headache, unspecified",
            category: .pain,
            isCommon: true
        ),

        // Postural Conditions
        ICD10Code(
            code: "M43.6",
            description: "Torticollis",
            category: .postural,
            isCommon: false,
            synonyms: ["wry neck", "stiff neck"]
        ),
        ICD10Code(
            code: "M54.2",
            description: "Cervicalgia",
            category: .postural,
            isCommon: true
        ),

        // Sports Injuries
        ICD10Code(
            code: "S46.911A",
            description: "Strain of unspecified muscle, fascia and tendon at shoulder and upper arm level, right arm, initial encounter",
            category: .injury,
            isCommon: false
        ),
        ICD10Code(
            code: "S46.912A",
            description: "Strain of unspecified muscle, fascia and tendon at shoulder and upper arm level, left arm, initial encounter",
            category: .injury,
            isCommon: false
        ),
        ICD10Code(
            code: "S83.511A",
            description: "Sprain of anterior cruciate ligament of right knee, initial encounter",
            category: .injury,
            isCommon: false
        ),

        // Sciatica
        ICD10Code(
            code: "M54.30",
            description: "Sciatica, unspecified side",
            category: .neurologicalDisorders,
            isCommon: true,
            synonyms: ["sciatica"]
        ),
        ICD10Code(
            code: "M54.31",
            description: "Sciatica, right side",
            category: .neurologicalDisorders,
            isCommon: true
        ),
        ICD10Code(
            code: "M54.32",
            description: "Sciatica, left side",
            category: .neurologicalDisorders,
            isCommon: true
        ),

        // Arthritis
        ICD10Code(
            code: "M19.90",
            description: "Unspecified osteoarthritis, unspecified site",
            category: .musculoskeletal,
            isCommon: true,
            synonyms: ["osteoarthritis", "arthritis"]
        ),
        ICD10Code(
            code: "M06.9",
            description: "Rheumatoid arthritis, unspecified",
            category: .musculoskeletal,
            isCommon: false
        ),

        // Stress & Anxiety
        ICD10Code(
            code: "F41.9",
            description: "Anxiety disorder, unspecified",
            category: .stressRelated,
            isCommon: true,
            synonyms: ["anxiety", "stress"]
        ),
        ICD10Code(
            code: "Z73.3",
            description: "Stress, not elsewhere classified",
            category: .stressRelated,
            isCommon: true
        ),

        // Range of Motion
        ICD10Code(
            code: "M25.50",
            description: "Pain in unspecified joint",
            category: .musculoskeletal,
            isCommon: true
        ),
        ICD10Code(
            code: "M25.60",
            description: "Stiffness of unspecified joint, not elsewhere classified",
            category: .musculoskeletal,
            isCommon: true,
            synonyms: ["joint stiffness", "limited range of motion"]
        ),

        // Post-surgical
        ICD10Code(
            code: "Z98.89",
            description: "Other specified postprocedural states",
            category: .rehabilitation,
            isCommon: false,
            synonyms: ["post-surgical", "post-op"]
        ),

        // Repetitive Strain
        ICD10Code(
            code: "M70.90",
            description: "Unspecified soft tissue disorder related to use, overuse and pressure of unspecified site",
            category: .injury,
            isCommon: true,
            synonyms: ["repetitive strain", "overuse injury"]
        ),

        // Carpal Tunnel
        ICD10Code(
            code: "G56.00",
            description: "Carpal tunnel syndrome, unspecified upper limb",
            category: .neurologicalDisorders,
            isCommon: true,
            synonyms: ["carpal tunnel"]
        ),

        // TMJ
        ICD10Code(
            code: "M26.60",
            description: "Temporomandibular joint disorder, unspecified",
            category: .musculoskeletal,
            isCommon: true,
            synonyms: ["TMJ", "jaw pain"]
        ),

        // Pregnancy-related
        ICD10Code(
            code: "O26.899",
            description: "Other specified pregnancy related conditions",
            category: .other,
            isCommon: false,
            synonyms: ["pregnancy discomfort"]
        ),

        // General Wellness
        ICD10Code(
            code: "Z00.00",
            description: "Encounter for general adult medical examination without abnormal findings",
            category: .other,
            isCommon: true,
            synonyms: ["wellness", "preventive care"]
        ),

        // Whiplash
        ICD10Code(
            code: "S13.4XXA",
            description: "Sprain of ligaments of cervical spine, initial encounter",
            category: .injury,
            isCommon: false,
            synonyms: ["whiplash"]
        ),

        // Plantar Fasciitis
        ICD10Code(
            code: "M72.2",
            description: "Plantar fascial fibromatosis",
            category: .musculoskeletal,
            isCommon: true,
            synonyms: ["plantar fasciitis", "heel pain"]
        ),

        // Frozen Shoulder
        ICD10Code(
            code: "M75.00",
            description: "Adhesive capsulitis of unspecified shoulder",
            category: .musculoskeletal,
            isCommon: true,
            synonyms: ["frozen shoulder", "adhesive capsulitis"]
        ),

        // Rotator Cuff
        ICD10Code(
            code: "M75.100",
            description: "Unspecified rotator cuff tear or rupture of unspecified shoulder, not specified as traumatic",
            category: .injury,
            isCommon: false,
            synonyms: ["rotator cuff injury"]
        ),

        // Tendonitis
        ICD10Code(
            code: "M76.899",
            description: "Other specified enthesopathies of unspecified lower limb",
            category: .musculoskeletal,
            isCommon: true,
            synonyms: ["tendonitis", "tendinitis"]
        ),

        // Scoliosis
        ICD10Code(
            code: "M41.9",
            description: "Scoliosis, unspecified",
            category: .postural,
            isCommon: false
        )
    ]

    /// Search ICD-10 codes by keyword
    static func search(_ query: String) -> [ICD10Code] {
        guard !query.isEmpty else { return commonMassageTherapyCodes }

        let lowercaseQuery = query.lowercased()

        return commonMassageTherapyCodes.filter { code in
            code.code.lowercased().contains(lowercaseQuery) ||
            code.description.lowercased().contains(lowercaseQuery) ||
            code.synonyms.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }

    /// Get codes by category
    static func byCategory(_ category: ICD10Category) -> [ICD10Code] {
        commonMassageTherapyCodes.filter { $0.category == category }
    }

    /// Get only commonly used codes
    static var commonCodes: [ICD10Code] {
        commonMassageTherapyCodes.filter { $0.isCommon }
    }
}
