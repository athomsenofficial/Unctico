import SwiftUI
import Speech
import AVFoundation

/// Voice dictation view for SOAP notes with real-time transcription
struct VoiceDictationView: View {
    @Binding var text: String
    @State private var isRecording = false
    @State private var isAuthorized = false
    @State private var showingPermissionAlert = false
    @State private var currentSection: SOAPSection = .subjective
    @State private var partialTranscript = ""
    @State private var insertionPosition: Int?
    @StateObject private var dictationManager = DictationManager()

    var body: some View {
        VStack(spacing: 16) {
            // Section selector
            sectionSelector

            // Transcription display
            transcriptionDisplay

            // Quick phrases
            quickPhrasesSection

            // Recording controls
            recordingControls
        }
        .padding()
        .onAppear {
            checkAuthorization()
        }
        .alert("Microphone Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings", action: openSettings)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable microphone and speech recognition permissions in Settings to use voice dictation.")
        }
    }

    private var sectionSelector: some View {
        Picker("Section", selection: $currentSection) {
            ForEach(SOAPSection.allCases, id: \.self) { section in
                Text(section.rawValue).tag(section)
            }
        }
        .pickerStyle(.segmented)
    }

    private var transcriptionDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Transcription")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if isRecording {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("Recording")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if !text.isEmpty {
                        Text(text)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !partialTranscript.isEmpty && isRecording {
                        Text(partialTranscript)
                            .font(.body)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if text.isEmpty && partialTranscript.isEmpty {
                        Text("Tap microphone to start dictating...")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .frame(height: 200)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private var quickPhrasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Phrases")
                .font(.subheadline)
                .fontWeight(.medium)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickPhrasesForSection, id: \.self) { phrase in
                        Button {
                            insertQuickPhrase(phrase)
                        } label: {
                            Text(phrase)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }

    private var recordingControls: some View {
        VStack(spacing: 12) {
            // Main microphone button
            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.blue)
                        .frame(width: 80, height: 80)

                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
            }
            .disabled(!isAuthorized)

            Text(isRecording ? "Tap to stop" : "Tap to record")
                .font(.caption)
                .foregroundColor(.secondary)

            // Additional controls
            HStack(spacing: 20) {
                Button {
                    clearTranscription()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.title3)
                        Text("Clear")
                            .font(.caption)
                    }
                    .foregroundColor(.red)
                }
                .disabled(text.isEmpty && partialTranscript.isEmpty)

                Button {
                    undoLastSentence()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.title3)
                        Text("Undo")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .disabled(text.isEmpty)

                Button {
                    insertPunctuation(".")
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "circle.fill")
                            .font(.title3)
                        Text("Period")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .disabled(!isRecording)
            }
        }
    }

    private var quickPhrasesForSection: [String] {
        switch currentSection {
        case .subjective:
            return [
                "Client reports pain in",
                "Pain level is",
                "Onset was",
                "Pain is described as",
                "Aggravated by",
                "Relieved by",
                "Sleep is affected",
                "Stress level is high"
            ]
        case .objective:
            return [
                "Upon palpation",
                "Range of motion",
                "Muscle tension noted in",
                "Trigger points located at",
                "Postural deviation",
                "Tissue texture is",
                "Decreased mobility in",
                "Notable tightness in"
            ]
        case .assessment:
            return [
                "Diagnosis:",
                "Progressing well",
                "Symptoms improving",
                "Chronic muscle tension",
                "Acute strain",
                "Postural dysfunction",
                "Myofascial pain syndrome",
                "Treatment is effective"
            ]
        case .plan:
            return [
                "Continue treatment",
                "Recommend frequency of",
                "Home care includes",
                "Stretching exercises",
                "Apply heat before",
                "Ice after activity",
                "Follow up in",
                "Refer to physician"
            ]
        }
    }

    // MARK: - Actions

    private func checkAuthorization() {
        Task {
            let speechAuthorized = await requestSpeechAuthorization()
            let micAuthorized = await requestMicrophoneAuthorization()
            await MainActor.run {
                isAuthorized = speechAuthorized && micAuthorized
                if !isAuthorized {
                    showingPermissionAlert = true
                }
            }
        }
    }

    private func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophoneAuthorization() async -> Bool {
        await AVAudioSession.sharedInstance().requestRecordPermission()
    }

    private func startRecording() {
        guard isAuthorized else {
            showingPermissionAlert = true
            return
        }

        isRecording = true
        partialTranscript = ""

        dictationManager.startRecording { partial in
            partialTranscript = partial
        } completion: { final in
            if !final.isEmpty {
                if text.isEmpty {
                    text = final
                } else {
                    text += " " + final
                }
            }
            partialTranscript = ""
            isRecording = false
        }
    }

    private func stopRecording() {
        dictationManager.stopRecording()
        isRecording = false
    }

    private func insertQuickPhrase(_ phrase: String) {
        if text.isEmpty {
            text = phrase
        } else {
            text += " " + phrase
        }
    }

    private func insertPunctuation(_ punctuation: String) {
        if !text.isEmpty {
            text += punctuation
        }
    }

    private func clearTranscription() {
        text = ""
        partialTranscript = ""
    }

    private func undoLastSentence() {
        if let lastPeriod = text.lastIndex(of: ".") {
            text = String(text[..<lastPeriod])
        } else {
            text = ""
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Dictation Manager

@MainActor
class DictationManager: ObservableObject {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?

    private var partialResultHandler: ((String) -> Void)?
    private var completionHandler: ((String) -> Void)?

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        audioEngine = AVAudioEngine()
    }

    func startRecording(
        partialResult: @escaping (String) -> Void,
        completion: @escaping (String) -> Void
    ) {
        self.partialResultHandler = partialResult
        self.completionHandler = completion

        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        guard let audioEngine = audioEngine else { return }
        let inputNode = audioEngine.inputNode

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            var isFinal = false

            if let result = result {
                let transcription = result.bestTranscription.formattedString

                if result.isFinal {
                    isFinal = true
                    self?.completionHandler?(transcription)
                } else {
                    self?.partialResultHandler?(transcription)
                }
            }

            if error != nil || isFinal {
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self?.recognitionRequest = nil
                self?.recognitionTask = nil
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine error: \(error)")
        }
    }

    func stopRecording() {
        audioEngine?.stop()
        recognitionRequest?.endAudio()

        // Give a moment for final transcription
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.recognitionTask?.finish()
        }
    }
}

// MARK: - SOAP Section

enum SOAPSection: String, CaseIterable {
    case subjective = "Subjective"
    case objective = "Objective"
    case assessment = "Assessment"
    case plan = "Plan"
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = ""

        var body: some View {
            NavigationView {
                VoiceDictationView(text: $text)
                    .navigationTitle("Voice Dictation")
            }
        }
    }

    return PreviewWrapper()
}
