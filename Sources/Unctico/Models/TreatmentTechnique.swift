import Foundation
import SwiftUI

/// Detailed treatment technique documentation for clinical records
struct TreatmentTechniqueRecord: Identifiable, Codable {
    let id: UUID
    let sessionId: UUID
    let technique: Technique
    let bodyAreas: [BodyLocation]
    let duration: TimeInterval // in seconds
    let pressure: PressureLevel
    let modalities: [Modality]
    let clientResponse: ClientResponse
    let notes: String
    let timestamp: Date

    init(
        id: UUID = UUID(),
        sessionId: UUID,
        technique: Technique,
        bodyAreas: [BodyLocation],
        duration: TimeInterval,
        pressure: PressureLevel,
        modalities: [Modality] = [],
        clientResponse: ClientResponse,
        notes: String = "",
        timestamp: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.technique = technique
        self.bodyAreas = bodyAreas
        self.duration = duration
        self.pressure = pressure
        self.modalities = modalities
        self.clientResponse = clientResponse
        self.notes = notes
        self.timestamp = timestamp
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
    }
}

enum Technique: String, Codable, CaseIterable {
    // Swedish Massage
    case effleurage = "Effleurage (Gliding Strokes)"
    case petrissage = "Petrissage (Kneading)"
    case tapotement = "Tapotement (Percussion)"
    case friction = "Friction"
    case vibration = "Vibration"

    // Deep Tissue
    case deepTissue = "Deep Tissue"
    case stripping = "Stripping"
    case crossFiberFriction = "Cross-Fiber Friction"

    // Trigger Point Therapy
    case triggerPointTherapy = "Trigger Point Therapy"
    case ischemicCompression = "Ischemic Compression"
    case pinAndStretch = "Pin and Stretch"

    // Myofascial Techniques
    case myofascialRelease = "Myofascial Release"
    case skinRolling = "Skin Rolling"
    case fascialStretching = "Fascial Stretching"

    // Stretching
    case passiveStretching = "Passive Stretching"
    case activeAssistedStretching = "Active Assisted Stretching"
    case proprioceptiveNeuromuscularFacilitation = "PNF Stretching"

    // Joint Mobilization
    case jointMobilization = "Joint Mobilization"
    case rangeOfMotion = "Range of Motion"

    // Sports Massage
    case compressionStrokes = "Compression Strokes"
    case jostling = "Jostling"
    case broadening = "Broadening Strokes"

    // Lymphatic
    case manualLymphDrainage = "Manual Lymph Drainage"
    case lymphaticDrainage = "Lymphatic Drainage"

    // Energy Work
    case reiki = "Reiki"
    case craniosacral = "Craniosacral Therapy"
    case polarityTherapy = "Polarity Therapy"

    // Reflexology
    case footReflexology = "Foot Reflexology"
    case handReflexology = "Hand Reflexology"

    // Asian Techniques
    case shiatsu = "Shiatsu"
    case thaiMassage = "Thai Massage"
    case acupressure = "Acupressure"
    case tuiNa = "Tui Na"

    var category: TechniqueCategory {
        switch self {
        case .effleurage, .petrissage, .tapotement, .friction, .vibration:
            return .swedish
        case .deepTissue, .stripping, .crossFiberFriction:
            return .deepTissue
        case .triggerPointTherapy, .ischemicCompression, .pinAndStretch:
            return .triggerPoint
        case .myofascialRelease, .skinRolling, .fascialStretching:
            return .myofascial
        case .passiveStretching, .activeAssistedStretching, .proprioceptiveNeuromuscularFacilitation:
            return .stretching
        case .jointMobilization, .rangeOfMotion:
            return .jointWork
        case .compressionStrokes, .jostling, .broadening:
            return .sports
        case .manualLymphDrainage, .lymphaticDrainage:
            return .lymphatic
        case .reiki, .craniosacral, .polarityTherapy:
            return .energy
        case .footReflexology, .handReflexology:
            return .reflexology
        case .shiatsu, .thaiMassage, .acupressure, .tuiNa:
            return .asian
        }
    }

    var icon: String {
        switch category {
        case .swedish: return "hand.raised.fill"
        case .deepTissue: return "flame.fill"
        case .triggerPoint: return "circle.fill"
        case .myofascial: return "waveform.path"
        case .stretching: return "arrow.up.and.down"
        case .jointWork: return "arrow.trianglehead.2.clockwise"
        case .sports: return "figure.run"
        case .lymphatic: return "drop.fill"
        case .energy: return "sparkles"
        case .reflexology: return "hand.thumbsup.fill"
        case .asian: return "hand.point.up.left.fill"
        }
    }

    var description: String {
        switch self {
        case .effleurage:
            return "Long, gliding strokes that warm up muscles and increase circulation"
        case .petrissage:
            return "Kneading movements that lift and squeeze muscles to release tension"
        case .tapotement:
            return "Rhythmic percussion strokes that stimulate and invigorate"
        case .friction:
            return "Deep circular movements that break down adhesions"
        case .vibration:
            return "Fine or coarse shaking movements that relax muscles"
        case .deepTissue:
            return "Slow, deep pressure targeting deeper muscle layers and fascia"
        case .stripping:
            return "Deep longitudinal pressure along muscle fibers"
        case .crossFiberFriction:
            return "Deep pressure across muscle fibers to break down scar tissue"
        case .triggerPointTherapy:
            return "Sustained pressure on trigger points to release referred pain"
        case .ischemicCompression:
            return "Direct pressure on trigger points to release muscle tension"
        case .pinAndStretch:
            return "Holding trigger point while stretching the muscle"
        case .myofascialRelease:
            return "Sustained pressure and stretch to release fascial restrictions"
        case .skinRolling:
            return "Lifting and rolling skin to release fascial adhesions"
        case .fascialStretching:
            return "Slow, sustained stretches targeting the fascial system"
        case .passiveStretching:
            return "Therapist moves limb through range of motion while client relaxes"
        case .activeAssistedStretching:
            return "Client initiates movement with therapist assistance"
        case .proprioceptiveNeuromuscularFacilitation:
            return "Contract-relax technique to increase range of motion"
        case .jointMobilization:
            return "Gentle passive movements to increase joint range of motion"
        case .rangeOfMotion:
            return "Moving joints through their full range of motion"
        case .compressionStrokes:
            return "Rhythmic pressing into muscles to increase blood flow"
        case .jostling:
            return "Rapid shaking of muscles to promote relaxation"
        case .broadening:
            return "Spreading muscle fibers apart to release tension"
        case .manualLymphDrainage:
            return "Very light, rhythmic strokes to stimulate lymph flow"
        case .lymphaticDrainage:
            return "Gentle techniques to reduce swelling and improve lymph circulation"
        case .reiki:
            return "Energy healing through light touch or hands above body"
        case .craniosacral:
            return "Gentle manipulation of cranial bones and sacrum"
        case .polarityTherapy:
            return "Balancing body's electromagnetic energy field"
        case .footReflexology:
            return "Pressure on specific foot points corresponding to body organs"
        case .handReflexology:
            return "Pressure on hand points corresponding to body systems"
        case .shiatsu:
            return "Finger pressure on meridian points to balance energy"
        case .thaiMassage:
            return "Combination of acupressure, stretching, and yoga-like movements"
        case .acupressure:
            return "Pressure on acupuncture points to release energy blockages"
        case .tuiNa:
            return "Chinese manual therapy using rhythmic pressure and stretches"
        }
    }
}

enum TechniqueCategory: String, Codable, CaseIterable {
    case swedish = "Swedish"
    case deepTissue = "Deep Tissue"
    case triggerPoint = "Trigger Point"
    case myofascial = "Myofascial"
    case stretching = "Stretching"
    case jointWork = "Joint Work"
    case sports = "Sports"
    case lymphatic = "Lymphatic"
    case energy = "Energy Work"
    case reflexology = "Reflexology"
    case asian = "Asian Techniques"

    var color: Color {
        switch self {
        case .swedish: return .blue
        case .deepTissue: return .red
        case .triggerPoint: return .purple
        case .myofascial: return .orange
        case .stretching: return .green
        case .jointWork: return .cyan
        case .sports: return .yellow
        case .lymphatic: return .pink
        case .energy: return .indigo
        case .reflexology: return .teal
        case .asian: return .brown
        }
    }
}

enum Modality: String, Codable, CaseIterable {
    // Heat Therapy
    case hotStone = "Hot Stone"
    case warmTowels = "Warm Towels"
    case heatingPad = "Heating Pad"
    case paraffinWax = "Paraffin Wax"

    // Cold Therapy
    case coldStone = "Cold Stone"
    case icePacks = "Ice Packs"
    case cryotherapy = "Cryotherapy"

    // Cupping
    case staticCupping = "Static Cupping"
    case dynamicCupping = "Dynamic Cupping"
    case fireCupping = "Fire Cupping"
    case suctionCupping = "Suction Cupping"

    // Percussion
    case percussionGun = "Percussion Gun"
    case vibrationTherapy = "Vibration Therapy"

    // Aromatherapy
    case essentialOils = "Essential Oils"
    case aromatherapy = "Aromatherapy"

    // Tools
    case guasha = "Gua Sha"
    case foamRoller = "Foam Roller"
    case massageBalls = "Massage Balls"
    case theracane = "Theracane"
    case bamboo = "Bamboo Massage"

    // Ultrasound & Electrical
    case ultrasound = "Therapeutic Ultrasound"
    case tens = "TENS (Electrical Stimulation)"

    // Hydrotherapy
    case hydrotherapy = "Hydrotherapy"
    case contrast = "Contrast Therapy"

    var category: ModalityCategory {
        switch self {
        case .hotStone, .warmTowels, .heatingPad, .paraffinWax:
            return .heat
        case .coldStone, .icePacks, .cryotherapy:
            return .cold
        case .staticCupping, .dynamicCupping, .fireCupping, .suctionCupping:
            return .cupping
        case .percussionGun, .vibrationTherapy:
            return .percussion
        case .essentialOils, .aromatherapy:
            return .aromatherapy
        case .guasha, .foamRoller, .massageBalls, .theracane, .bamboo:
            return .tools
        case .ultrasound, .tens:
            return .electrical
        case .hydrotherapy, .contrast:
            return .water
        }
    }

    var icon: String {
        switch category {
        case .heat: return "flame.fill"
        case .cold: return "snowflake"
        case .cupping: return "circle.circle"
        case .percussion: return "waveform"
        case .aromatherapy: return "leaf.fill"
        case .tools: return "hammer.fill"
        case .electrical: return "bolt.fill"
        case .water: return "drop.fill"
        }
    }

    var color: Color {
        switch category {
        case .heat: return .red
        case .cold: return .blue
        case .cupping: return .purple
        case .percussion: return .orange
        case .aromatherapy: return .green
        case .tools: return .gray
        case .electrical: return .yellow
        case .water: return .cyan
        }
    }
}

enum ModalityCategory: String, Codable, CaseIterable {
    case heat = "Heat Therapy"
    case cold = "Cold Therapy"
    case cupping = "Cupping"
    case percussion = "Percussion"
    case aromatherapy = "Aromatherapy"
    case tools = "Tools"
    case electrical = "Electrical"
    case water = "Hydrotherapy"
}

enum ClientResponse: String, Codable, CaseIterable {
    case excellent = "Excellent - Very positive response"
    case good = "Good - Positive response"
    case fair = "Fair - Moderate response"
    case poor = "Poor - Minimal response"
    case adverse = "Adverse - Negative reaction"

    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .orange
        case .adverse: return .red
        }
    }

    var icon: String {
        switch self {
        case .excellent: return "hand.thumbsup.fill"
        case .good: return "checkmark.circle.fill"
        case .fair: return "minus.circle.fill"
        case .poor: return "xmark.circle.fill"
        case .adverse: return "exclamationmark.triangle.fill"
        }
    }
}
