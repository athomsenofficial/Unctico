import Foundation

/// Pre-built intake form templates
extension IntakeFormTemplate {
    /// General massage therapy intake form
    static func generalMassageIntake() -> IntakeFormTemplate {
        IntakeFormTemplate(
            name: "General Massage Intake",
            description: "Standard intake form for new massage therapy clients",
            category: .general,
            questions: [
                // Personal Information
                FormQuestion(
                    text: "Full Name",
                    type: .shortText,
                    isRequired: true,
                    placeholder: "Enter your full name",
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
                    order: 3,
                    validationRules: ValidationRules(
                        pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}",
                        errorMessage: "Please enter a valid email address"
                    )
                ),
                FormQuestion(
                    text: "Phone Number",
                    type: .phone,
                    isRequired: true,
                    placeholder: "(555) 123-4567",
                    order: 4
                ),

                // Medical History
                FormQuestion(
                    text: "Are you currently experiencing any pain or discomfort?",
                    type: .yesNo,
                    isRequired: true,
                    order: 5
                ),
                FormQuestion(
                    text: "Please describe your pain or discomfort",
                    type: .longText,
                    isRequired: true,
                    placeholder: "Describe location, severity, and duration...",
                    order: 6,
                    conditionalLogic: ConditionalLogic(
                        dependsOnQuestionId: UUID(), // Set to question 5's ID
                        showIf: "Yes",
                        operator: .equals
                    )
                ),
                FormQuestion(
                    text: "Rate your current pain level",
                    type: .rating,
                    isRequired: true,
                    helpText: "1 = minimal pain, 10 = severe pain",
                    order: 7,
                    conditionalLogic: ConditionalLogic(
                        dependsOnQuestionId: UUID(),
                        showIf: "Yes",
                        operator: .equals
                    )
                ),

                // Medical Conditions
                FormQuestion(
                    text: "Do you have any of the following conditions?",
                    type: .checkbox,
                    options: [
                        "High Blood Pressure",
                        "Heart Condition",
                        "Diabetes",
                        "Cancer",
                        "Epilepsy",
                        "Arthritis",
                        "Fibromyalgia",
                        "Pregnancy",
                        "None"
                    ],
                    isRequired: true,
                    order: 8
                ),
                FormQuestion(
                    text: "Are you currently pregnant?",
                    type: .yesNo,
                    isRequired: true,
                    order: 9
                ),
                FormQuestion(
                    text: "How many weeks pregnant are you?",
                    type: .number,
                    isRequired: true,
                    placeholder: "Enter weeks",
                    order: 10,
                    conditionalLogic: ConditionalLogic(
                        dependsOnQuestionId: UUID(),
                        showIf: "Yes",
                        operator: .equals
                    )
                ),

                // Medications & Allergies
                FormQuestion(
                    text: "Are you currently taking any medications?",
                    type: .yesNo,
                    isRequired: true,
                    order: 11
                ),
                FormQuestion(
                    text: "Please list all medications",
                    type: .longText,
                    isRequired: true,
                    placeholder: "Include prescription and over-the-counter medications",
                    order: 12,
                    conditionalLogic: ConditionalLogic(
                        dependsOnQuestionId: UUID(),
                        showIf: "Yes",
                        operator: .equals
                    )
                ),
                FormQuestion(
                    text: "Do you have any allergies?",
                    type: .yesNo,
                    isRequired: true,
                    order: 13
                ),
                FormQuestion(
                    text: "Please describe your allergies",
                    type: .longText,
                    isRequired: true,
                    placeholder: "Include allergies to oils, lotions, fragrances, latex, etc.",
                    order: 14,
                    conditionalLogic: ConditionalLogic(
                        dependsOnQuestionId: UUID(),
                        showIf: "Yes",
                        operator: .equals
                    )
                ),

                // Massage History
                FormQuestion(
                    text: "Have you received massage therapy before?",
                    type: .yesNo,
                    isRequired: true,
                    order: 15
                ),
                FormQuestion(
                    text: "What is your preferred pressure level?",
                    type: .multipleChoice,
                    options: ["Light", "Medium", "Firm", "Very Firm", "Varies by area"],
                    isRequired: true,
                    order: 16
                ),
                FormQuestion(
                    text: "What are your goals for today's session?",
                    type: .checkbox,
                    options: [
                        "Pain Relief",
                        "Stress Reduction",
                        "Relaxation",
                        "Improved Flexibility",
                        "Injury Recovery",
                        "General Wellness",
                        "Other"
                    ],
                    isRequired: true,
                    order: 17
                ),

                // Additional Information
                FormQuestion(
                    text: "Is there anything else we should know?",
                    type: .longText,
                    placeholder: "Any concerns, preferences, or special requests...",
                    order: 18
                )
            ],
            version: "1.0",
            isDefault: true
        )
    }

    /// Pain assessment intake form
    static func painAssessmentIntake() -> IntakeFormTemplate {
        IntakeFormTemplate(
            name: "Pain Assessment",
            description: "Detailed pain assessment for treatment planning",
            category: .painAssessment,
            questions: [
                FormQuestion(
                    text: "Chief Complaint",
                    type: .longText,
                    isRequired: true,
                    placeholder: "Describe your main concern...",
                    order: 1
                ),
                FormQuestion(
                    text: "Current Pain Level",
                    type: .rating,
                    isRequired: true,
                    helpText: "0 = no pain, 10 = worst pain imaginable",
                    order: 2
                ),
                FormQuestion(
                    text: "When did the pain start?",
                    type: .multipleChoice,
                    options: [
                        "Today",
                        "This week",
                        "This month",
                        "2-6 months ago",
                        "6-12 months ago",
                        "Over a year ago"
                    ],
                    isRequired: true,
                    order: 3
                ),
                FormQuestion(
                    text: "Pain Quality (check all that apply)",
                    type: .checkbox,
                    options: [
                        "Sharp",
                        "Dull",
                        "Aching",
                        "Burning",
                        "Shooting",
                        "Tingling",
                        "Numbness",
                        "Throbbing"
                    ],
                    isRequired: true,
                    order: 4
                ),
                FormQuestion(
                    text: "Does the pain radiate to other areas?",
                    type: .yesNo,
                    isRequired: true,
                    order: 5
                ),
                FormQuestion(
                    text: "Where does the pain radiate?",
                    type: .longText,
                    isRequired: true,
                    placeholder: "Describe the pattern...",
                    order: 6,
                    conditionalLogic: ConditionalLogic(
                        dependsOnQuestionId: UUID(),
                        showIf: "Yes",
                        operator: .equals
                    )
                ),
                FormQuestion(
                    text: "What makes the pain worse?",
                    type: .checkbox,
                    options: [
                        "Sitting",
                        "Standing",
                        "Walking",
                        "Lying down",
                        "Movement",
                        "Exercise",
                        "Stress",
                        "Weather changes"
                    ],
                    isRequired: true,
                    order: 7
                ),
                FormQuestion(
                    text: "What makes the pain better?",
                    type: .checkbox,
                    options: [
                        "Rest",
                        "Ice",
                        "Heat",
                        "Movement",
                        "Medication",
                        "Massage",
                        "Stretching",
                        "Nothing helps"
                    ],
                    isRequired: true,
                    order: 8
                ),
                FormQuestion(
                    text: "How does the pain affect your daily activities?",
                    type: .multipleChoice,
                    options: [
                        "No impact",
                        "Mild limitation",
                        "Moderate limitation",
                        "Severe limitation",
                        "Unable to perform activities"
                    ],
                    isRequired: true,
                    order: 9
                ),
                FormQuestion(
                    text: "Rate your sleep quality",
                    type: .rating,
                    isRequired: true,
                    helpText: "1 = very poor, 10 = excellent",
                    order: 10
                ),
                FormQuestion(
                    text: "Does pain interrupt your sleep?",
                    type: .yesNo,
                    isRequired: true,
                    order: 11
                ),
                FormQuestion(
                    text: "Have you seen other healthcare providers for this issue?",
                    type: .yesNo,
                    isRequired: true,
                    order: 12
                ),
                FormQuestion(
                    text: "What treatments have you tried?",
                    type: .longText,
                    isRequired: true,
                    placeholder: "Physical therapy, chiropractic, medications, etc.",
                    order: 13,
                    conditionalLogic: ConditionalLogic(
                        dependsOnQuestionId: UUID(),
                        showIf: "Yes",
                        operator: .equals
                    )
                )
            ]
        )
    }

    /// Prenatal massage intake form
    static func prenatalIntake() -> IntakeFormTemplate {
        IntakeFormTemplate(
            name: "Prenatal Massage Intake",
            description: "Specialized intake for pregnant clients",
            category: .prenatal,
            questions: [
                FormQuestion(
                    text: "How many weeks pregnant are you?",
                    type: .number,
                    isRequired: true,
                    placeholder: "Weeks",
                    order: 1,
                    validationRules: ValidationRules(
                        minValue: 12,
                        maxValue: 42,
                        errorMessage: "Must be between 12 and 42 weeks (we only treat 2nd and 3rd trimester)"
                    )
                ),
                FormQuestion(
                    text: "Is this your first pregnancy?",
                    type: .yesNo,
                    isRequired: true,
                    order: 2
                ),
                FormQuestion(
                    text: "Have you been experiencing any complications?",
                    type: .checkbox,
                    options: [
                        "High blood pressure",
                        "Gestational diabetes",
                        "Preeclampsia",
                        "Placenta previa",
                        "Preterm labor risk",
                        "Severe morning sickness",
                        "None"
                    ],
                    isRequired: true,
                    order: 3
                ),
                FormQuestion(
                    text: "Has your doctor cleared you for massage?",
                    type: .yesNo,
                    isRequired: true,
                    helpText: "Required for high-risk pregnancies",
                    order: 4
                ),
                FormQuestion(
                    text: "What discomforts are you experiencing?",
                    type: .checkbox,
                    options: [
                        "Back pain",
                        "Sciatica",
                        "Hip pain",
                        "Swelling in legs/feet",
                        "Carpal tunnel",
                        "Headaches",
                        "Muscle tension",
                        "Sleep difficulties"
                    ],
                    isRequired: true,
                    order: 5
                ),
                FormQuestion(
                    text: "Rate your current discomfort level",
                    type: .rating,
                    isRequired: true,
                    order: 6
                ),
                FormQuestion(
                    text: "What is your preferred positioning?",
                    type: .multipleChoice,
                    options: [
                        "Side-lying",
                        "Semi-reclined",
                        "Whatever is most comfortable",
                        "Not sure"
                    ],
                    isRequired: true,
                    order: 7
                ),
                FormQuestion(
                    text: "Are there any areas you would like us to avoid?",
                    type: .longText,
                    placeholder: "Specify any sensitive or uncomfortable areas...",
                    order: 8
                )
            ]
        )
    }
}

/// Validation rules extension
struct ValidationRules: Codable {
    let minLength: Int?
    let maxLength: Int?
    let minValue: Double?
    let maxValue: Double?
    let pattern: String? // Regex pattern
    let errorMessage: String?

    init(
        minLength: Int? = nil,
        maxLength: Int? = nil,
        minValue: Double? = nil,
        maxValue: Double? = nil,
        pattern: String? = nil,
        errorMessage: String? = nil
    ) {
        self.minLength = minLength
        self.maxLength = maxLength
        self.minValue = minValue
        self.maxValue = maxValue
        self.pattern = pattern
        self.errorMessage = errorMessage
    }
}
