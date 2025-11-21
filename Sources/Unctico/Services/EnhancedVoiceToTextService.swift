//
//  EnhancedVoiceToTextService.swift
//  Unctico
//
//  Enhanced voice-to-text transcription service with quick phrases library
//  Ported from MassageTherapySOAP project
//

import Foundation
import Speech
import AVFoundation
import Combine

final class EnhancedVoiceToTextService: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var errorMessage: String?
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    // MARK: - Private Properties

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - Initialization

    override init() {
        super.init()
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                self?.handleAuthorizationStatus(status)
            }
        }
    }

    private func checkAuthorizationStatus() {
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }

    private func handleAuthorizationStatus(_ status: SFSpeechRecognizerAuthorizationStatus) {
        switch status {
        case .authorized:
            print("Speech recognition authorized")
        case .denied:
            errorMessage = "Speech recognition access denied"
        case .restricted:
            errorMessage = "Speech recognition restricted on this device"
        case .notDetermined:
            errorMessage = "Speech recognition not yet authorized"
        @unknown default:
            errorMessage = "Unknown authorization status"
        }
    }

    // MARK: - Recording Control

    func startRecording() {
        // Cancel any existing task
        stopRecording()

        // Check authorization
        guard authorizationStatus == .authorized else {
            errorMessage = "Speech recognition not authorized"
            return
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to configure audio session: \(error.localizedDescription)"
            return
        }

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create recognition request"
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
            return
        }

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
            }

            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Recognition error: \(error.localizedDescription)"
                    self.stopRecording()
                }
            }
        }

        isRecording = true

        AuditLogger.shared.log(
            event: .userAction,
            details: "Voice-to-text recording started"
        )
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isRecording = false

        AuditLogger.shared.log(
            event: .userAction,
            details: "Voice-to-text recording stopped. Transcribed \(transcribedText.count) characters"
        )
    }

    func clearTranscription() {
        transcribedText = ""
    }

    // MARK: - Text Processing

    func appendToTranscription(_ text: String) {
        if !transcribedText.isEmpty {
            transcribedText += " "
        }
        transcribedText += text
    }

    func replaceTranscription(_ text: String) {
        transcribedText = text
    }
}

// MARK: - Quick Phrases Library

final class QuickPhrasesLibrary {
    static let shared = QuickPhrasesLibrary()

    let commonPhrases: [PhraseCategory: [String]] = [
        .painDescriptions: [
            "Sharp, stabbing pain",
            "Dull, aching pain",
            "Burning sensation",
            "Throbbing pain",
            "Tingling or numbness",
            "Radiating pain",
            "Constant discomfort",
            "Intermittent pain"
        ],
        .locations: [
            "Lower back",
            "Upper back between shoulder blades",
            "Right shoulder",
            "Left shoulder",
            "Neck and upper trapezius",
            "Hip and gluteal region",
            "Hamstring and posterior thigh",
            "Calf muscles"
        ],
        .duration: [
            "Started this morning",
            "Ongoing for several days",
            "Chronic, present for weeks",
            "Recurring issue",
            "New onset today",
            "Worsening over the past week"
        ],
        .activities: [
            "Pain worse with sitting",
            "Discomfort increases with standing",
            "Pain during physical activity",
            "Stiffness in the morning",
            "Worse at end of day",
            "Aggravated by exercise"
        ],
        .previousTreatment: [
            "Previous massage provided relief",
            "Ice application helps",
            "Heat reduces symptoms",
            "Stretching provides temporary relief",
            "Over-the-counter pain medication taken",
            "No previous treatment attempted"
        ],
        .goals: [
            "Reduce pain and discomfort",
            "Improve range of motion",
            "Increase flexibility",
            "Reduce muscle tension",
            "Improve sleep quality",
            "Return to normal activities"
        ]
    ]

    func getAllPhrases() -> [String] {
        return commonPhrases.values.flatMap { $0 }
    }

    func getPhrases(for category: PhraseCategory) -> [String] {
        return commonPhrases[category] ?? []
    }

    func searchPhrases(_ query: String) -> [String] {
        let lowercasedQuery = query.lowercased()
        return getAllPhrases().filter { phrase in
            phrase.lowercased().contains(lowercasedQuery)
        }
    }
}

enum PhraseCategory: String, CaseIterable {
    case painDescriptions = "Pain Descriptions"
    case locations = "Body Locations"
    case duration = "Duration"
    case activities = "Aggravating Activities"
    case previousTreatment = "Previous Treatment"
    case goals = "Treatment Goals"
}
