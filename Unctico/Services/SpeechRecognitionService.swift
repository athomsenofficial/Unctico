import Foundation
import Speech
import AVFoundation

class SpeechRecognitionService: ObservableObject {
    static let shared = SpeechRecognitionService()

    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizer?.delegate = self as? SFSpeechRecognizerDelegate
    }

    // MARK: - Authorization

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
                completion(status == .authorized)
            }
        }
    }

    // MARK: - Recording Control

    func startRecording(completion: @escaping (String) -> Void) throws {
        // Cancel any ongoing recognition task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.recognitionRequestFailed
        }

        recognitionRequest.shouldReportPartialResults = true

        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognizedText = ""
        isRecording = true

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            var isFinal = false

            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                    completion(self.recognizedText)
                }
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
        }
    }

    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
    }

    // MARK: - Transcription

    func transcribeAudioFile(url: URL, completion: @escaping (String?) -> Void) {
        guard let speechRecognizer = speechRecognizer else {
            completion(nil)
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: url)

        speechRecognizer.recognitionTask(with: request) { result, error in
            if let result = result {
                completion(result.bestTranscription.formattedString)
            } else {
                completion(nil)
            }
        }
    }
}

// MARK: - Errors

enum SpeechRecognitionError: Error {
    case notAuthorized
    case recognitionRequestFailed
    case audioEngineFailed
    case recognizerUnavailable

    var localizedDescription: String {
        switch self {
        case .notAuthorized:
            return "Speech recognition not authorized. Please enable in Settings."
        case .recognitionRequestFailed:
            return "Failed to create speech recognition request."
        case .audioEngineFailed:
            return "Audio engine failed to start."
        case .recognizerUnavailable:
            return "Speech recognizer is not available for this locale."
        }
    }
}
