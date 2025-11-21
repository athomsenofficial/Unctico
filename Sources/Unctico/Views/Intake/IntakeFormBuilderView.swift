import SwiftUI

/// Interactive intake form builder with conditional logic
struct IntakeFormBuilderView: View {
    let template: IntakeFormTemplate
    @State private var responses: [UUID: String] = [:]
    @State private var showingSignaturePad = false
    @State private var signatureData: Data?
    @State private var currentSectionIndex = 0
    @Environment(\.dismiss) var dismiss

    private var visibleQuestions: [FormQuestion] {
        template.questions.filter { question in
            guard let conditional = question.conditionalLogic else {
                return true // Always show if no conditional logic
            }

            let dependentAnswer = responses[conditional.dependsOnQuestionId] ?? ""

            switch conditional.operator {
            case .equals:
                return dependentAnswer == conditional.showIf
            case .contains:
                return dependentAnswer.lowercased().contains(conditional.showIf.lowercased())
            case .notEquals:
                return dependentAnswer != conditional.showIf
            }
        }
    }

    private var completionPercentage: Double {
        let requiredQuestions = visibleQuestions.filter { $0.isRequired }
        guard !requiredQuestions.isEmpty else { return 100 }

        let answeredRequired = requiredQuestions.filter { question in
            let answer = responses[question.id] ?? ""
            return !answer.isEmpty && isValidAnswer(answer, for: question)
        }.count

        return Double(answeredRequired) / Double(requiredQuestions.count) * 100
    }

    private var canSubmit: Bool {
        completionPercentage == 100
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: completionPercentage, total: 100)
                    .progressViewStyle(.linear)
                    .tint(.blue)

                // Completion status
                HStack {
                    Text("Completion: \(Int(completionPercentage))%")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if canSubmit {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Ready to Submit")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Form content
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(visibleQuestions) { question in
                            QuestionView(
                                question: question,
                                answer: Binding(
                                    get: { responses[question.id] ?? "" },
                                    set: { responses[question.id] = $0 }
                                )
                            )
                        }

                        // Signature section
                        SignatureSectionView(
                            signatureData: $signatureData,
                            showingSignaturePad: $showingSignaturePad
                        )
                    }
                    .padding()
                }

                // Submit button
                Button {
                    submitForm()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Submit Form")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmit ? Color.blue : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!canSubmit)
                .padding()
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingSignaturePad) {
                SignaturePadView(signatureData: $signatureData)
            }
        }
    }

    private func submitForm() {
        // TODO: Save form to repository
        print("Form submitted with \(responses.count) responses")
        dismiss()
    }

    private func isValidAnswer(_ answer: String, for question: FormQuestion) -> Bool {
        guard !answer.isEmpty else { return false }

        // Apply validation rules if present
        if let rules = question.validationRules {
            if let minLength = rules.minLength, answer.count < minLength {
                return false
            }
            if let maxLength = rules.maxLength, answer.count > maxLength {
                return false
            }
            if let pattern = rules.pattern, !answer.range(of: pattern, options: .regularExpression).isPresent {
                return false
            }
        }

        return true
    }
}

// MARK: - Question View

struct QuestionView: View {
    let question: FormQuestion
    @Binding var answer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Question text
            HStack {
                Text(question.text)
                    .font(.headline)

                if question.isRequired {
                    Text("*")
                        .foregroundColor(.red)
                }
            }

            // Help text
            if !question.helpText.isEmpty {
                Text(question.helpText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Input field based on question type
            inputView

            // Validation feedback
            if question.isRequired && !answer.isEmpty {
                if isValid {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Valid")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else if let rules = question.validationRules, let message = rules.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    @ViewBuilder
    private var inputView: some View {
        switch question.type {
        case .shortText, .email, .phone:
            TextField(question.placeholder, text: $answer)
                .textFieldStyle(.roundedBorder)
                .keyboardType(keyboardType)
                .autocapitalization(autocapitalization)

        case .longText:
            TextField(question.placeholder, text: $answer, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(4...8)

        case .multipleChoice:
            VStack(spacing: 8) {
                ForEach(question.options, id: \.self) { option in
                    Button {
                        answer = option
                    } label: {
                        HStack {
                            Image(systemName: answer == option ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(answer == option ? .blue : .gray)

                            Text(option)
                                .foregroundColor(.primary)

                            Spacer()
                        }
                        .padding()
                        .background(answer == option ? Color.blue.opacity(0.1) : Color(.systemBackground))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

        case .checkbox:
            VStack(spacing: 8) {
                ForEach(question.options, id: \.self) { option in
                    Button {
                        toggleCheckbox(option)
                    } label: {
                        HStack {
                            Image(systemName: isChecked(option) ? "checkmark.square.fill" : "square")
                                .foregroundColor(isChecked(option) ? .blue : .gray)

                            Text(option)
                                .foregroundColor(.primary)

                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

        case .dropdown:
            Picker("Select", selection: $answer) {
                Text("Select...").tag("")
                ForEach(question.options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

        case .yesNo:
            HStack(spacing: 16) {
                Button {
                    answer = "Yes"
                } label: {
                    HStack {
                        Image(systemName: answer == "Yes" ? "checkmark.circle.fill" : "circle")
                        Text("Yes")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(answer == "Yes" ? Color.green.opacity(0.2) : Color(.systemBackground))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button {
                    answer = "No"
                } label: {
                    HStack {
                        Image(systemName: answer == "No" ? "checkmark.circle.fill" : "circle")
                        Text("No")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(answer == "No" ? Color.red.opacity(0.2) : Color(.systemBackground))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

        case .date:
            DatePicker("", selection: Binding(
                get: {
                    if let date = ISO8601DateFormatter().date(from: answer) {
                        return date
                    }
                    return Date()
                },
                set: { date in
                    answer = ISO8601DateFormatter().string(from: date)
                }
            ), displayedComponents: .date)
            .labelsHidden()

        case .number:
            TextField(question.placeholder, text: $answer)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

        case .rating:
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(1...10, id: \.self) { value in
                        Button {
                            answer = "\(value)"
                        } label: {
                            Text("\(value)")
                                .font(.headline)
                                .frame(width: 32, height: 32)
                                .background(answer == "\(value)" ? Color.blue : Color(.systemGray5))
                                .foregroundColor(answer == "\(value)" ? .white : .primary)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let rating = Int(answer), rating > 0 {
                    Text("Rating: \(rating)/10")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

        case .bodyDiagram:
            Text("Body diagram integration coming soon")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()

        case .signature:
            Text("Signature at bottom of form")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var keyboardType: UIKeyboardType {
        switch question.type {
        case .email: return .emailAddress
        case .phone: return .phonePad
        case .number: return .numberPad
        default: return .default
        }
    }

    private var autocapitalization: TextInputAutocapitalization {
        switch question.type {
        case .email: return .never
        default: return .sentences
        }
    }

    private var isValid: Bool {
        guard !answer.isEmpty else { return false }

        if let rules = question.validationRules {
            if let minLength = rules.minLength, answer.count < minLength {
                return false
            }
            if let maxLength = rules.maxLength, answer.count > maxLength {
                return false
            }
            if let pattern = rules.pattern {
                let regex = try? NSRegularExpression(pattern: pattern)
                let range = NSRange(answer.startIndex..., in: answer)
                return regex?.firstMatch(in: answer, range: range) != nil
            }
        }

        return true
    }

    private func isChecked(_ option: String) -> Bool {
        let selected = answer.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return selected.contains(option)
    }

    private func toggleCheckbox(_ option: String) {
        var selected = answer.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if let index = selected.firstIndex(of: option) {
            selected.remove(at: index)
        } else {
            selected.append(option)
        }

        answer = selected.joined(separator: ", ")
    }
}

// MARK: - Signature Section

struct SignatureSectionView: View {
    @Binding var signatureData: Data?
    @Binding var showingSignaturePad: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Signature")
                    .font(.headline)

                Text("*")
                    .foregroundColor(.red)
            }

            if let data = signatureData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                Button {
                    signatureData = nil
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear Signature")
                    }
                    .foregroundColor(.red)
                }
            } else {
                Button {
                    showingSignaturePad = true
                } label: {
                    HStack {
                        Image(systemName: "signature")
                        Text("Add Signature")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }

            Text("I certify that the information provided is accurate to the best of my knowledge.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Signature Pad

struct SignaturePadView: View {
    @Binding var signatureData: Data?
    @State private var paths: [Path] = []
    @State private var currentPath = Path()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("Sign below")
                    .font(.headline)
                    .padding()

                Canvas { context, size in
                    for path in paths {
                        context.stroke(path, with: .color(.black), lineWidth: 3)
                    }
                    context.stroke(currentPath, with: .color(.black), lineWidth: 3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .cornerRadius(12)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if currentPath.isEmpty {
                                currentPath.move(to: value.location)
                            } else {
                                currentPath.addLine(to: value.location)
                            }
                        }
                        .onEnded { _ in
                            paths.append(currentPath)
                            currentPath = Path()
                        }
                )
                .padding()

                HStack(spacing: 16) {
                    Button {
                        paths.removeAll()
                        currentPath = Path()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                        .foregroundColor(.red)
                    }

                    Spacer()

                    Button {
                        saveSignature()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Done")
                        }
                        .foregroundColor(.blue)
                    }
                    .disabled(paths.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func saveSignature() {
        // Create an image from the paths
        let renderer = ImageRenderer(content: Canvas { context, size in
            for path in paths {
                context.stroke(path, with: .color(.black), lineWidth: 3)
            }
        }.frame(width: 400, height: 200))

        if let image = renderer.uiImage {
            signatureData = image.pngData()
        }

        dismiss()
    }
}

extension Optional where Wrapped == Range<String.Index> {
    var isPresent: Bool {
        self != nil
    }
}

#Preview {
    IntakeFormBuilderView(
        template: IntakeFormTemplate.generalMassageIntake()
    )
}
