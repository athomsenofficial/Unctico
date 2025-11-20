import Foundation
import SwiftUI

/// Digital intake form for collecting client information
struct IntakeForm: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    let clientName: String
    let formTemplateId: UUID
    let formName: String
    let createdDate: Date
    let completedDate: Date?
    let lastModified: Date
    let status: IntakeFormStatus
    let responses: [FormResponse]
    let signatureData: Data?
    let signatureDate: Date?
    let version: String

    init(
        id: UUID = UUID(),
        clientId: UUID,
        clientName: String,
        formTemplateId: UUID,
        formName: String,
        createdDate: Date = Date(),
        completedDate: Date? = nil,
        lastModified: Date = Date(),
        status: IntakeFormStatus = .draft,
        responses: [FormResponse] = [],
        signatureData: Data? = nil,
        signatureDate: Date? = nil,
        version: String = "1.0"
    ) {
        self.id = id
        self.clientId = clientId
        self.clientName = clientName
        self.formTemplateId = formTemplateId
        self.formName = formName
        self.createdDate = createdDate
        self.completedDate = completedDate
        self.lastModified = lastModified
        self.status = status
        self.responses = responses
        self.signatureData = signatureData
        self.signatureDate = signatureDate
        self.version = version
    }

    var isComplete: Bool {
        status == .completed
    }

    var completionPercentage: Double {
        guard !responses.isEmpty else { return 0 }
        let answered = responses.filter { !$0.answer.isEmpty }.count
        return Double(answered) / Double(responses.count) * 100
    }
}

enum IntakeFormStatus: String, Codable {
    case draft = "Draft"
    case inProgress = "In Progress"
    case completed = "Completed"
    case archived = "Archived"

    var color: Color {
        switch self {
        case .draft: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        case .archived: return .purple
        }
    }
}

/// Individual question response
struct FormResponse: Identifiable, Codable {
    let id: UUID
    let questionId: UUID
    let question: String
    let questionType: QuestionType
    let answer: String
    let options: [String]
    let isRequired: Bool
    let answeredDate: Date?

    init(
        id: UUID = UUID(),
        questionId: UUID,
        question: String,
        questionType: QuestionType,
        answer: String = "",
        options: [String] = [],
        isRequired: Bool = false,
        answeredDate: Date? = nil
    ) {
        self.id = id
        self.questionId = questionId
        self.question = question
        self.questionType = questionType
        self.answer = answer
        self.options = options
        self.isRequired = isRequired
        self.answeredDate = answeredDate
    }

    var isAnswered: Bool {
        !answer.isEmpty
    }
}

enum QuestionType: String, Codable {
    case shortText = "Short Text"
    case longText = "Long Text"
    case multipleChoice = "Multiple Choice"
    case checkbox = "Checkbox"
    case dropdown = "Dropdown"
    case yesNo = "Yes/No"
    case date = "Date"
    case number = "Number"
    case phone = "Phone"
    case email = "Email"
    case rating = "Rating (1-10)"
    case bodyDiagram = "Body Diagram"
    case signature = "Signature"
}

/// Intake form template (reusable form structure)
struct IntakeFormTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let category: IntakeFormCategory
    let questions: [FormQuestion]
    let version: String
    let isActive: Bool
    let isDefault: Bool
    let createdDate: Date
    let lastModified: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: IntakeFormCategory,
        questions: [FormQuestion],
        version: String = "1.0",
        isActive: Bool = true,
        isDefault: Bool = false,
        createdDate: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.questions = questions
        self.version = version
        self.isActive = isActive
        self.isDefault = isDefault
        self.createdDate = createdDate
        self.lastModified = lastModified
    }
}

enum IntakeFormCategory: String, Codable, CaseIterable {
    case general = "General Intake"
    case medical = "Medical History"
    case painAssessment = "Pain Assessment"
    case prenatal = "Prenatal Intake"
    case sports = "Sports Massage"
    case spa = "Spa Services"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .general: return "list.clipboard.fill"
        case .medical: return "cross.case.fill"
        case .painAssessment: return "stethoscope"
        case .prenatal: return "figure.walk"
        case .sports: return "sportscourt.fill"
        case .spa: return "sparkles"
        case .custom: return "pencil.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .general: return .blue
        case .medical: return .red
        case .painAssessment: return .orange
        case .prenatal: return .pink
        case .sports: return .green
        case .spa: return .purple
        case .custom: return .gray
        }
    }
}

/// Form question definition
struct FormQuestion: Identifiable, Codable {
    let id: UUID
    let text: String
    let type: QuestionType
    let options: [String]
    let isRequired: Bool
    let placeholder: String
    let helpText: String
    let order: Int
    let conditionalLogic: ConditionalLogic?
    let validationRules: ValidationRules?

    init(
        id: UUID = UUID(),
        text: String,
        type: QuestionType,
        options: [String] = [],
        isRequired: Bool = false,
        placeholder: String = "",
        helpText: String = "",
        order: Int,
        conditionalLogic: ConditionalLogic? = nil,
        validationRules: ValidationRules? = nil
    ) {
        self.id = id
        self.text = text
        self.type = type
        self.options = options
        self.isRequired = isRequired
        self.placeholder = placeholder
        self.helpText = helpText
        self.order = order
        self.conditionalLogic = conditionalLogic
        self.validationRules = validationRules
    }
}

/// Conditional logic for showing/hiding questions
struct ConditionalLogic: Codable {
    let dependsOnQuestionId: UUID
    let showIf: String // value to match
    let operator: LogicOperator

    enum LogicOperator: String, Codable {
        case equals = "equals"
        case contains = "contains"
        case notEquals = "not equals"
    }
}

/// Validation rules for form fields
struct ValidationRules: Codable {
    let minLength: Int?
    let maxLength: Int?
    let minValue: Double?
    let maxValue: Double?
    let pattern: String? // regex pattern
    let errorMessage: String
}

/// Pre-built template helpers
extension IntakeFormTemplate {
    /// General massage therapy intake form
    static func generalMassageIntake() -> IntakeFormTemplate {
        IntakeFormTemplate(
            name: "General Massage Intake",
            description: "Standard intake form for new massage therapy clients",
            category: .general,
            questions: [
                FormQuestion(
                    text: "Full Name",
                    type: .shortText,
                    isRequired: true,
                    placeholder: "First Last",
                    order: 1
                ),
                FormQuestion(
                    text: "Date of Birth",
                    type: .date,
                    isRequired: true,
                    order: 2
                ),
                FormQuestion(
                    text: "Email Address",
                    type: .email,
                    isRequired: true,
                    placeholder: "email@example.com",
                    order: 3
                ),
                FormQuestion(
                    text: "Phone Number",
                    type: .phone,
                    isRequired: true,
                    placeholder: "(555) 123-4567",
                    order: 4
                ),
                FormQuestion(
                    text: "Address",
                    type: .longText,
                    isRequired: false,
                    placeholder: "Street, City, State, ZIP",
                    order: 5
                ),
                FormQuestion(
                    text: "Emergency Contact Name",
                    type: .shortText,
                    isRequired: true,
                    order: 6
                ),
                FormQuestion(
                    text: "Emergency Contact Phone",
                    type: .phone,
                    isRequired: true,
                    order: 7
                ),
                FormQuestion(
                    text: "How did you hear about us?",
                    type: .multipleChoice,
                    options: ["Referral", "Online Search", "Social Media", "Advertisement", "Walk-in", "Other"],
                    order: 8
                ),
                FormQuestion(
                    text: "What are your primary goals for massage therapy?",
                    type: .checkbox,
                    options: ["Pain Relief", "Stress Reduction", "Injury Recovery", "Relaxation", "Improved Flexibility", "Sports Performance"],
                    isRequired: true,
                    order: 9
                ),
                FormQuestion(
                    text: "Please describe any specific areas of concern or pain",
                    type: .longText,
                    placeholder: "Describe location, intensity, and duration of pain...",
                    order: 10
                ),
                FormQuestion(
                    text: "On a scale of 1-10, how would you rate your current pain level?",
                    type: .rating,
                    isRequired: true,
                    helpText: "1 = No pain, 10 = Worst pain imaginable",
                    order: 11
                ),
                FormQuestion(
                    text: "Have you received massage therapy before?",
                    type: .yesNo,
                    isRequired: true,
                    order: 12
                ),
                FormQuestion(
                    text: "Preferred pressure level",
                    type: .multipleChoice,
                    options: ["Light", "Medium", "Firm", "Deep", "Varies by area"],
                    order: 13
                ),
                FormQuestion(
                    text: "Are you currently experiencing any of the following? (Check all that apply)",
                    type: .checkbox,
                    options: [
                        "Pregnancy",
                        "Recent surgery",
                        "Skin conditions",
                        "Fever or infection",
                        "Blood clots",
                        "Cancer",
                        "Heart conditions",
                        "None of the above"
                    ],
                    isRequired: true,
                    order: 14
                ),
                FormQuestion(
                    text: "Do you have any allergies to oils, lotions, or fragrances?",
                    type: .yesNo,
                    isRequired: true,
                    order: 15
                ),
                FormQuestion(
                    text: "If yes, please describe your allergies",
                    type: .longText,
                    placeholder: "List specific allergens...",
                    order: 16,
                    conditionalLogic: ConditionalLogic(
                        dependsOnQuestionId: UUID(), // Would be the ID of question 15
                        showIf: "Yes",
                        operator: .equals
                    )
                ),
                FormQuestion(
                    text: "Additional comments or concerns",
                    type: .longText,
                    placeholder: "Anything else we should know?",
                    order: 17
                )
            ],
            isDefault: true
        )
    }

    /// Pain-focused intake form
    static func painAssessmentIntake() -> IntakeFormTemplate {
        IntakeFormTemplate(
            name: "Pain Assessment Intake",
            description: "Detailed pain assessment for therapeutic massage",
            category: .painAssessment,
            questions: [
                FormQuestion(
                    text: "Primary pain location",
                    type: .multipleChoice,
                    options: ["Neck", "Upper Back", "Lower Back", "Shoulders", "Hips", "Legs", "Arms", "Other"],
                    isRequired: true,
                    order: 1
                ),
                FormQuestion(
                    text: "Current pain level (1-10)",
                    type: .rating,
                    isRequired: true,
                    order: 2
                ),
                FormQuestion(
                    text: "When did the pain start?",
                    type: .multipleChoice,
                    options: ["Today", "This week", "This month", "3-6 months ago", "Over 6 months ago"],
                    isRequired: true,
                    order: 3
                ),
                FormQuestion(
                    text: "How did the pain start?",
                    type: .multipleChoice,
                    options: ["Sudden injury", "Gradual onset", "Post-surgery", "Unknown cause"],
                    order: 4
                ),
                FormQuestion(
                    text: "Describe the type of pain",
                    type: .checkbox,
                    options: ["Sharp", "Dull", "Aching", "Burning", "Tingling", "Numbness", "Radiating", "Throbbing"],
                    order: 5
                ),
                FormQuestion(
                    text: "What makes the pain worse?",
                    type: .longText,
                    placeholder: "Activities, positions, times of day...",
                    order: 6
                ),
                FormQuestion(
                    text: "What makes the pain better?",
                    type: .longText,
                    placeholder: "Rest, heat, ice, medications...",
                    order: 7
                ),
                FormQuestion(
                    text: "Have you seen other healthcare providers for this issue?",
                    type: .yesNo,
                    order: 8
                ),
                FormQuestion(
                    text: "If yes, please describe treatments received",
                    type: .longText,
                    order: 9,
                    conditionalLogic: ConditionalLogic(
                        dependsOnQuestionId: UUID(),
                        showIf: "Yes",
                        operator: .equals
                    )
                )
            ]
        )
    }

    /// Prenatal massage intake
    static func prenatalIntake() -> IntakeFormTemplate {
        IntakeFormTemplate(
            name: "Prenatal Massage Intake",
            description: "Specialized intake for prenatal massage clients",
            category: .prenatal,
            questions: [
                FormQuestion(
                    text: "Expected due date",
                    type: .date,
                    isRequired: true,
                    order: 1
                ),
                FormQuestion(
                    text: "Current trimester",
                    type: .multipleChoice,
                    options: ["First (0-13 weeks)", "Second (14-27 weeks)", "Third (28+ weeks)"],
                    isRequired: true,
                    order: 2
                ),
                FormQuestion(
                    text: "Is this your first pregnancy?",
                    type: .yesNo,
                    order: 3
                ),
                FormQuestion(
                    text: "Have you received prenatal massage before?",
                    type: .yesNo,
                    order: 4
                ),
                FormQuestion(
                    text: "OB/GYN Name and Contact",
                    type: .shortText,
                    isRequired: true,
                    order: 5
                ),
                FormQuestion(
                    text: "Has your doctor approved massage therapy?",
                    type: .yesNo,
                    isRequired: true,
                    order: 6
                ),
                FormQuestion(
                    text: "Are you experiencing any pregnancy complications?",
                    type: .yesNo,
                    isRequired: true,
                    order: 7
                ),
                FormQuestion(
                    text: "If yes, please describe",
                    type: .longText,
                    isRequired: true,
                    order: 8,
                    conditionalLogic: ConditionalLogic(
                        dependsOnQuestionId: UUID(),
                        showIf: "Yes",
                        operator: .equals
                    )
                ),
                FormQuestion(
                    text: "Common pregnancy discomforts (check all that apply)",
                    type: .checkbox,
                    options: ["Back pain", "Hip pain", "Swelling", "Leg cramps", "Headaches", "Carpal tunnel", "Sciatica", "Insomnia"],
                    order: 9
                ),
                FormQuestion(
                    text: "Any areas to avoid during massage?",
                    type: .longText,
                    order: 10
                )
            ]
        )
    }
}
