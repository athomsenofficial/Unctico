// VoiceTranscriptionManager.swift
// Handles speech-to-text transcription for SOAP notes

import Foundation
import Speech
import AVFoundation

/// Manages voice-to-text transcription using iOS Speech Recognition
/// This allows therapists to dictate SOAP notes hands-free
class VoiceTranscriptionManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    /// Current transcribed text
    @Published var transcribedText: String = ""

    /// Is currently recording?
    @Published var isRecording: Bool = false

    /// Is speech recognition available?
    @Published var isAvailable: Bool = false

    /// Authorization status
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    /// Any error message
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - Initialization

    override init() {
        // Initialize with user's locale
        self.speechRecognizer = SFSpeechRecognizer()

        super.init()

        // Check if speech recognition is available
        self.isAvailable = speechRecognizer?.isAvailable ?? false

        // Observe availability changes
        speechRecognizer?.delegate = self
    }

    // MARK: - Public Methods

    /// Request authorization for speech recognition
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                self?.isAvailable = status == .authorized && (self?.speechRecognizer?.isAvailable ?? false)
            }
        }
    }

    /// Start recording and transcribing
    func startRecording() {
        // Check authorization
        guard authorizationStatus == .authorized else {
            errorMessage = "Speech recognition not authorized"
            return
        }

        // Check if already recording
        guard !isRecording else { return }

        // Check if available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition not available"
            return
        }

        do {
            // Cancel any existing task
            if let recognitionTask = recognitionTask {
                recognitionTask.cancel()
                self.recognitionTask = nil
            }

            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            // Create recognition request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

            guard let recognitionRequest = recognitionRequest else {
                errorMessage = "Unable to create recognition request"
                return
            }

            recognitionRequest.shouldReportPartialResults = true

            // Get input node
            let inputNode = audioEngine.inputNode

            // Start recognition task
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                if let result = result {
                    DispatchQueue.main.async {
                        self?.transcribedText = result.bestTranscription.formattedString
                    }
                }

                if error != nil || result?.isFinal == true {
                    self?.stopRecording()
                }
            }

            // Configure input node
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }

            // Start audio engine
            audioEngine.prepare()
            try audioEngine.start()

            DispatchQueue.main.async {
                self.isRecording = true
                self.errorMessage = nil
            }

        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to start recording: \(error.localizedDescription)"
            }
        }
    }

    /// Stop recording and transcribing
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        DispatchQueue.main.async {
            self.isRecording = false
        }
    }

    /// Clear the transcribed text
    func clearTranscription() {
        transcribedText = ""
    }

    /// Append text to current transcription
    /// - Parameter text: Text to append
    func appendText(_ text: String) {
        if transcribedText.isEmpty {
            transcribedText = text
        } else {
            transcribedText += " " + text
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension VoiceTranscriptionManager: SFSpeechRecognizerDelegate {

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            self.isAvailable = available
            if !available {
                self.errorMessage = "Speech recognition is not available"
            }
        }
    }
}
