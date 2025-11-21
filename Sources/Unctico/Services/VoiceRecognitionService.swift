import Foundation
import AVFoundation
// TODO: import Speech // Apple Speech Framework
// TODO: Add OpenAI API client for Whisper

/// Service for voice recognition and speech-to-text for SOAP notes
/// TODO: Implement Apple Speech Framework for real-time dictation
/// TODO: Integrate OpenAI Whisper API for batch processing
@MainActor
class VoiceRecognitionService: ObservableObject {
    static let shared = VoiceRecognitionService()

    // Audio recording
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession?

    // Speech recognition
    // TODO: private var speechRecognizer: SFSpeechRecognizer?
    // TODO: private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    // TODO: private var recognitionTask: SFSpeechRecognitionTask?

    @Published var isRecording = false
    @Published var currentTranscription = ""
    @Published var currentSession: DictationSession?

    private let medicalVocabulary = MedicalVocabulary.massageTherapyDefault

    init() {
        setupAudioSession()
        // TODO: Initialize speech recognizer
        // speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    // MARK: - Audio Setup

    private func setupAudioSession() {
        // TODO: Configure AVAudioSession for recording
        /*
        do {
            recordingSession = AVAudioSession.sharedInstance()
            try recordingSession?.setCategory(.record, mode: .measurement)
            try recordingSession?.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        */
    }

    /// Request microphone and speech recognition permissions
    func requestPermissions() async -> Bool {
        // TODO: Request microphone permission
        /*
        let microphoneStatus = await AVAudioSession.sharedInstance().requestRecordPermission()
        guard microphoneStatus else { return false }

        // Request speech recognition permission
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        */

        // Placeholder
        return false
    }

    // MARK: - Dictation Session

    /// Start new dictation session
    func startDictationSession(
        appointmentId: UUID?,
        soapNoteId: UUID?
    ) -> DictationSession {
        let session = DictationSession(
            appointmentId: appointmentId,
            soapNoteId: soapNoteId,
            status: .active
        )

        currentSession = session
        return session
    }

    /// End dictation session
    func endDictationSession() -> DictationSession? {
        guard var session = currentSession else { return nil }

        stopRecording()

        session.endTime = Date()
        session.status = .completed
        currentSession = nil

        return session
    }

    /// Change SOAP section during dictation
    func changeDictationSection(_ section: SOAPSection) {
        currentSession?.currentSection = section
    }

    // MARK: - Real-Time Recording & Transcription

    /// Start recording and real-time transcription
    func startRecording() async throws {
        guard !isRecording else { return }

        // TODO: Set up audio recorder
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording-\(UUID().uuidString).wav")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        // TODO: Create and start audio recorder
        /*
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.record()
        */

        // TODO: Start real-time speech recognition
        /*
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                self.currentTranscription = result.bestTranscription.formattedString

                // Check for voice commands
                self.handleVoiceCommands(result.bestTranscription.formattedString)

                // Apply medical vocabulary corrections
                let corrected = self.applyMedicalVocabulary(result.bestTranscription.formattedString)
                self.currentTranscription = corrected
            }

            if error != nil || result?.isFinal == true {
                // Transcription complete
                self.finishTranscription()
            }
        }
        */

        isRecording = true
    }

    /// Stop recording
    func stopRecording() {
        guard isRecording else { return }

        // TODO: Stop audio recorder
        // audioRecorder?.stop()
        // audioRecorder = nil

        // TODO: Stop speech recognition
        // recognitionRequest?.endAudio()
        // recognitionTask?.cancel()

        isRecording = false

        // Save transcription
        if !currentTranscription.isEmpty {
            saveTranscription(currentTranscription)
        }
    }

    /// Pause recording
    func pauseRecording() {
        guard isRecording else { return }

        // TODO: Pause audio recorder
        // audioRecorder?.pause()

        currentSession?.status = .paused
    }

    /// Resume recording
    func resumeRecording() {
        guard !isRecording else { return }

        // TODO: Resume audio recorder
        // audioRecorder?.record()

        currentSession?.status = .active
    }

    // MARK: - Batch Transcription (Whisper API)

    /// Transcribe audio file using OpenAI Whisper
    /// TODO: Implement Whisper API integration
    func transcribeAudioFile(fileUrl: URL) async throws -> VoiceTranscription {
        // TODO: Upload audio file to OpenAI Whisper API
        /*
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(try Data(contentsOf: fileUrl))
        body.append("\r\n".data(using: .utf8)!)

        // Add language
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("en\r\n".data(using: .utf8)!)

        // Add prompt for medical context
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        body.append("This is a medical SOAP note from a massage therapy session. It includes medical terminology, anatomy terms, and treatment techniques.\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(WhisperResponse.self, from: data)

        let transcription = VoiceTranscription(
            audioFileUrl: fileUrl.path,
            transcribedText: response.text,
            confidence: 95, // Whisper doesn't return confidence
            duration: 0, // Would need to calculate
            transcriptionService: .openaiWhisper
        )

        return transcription
        */

        // Placeholder
        throw NSError(domain: "VoiceRecognitionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Whisper API integration not yet implemented"])
    }

    // MARK: - Voice Commands

    /// Handle voice commands
    private func handleVoiceCommands(_ text: String) {
        let lowercased = text.lowercased()

        // Section navigation commands
        if lowercased.contains("start subjective") || lowercased.contains("subjective section") {
            changeDictationSection(.subjective)
        } else if lowercased.contains("start objective") || lowercased.contains("objective section") {
            changeDictationSection(.objective)
        } else if lowercased.contains("start assessment") || lowercased.contains("assessment section") {
            changeDictationSection(.assessment)
        } else if lowercased.contains("start plan") || lowercased.contains("plan section") {
            changeDictationSection(.plan)
        }

        // Formatting commands
        if lowercased.contains("new paragraph") {
            currentTranscription += "\n\n"
        } else if lowercased.contains("new line") {
            currentTranscription += "\n"
        } else if lowercased.contains("bullet point") {
            currentTranscription += "\n• "
        }

        // Editing commands
        if lowercased.contains("delete that") || lowercased.contains("scratch that") {
            // Remove last sentence
            if let lastPeriod = currentTranscription.lastIndex(of: ".") {
                currentTranscription = String(currentTranscription[..<lastPeriod]) + "."
            }
        }
    }

    // MARK: - Medical Vocabulary

    /// Apply medical vocabulary corrections
    private func applyMedicalVocabulary(_ text: String) -> String {
        var corrected = text

        // Replace common misheard medical terms
        let corrections: [String: String] = [
            "trap easy us": "trapezius",
            "lat is most dorsi": "latissimus dorsi",
            "gas truck knee me us": "gastrocnemius",
            "soul ee us": "soleus",
            "my al juh": "myalgia",
            "fiber my al juh": "fibromyalgia",
            "sigh at ick uh": "sciatica",
            "bur sight is": "bursitis",
            "tendon itis": "tendinitis",
            "my oh fash ul": "myofascial",
            "ef lure age": "effleurage",
            "pet ruh sahge": "petrissage",
            "tap oh tuh ment": "tapotement"
        ]

        for (incorrect, correct) in corrections {
            corrected = corrected.replacingOccurrences(
                of: incorrect,
                with: correct,
                options: .caseInsensitive
            )
        }

        // Expand abbreviations
        for (abbreviation, fullTerm) in medicalVocabulary.abbreviations {
            let pattern = "\\b\(abbreviation)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(corrected.startIndex..., in: corrected)
                corrected = regex.stringByReplacingMatches(
                    in: corrected,
                    range: range,
                    withTemplate: fullTerm
                )
            }
        }

        return corrected
    }

    /// Get suggestions for similar medical terms
    func getMedicalTermSuggestions(for word: String) -> [String] {
        let lowercased = word.lowercased()

        return medicalVocabulary.terms
            .filter { term in
                term.term.lowercased().contains(lowercased) ||
                levenshteinDistance(lowercased, term.term.lowercased()) <= 2
            }
            .map { $0.term }
            .prefix(5)
            .map { String($0) }
    }

    /// Calculate Levenshtein distance between two strings
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let m = s1.count
        let n = s2.count
        var matrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m {
            matrix[i][0] = i
        }

        for j in 0...n {
            matrix[0][j] = j
        }

        for i in 1...m {
            for j in 1...n {
                let cost = s1[s1.index(s1.startIndex, offsetBy: i - 1)] == s2[s2.index(s2.startIndex, offsetBy: j - 1)] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }

        return matrix[m][n]
    }

    // MARK: - Transcription Management

    /// Save transcription to session
    private func saveTranscription(_ text: String) {
        guard currentSession != nil else { return }

        let transcription = VoiceTranscription(
            transcribedText: text,
            confidence: 85, // Would be actual confidence from recognizer
            transcriptionService: .appleSpeech
        )

        currentSession?.transcriptions.append(transcription)
    }

    /// Finish current transcription
    private func finishTranscription() {
        if !currentTranscription.isEmpty {
            saveTranscription(currentTranscription)
            currentTranscription = ""
        }
    }

    /// Get full transcription text for session
    func getSessionTranscription(_ session: DictationSession) -> String {
        return session.transcriptions
            .map { $0.transcribedText }
            .joined(separator: "\n\n")
    }

    /// Apply transcription to SOAP note
    func applyToSOAPNote(
        session: DictationSession,
        soapNote: SOAPNote
    ) -> SOAPNote {
        var updated = soapNote

        // Group transcriptions by section
        // In real implementation, would track which section each transcription belongs to

        let fullText = getSessionTranscription(session)

        // Simple approach: append to subjective section
        // In production, would be more sophisticated based on voice commands
        updated.subjective = (updated.subjective.isEmpty ? "" : updated.subjective + "\n\n") + fullText

        return updated
    }

    // MARK: - Utilities

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Delete audio file
    func deleteAudioFile(at url: String) {
        let fileUrl = URL(fileURLWithPath: url)
        try? FileManager.default.removeItem(at: fileUrl)
    }

    /// Get audio file duration
    func getAudioDuration(fileUrl: URL) -> TimeInterval {
        let asset = AVAsset(url: fileUrl)
        return CMTimeGetSeconds(asset.duration)
    }

    // MARK: - Statistics

    /// Calculate voice recognition statistics
    func calculateStatistics(
        transcriptions: [VoiceTranscription]
    ) -> VoiceRecognitionStatistics {
        let totalDuration = transcriptions.reduce(0) { $0 + $1.duration }
        let totalWords = transcriptions.reduce(0) { $0 + $1.wordCount }
        let avgConfidence = transcriptions.isEmpty ? 0 : transcriptions.reduce(0) { $0 + $1.confidence } / Double(transcriptions.count)
        let avgWPM = transcriptions.isEmpty ? 0 : transcriptions.reduce(0) { $0 + $1.wordsPerMinute } / Double(transcriptions.count)

        // Find most used service
        let serviceCounts = Dictionary(grouping: transcriptions, by: { $0.transcriptionService })
            .mapValues { $0.count }
        let mostUsed = serviceCounts.max(by: { $0.value < $1.value })?.key

        // Calculate success rate
        let successful = transcriptions.filter { $0.status == .completed }.count
        let successRate = transcriptions.isEmpty ? 0 : (Double(successful) / Double(transcriptions.count)) * 100

        return VoiceRecognitionStatistics(
            totalTranscriptions: transcriptions.count,
            totalDuration: totalDuration,
            averageConfidence: avgConfidence,
            totalWords: totalWords,
            averageWordsPerMinute: avgWPM,
            mostUsedService: mostUsed,
            successRate: successRate
        )
    }
}

// MARK: - Supporting Types

private struct WhisperResponse: Codable {
    let text: String
}

/*
 IMPLEMENTATION GUIDE:

 1. Enable Speech Framework:
    - Add to Info.plist:
      NSSpeechRecognitionUsageDescription: "We need speech recognition to transcribe your SOAP notes"
      NSMicrophoneUsageDescription: "We need microphone access to record your voice"

 2. Apple Speech Framework Implementation:
    ```swift
    import Speech

    func startRealTimeTranscription() throws {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
            throw TranscriptionError.recognizerUnavailable
        }

        guard recognizer.isAvailable else {
            throw TranscriptionError.recognizerNotAvailable
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                // Update UI with transcription
            }
        }
    }
    ```

 3. OpenAI Whisper API:
    - Sign up at https://platform.openai.com
    - Get API key
    - Use for batch processing of recorded audio
    - Add medical context in prompt parameter for better accuracy

 4. Medical Vocabulary:
    - Build comprehensive correction dictionary
    - Use post-processing to fix common errors
    - Consider custom acoustic model training for frequently used terms

 5. Voice Commands:
    - Define command phrases
    - Use pattern matching to detect
    - Execute actions (section navigation, formatting)
    - Provide audio or visual feedback

 6. HIPAA Compliance:
    - If using cloud services, ensure BAA (Business Associate Agreement)
    - Encrypt audio files at rest
    - Secure transmission (HTTPS)
    - Audit logging
    - Data retention and deletion policies
    - Patient consent for recording

 7. User Experience:
    - Visual feedback during recording (waveform, timer)
    - Confidence indicators
    - Easy editing of transcribed text
    - Undo/redo functionality
    - Save drafts automatically
 */
