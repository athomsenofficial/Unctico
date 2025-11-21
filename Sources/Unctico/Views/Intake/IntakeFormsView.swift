import SwiftUI

/// Main intake forms management view
struct IntakeFormsView: View {
    @State private var intakeForms: [IntakeForm] = []
    @State private var showingNewForm = false
    @State private var selectedTemplate: IntakeFormTemplate?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if intakeForms.isEmpty {
                    EmptyStateView()
                } else {
                    IntakeFormsList(forms: $intakeForms)
                }
            }
            .navigationTitle("Intake Forms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(IntakeFormCategory.allCases, id: \.self) { category in
                            Button(action: {
                                createNewForm(category: category)
                            }) {
                                Label(category.rawValue, systemImage: category.icon)
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.tranquilTeal)
                    }
                }
            }
            .sheet(isPresented: $showingNewForm) {
                if let template = selectedTemplate {
                    IntakeFormBuilderView(template: template)
                }
            }
        }
    }

    private func createNewForm(category: IntakeFormCategory) {
        switch category {
        case .general:
            selectedTemplate = IntakeFormTemplate.generalMassageIntake()
        case .painAssessment:
            selectedTemplate = IntakeFormTemplate.painAssessmentIntake()
        case .prenatal:
            selectedTemplate = IntakeFormTemplate.prenatalIntake()
        default:
            selectedTemplate = IntakeFormTemplate(
                name: "Custom \(category.rawValue)",
                description: "Customized intake form",
                category: category,
                questions: []
            )
        }
        showingNewForm = true
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Intake Forms")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create your first intake form using the + button above")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Intake Forms List
struct IntakeFormsList: View {
    @Binding var forms: [IntakeForm]

    var body: some View {
        List {
            ForEach(forms.sorted(by: { $0.createdDate > $1.createdDate })) { form in
                NavigationLink(destination: IntakeFormDetailView(form: form)) {
                    IntakeFormRow(form: form)
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Intake Form Row
struct IntakeFormRow: View {
    let form: IntakeForm

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(form.formName)
                    .font(.headline)

                Spacer()

                StatusBadge(status: form.status)
            }

            Text(form.clientName)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Label("\(Int(form.completionPercentage))%", systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(.tranquilTeal)

                Label(form.createdDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if form.isSigned {
                    Label("Signed", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: IntakeFormStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .cornerRadius(6)
    }
}

// MARK: - Intake Form Builder
struct IntakeFormBuilderView: View {
    @Environment(\.dismiss) var dismiss
    let template: IntakeFormTemplate

    @State private var responses: [FormResponse] = []
    @State private var currentQuestionIndex = 0
    @State private var signature Data: Data? = nil
    @State private var showingSignaturePad = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Bar
                ProgressBar(current: currentQuestionIndex, total: template.questions.count)
                    .padding()

                // Question View
                ScrollView {
                    VStack(spacing: 24) {
                        if currentQuestionIndex < template.questions.count {
                            QuestionView(
                                question: template.questions[currentQuestionIndex],
                                response: binding(for: template.questions[currentQuestionIndex])
                            )
                        } else {
                            // Signature Page
                            SignatureSectionView(signatureData: $signatureData, showingPad: $showingSignaturePad)
                        }
                    }
                    .padding()
                }

                // Navigation Buttons
                NavigationButtons(
                    currentIndex: $currentQuestionIndex,
                    totalQuestions: template.questions.count,
                    canProceed: canProceed(),
                    onSave: saveForm
                )
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            initializeResponses()
        }
        .sheet(isPresented: $showingSignaturePad) {
            SignaturePadView(signatureData: $signatureData)
        }
    }

    private func initializeResponses() {
        responses = template.questions.map { question in
            FormResponse(
                questionId: question.id,
                question: question.text,
                questionType: question.type,
                options: question.options,
                isRequired: question.isRequired
            )
        }
    }

    private func binding(for question: FormQuestion) -> Binding<FormResponse> {
        let index = responses.firstIndex { $0.questionId == question.id } ?? 0
        return $responses[index]
    }

    private func canProceed() -> Bool {
        guard currentQuestionIndex < template.questions.count else {
            return signatureData != nil
        }

        let currentResponse = responses[currentQuestionIndex]
        if currentResponse.isRequired {
            return !currentResponse.answer.isEmpty
        }
        return true
    }

    private func saveForm() {
        // TODO: Save form to repository
        dismiss()
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let current: Int
    let total: Int

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Question \(current + 1) of \(total)")
                .font(.caption)
                .foregroundColor(.secondary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(Color.tranquilTeal)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Question View
struct QuestionView: View {
    let question: FormQuestion
    @Binding var response: FormResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question Text
            HStack {
                Text(question.text)
                    .font(.title3)
                    .fontWeight(.semibold)

                if question.isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }

            // Help Text
            if !question.helpText.isEmpty {
                Text(question.helpText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Answer Input
            AnswerInputView(question: question, response: $response)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Answer Input View
struct AnswerInputView: View {
    let question: FormQuestion
    @Binding var response: FormResponse

    var body: some View {
        switch question.type {
        case .shortText:
            TextField(question.placeholder, text: $response.answer)
                .textFieldStyle(.roundedBorder)
                .padding(.vertical, 8)

        case .longText:
            TextEditor(text: $response.answer)
                .frame(height: 120)
                .padding(8)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

        case .multipleChoice:
            VStack(spacing: 12) {
                ForEach(question.options, id: \.self) { option in
                    RadioButton(
                        option: option,
                        isSelected: response.answer == option
                    ) {
                        response.answer = option
                    }
                }
            }

        case .checkbox:
            VStack(spacing: 12) {
                ForEach(question.options, id: \.self) { option in
                    CheckboxButton(
                        option: option,
                        isSelected: selectedOptions.contains(option)
                    ) {
                        toggleOption(option)
                    }
                }
            }

        case .yesNo:
            HStack(spacing: 20) {
                YesNoButton(text: "Yes", isSelected: response.answer == "Yes") {
                    response.answer = "Yes"
                }
                YesNoButton(text: "No", isSelected: response.answer == "No") {
                    response.answer = "No"
                }
            }

        case .date:
            DatePicker("Select Date",
                      selection: Binding(
                        get: { dateFromString(response.answer) ?? Date() },
                        set: { response.answer = dateToString($0) }
                      ),
                      displayedComponents: .date)
                .datePickerStyle(.graphical)

        case .rating:
            VStack(spacing: 16) {
                Text(response.answer.isEmpty ? "Select Rating" : response.answer)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.tranquilTeal)

                HStack(spacing: 8) {
                    ForEach(1...10, id: \.self) { rating in
                        Button(action: {
                            response.answer = "\(rating)"
                        }) {
                            Text("\(rating)")
                                .font(.headline)
                                .frame(width: 40, height: 40)
                                .background(response.answer == "\(rating)" ? Color.tranquilTeal : Color.gray.opacity(0.2))
                                .foregroundColor(response.answer == "\(rating)" ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
            }

        case .phone:
            TextField(question.placeholder, text: $response.answer)
                .keyboardType(.phonePad)
                .textFieldStyle(.roundedBorder)
                .padding(.vertical, 8)

        case .email:
            TextField(question.placeholder, text: $response.answer)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)
                .padding(.vertical, 8)

        default:
            TextField(question.placeholder, text: $response.answer)
                .textFieldStyle(.roundedBorder)
                .padding(.vertical, 8)
        }
    }

    private var selectedOptions: [String] {
        response.answer.components(separatedBy: ", ").filter { !$0.isEmpty }
    }

    private func toggleOption(_ option: String) {
        var options = selectedOptions
        if let index = options.firstIndex(of: option) {
            options.remove(at: index)
        } else {
            options.append(option)
        }
        response.answer = options.joined(separator: ", ")
    }

    private func dateFromString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.date(from: string)
    }

    private func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Radio Button
struct RadioButton: View {
    let option: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "circle.fill" : "circle")
                    .foregroundColor(isSelected ? .tranquilTeal : .gray)

                Text(option)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding()
            .background(isSelected ? Color.tranquilTeal.opacity(0.1) : Color.white)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Checkbox Button
struct CheckboxButton: View {
    let option: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .tranquilTeal : .gray)

                Text(option)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding()
            .background(isSelected ? Color.tranquilTeal.opacity(0.1) : Color.white)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Yes/No Button
struct YesNoButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? Color.tranquilTeal : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(10)
        }
    }
}

// MARK: - Navigation Buttons
struct NavigationButtons: View {
    @Binding var currentIndex: Int
    let totalQuestions: Int
    let canProceed: Bool
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if currentIndex > 0 {
                Button(action: {
                    currentIndex -= 1
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
            }

            Button(action: {
                if currentIndex < totalQuestions {
                    currentIndex += 1
                } else {
                    onSave()
                }
            }) {
                HStack {
                    Text(currentIndex < totalQuestions ? "Next" : "Submit")
                    if currentIndex < totalQuestions {
                        Image(systemName: "chevron.right")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canProceed ? Color.tranquilTeal : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!canProceed)
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - Signature Section
struct SignatureSectionView: View {
    @Binding var signatureData: Data?
    @Binding var showingPad: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text("Please sign below to complete the form")
                .font(.title3)
                .fontWeight(.semibold)

            if let data = signatureData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .background(Color.white)
                    .border(Color.gray, width: 1)
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 150)
                    .border(Color.gray.opacity(0.5), width: 2)
                    .cornerRadius(8)
                    .overlay(
                        Text("Tap to Sign")
                            .foregroundColor(.secondary)
                    )
                    .onTapGesture {
                        showingPad = true
                    }
            }

            Button(action: {
                showingPad = true
            }) {
                HStack {
                    Image(systemName: signatureData == nil ? "pencil.tip.crop.circle" : "pencil.tip.crop.circle.badge.plus")
                    Text(signatureData == nil ? "Add Signature" : "Re-sign")
                        .fontWeight(.semibold)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.tranquilTeal.opacity(0.1))
                .foregroundColor(.tranquilTeal)
                .cornerRadius(10)
            }

            if signatureData != nil {
                Button(action: {
                    signatureData = nil
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear Signature")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Intake Form Detail View
struct IntakeFormDetailView: View {
    let form: IntakeForm

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Form Details View")
                    .font(.headline)
                // TODO: Implement detail view
            }
            .padding()
        }
        .navigationTitle(form.formName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
