// VoiceInputService.swift
// Voice-to-text transcription service
// QA Note: Converts speech to text for clinical documentation

import Foundation
import Speech
import AVFoundation

/// Service for voice-to-text transcription
/// Uses iOS Speech Recognition framework
class VoiceInputService: ObservableObject {

    // MARK: - Published Properties

    @Published var transcribedText = ""
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    // MARK: - Private Properties

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?

    // MARK: - Initialization

    init() {
        setupSpeechRecognizer()
    }

    // MARK: - Setup

    /// Initialize speech recognizer
    /// QA Note: This sets up the voice recognition engine
    private func setupSpeechRecognizer() {
        // Create recognizer for configured language
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: AppConfig.voiceLanguage))

        // Check if speech recognition is available on this device
        guard speechRecognizer != nil else {
            errorMessage = "Speech recognition not available on this device"
            return
        }

        // Update authorization status
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }

    // MARK: - Authorization

    /// Request authorization for speech recognition
    /// QA Note: This asks user for microphone permission
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status

                switch status {
                case .authorized:
                    completion(true)
                case .denied, .restricted, .notDetermined:
                    self.errorMessage = "Speech recognition not authorized"
                    completion(false)
                @unknown default:
                    self.errorMessage = "Unknown authorization status"
                    completion(false)
                }
            }
        }
    }

    /// Check if authorized to use speech recognition
    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    // MARK: - Recording

    /// Start recording and transcribing
    /// QA Note: This starts listening to user's voice
    func startRecording() {
        // Check authorization
        guard isAuthorized else {
            errorMessage = "Speech recognition not authorized"
            return
        }

        // Check if already recording
        guard !isRecording else { return }

        // Stop any existing task
        stopRecording()

        // Create audio engine
        audioEngine = AVAudioEngine()

        guard let audioEngine = audioEngine,
              let speechRecognizer = speechRecognizer else {
            errorMessage = "Failed to initialize audio engine"
            return
        }

        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Failed to create recognition request"
            return
        }

        // Configure request
        recognitionRequest.shouldReportPartialResults = true  // Get results as user speaks

        // Get input node
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Install tap on input node to get audio data
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        // Prepare and start audio engine
        audioEngine.prepare()

        do {
            try audioEngine.start()
            isRecording = true
            transcribedText = ""
            errorMessage = nil

            // Start recognition task
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }

                if let result = result {
                    // Update transcribed text
                    DispatchQueue.main.async {
                        self.transcribedText = result.bestTranscription.formattedString
                    }
                }

                if error != nil || result?.isFinal == true {
                    // Stop recording if error or final result
                    DispatchQueue.main.async {
                        self.stopRecording()
                    }
                }
            }

        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            stopRecording()
        }
    }

    /// Stop recording
    /// QA Note: This stops listening and finalizes transcription
    func stopRecording() {
        isRecording = false

        // Stop audio engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)

        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    /// Toggle recording on/off
    /// QA Note: Start or stop recording based on current state
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    /// Clear transcribed text
    /// QA Note: Clear the current transcription
    func clearText() {
        transcribedText = ""
    }

    // MARK: - Cleanup

    deinit {
        stopRecording()
    }
}

// MARK: - Authorization Status Extension

extension SFSpeechRecognizerAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .authorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
}
