import Foundation

/// Voice recognition and speech-to-text models for SOAP note dictation
/// TODO: Integrate speech recognition service (Apple Speech, Google Cloud Speech, or OpenAI Whisper)

// MARK: - Voice Transcription

struct VoiceTranscription: Identifiable, Codable {
    let id: UUID
    var audioFileUrl: String? // Local file path
    var transcribedText: String
    var confidence: Double // 0-100
    var language: String
    var duration: TimeInterval // Audio duration in seconds
    var transcriptionDate: Date
    var transcriptionService: TranscriptionService
    var status: TranscriptionStatus
    var linkedSOAPNoteId: UUID?
    var linkedAppointmentId: UUID?
    var segments: [TranscriptionSegment]

    init(
        id: UUID = UUID(),
        audioFileUrl: String? = nil,
        transcribedText: String,
        confidence: Double,
        language: String = "en-US",
        duration: TimeInterval = 0,
        transcriptionDate: Date = Date(),
        transcriptionService: TranscriptionService,
        status: TranscriptionStatus = .completed,
        linkedSOAPNoteId: UUID? = nil,
        linkedAppointmentId: UUID? = nil,
        segments: [TranscriptionSegment] = []
    ) {
        self.id = id
        self.audioFileUrl = audioFileUrl
        self.transcribedText = transcribedText
        self.confidence = confidence
        self.language = language
        self.duration = duration
        self.transcriptionDate = transcriptionDate
        self.transcriptionService = transcriptionService
        self.status = status
        self.linkedSOAPNoteId = linkedSOAPNoteId
        self.linkedAppointmentId = linkedAppointmentId
        self.segments = segments
    }

    var isHighConfidence: Bool {
        confidence >= 80
    }

    var wordCount: Int {
        transcribedText.split(separator: " ").count
    }

    var wordsPerMinute: Double {
        guard duration > 0 else { return 0 }
        return Double(wordCount) / (duration / 60)
    }
}

enum TranscriptionService: String, Codable {
    case appleSpeech = "Apple Speech Framework"
    case googleCloud = "Google Cloud Speech-to-Text"
    case openaiWhisper = "OpenAI Whisper"
    case assemblyAI = "AssemblyAI"
    case deepgram = "Deepgram"

    var supportsRealTime: Bool {
        switch self {
        case .appleSpeech, .googleCloud, .deepgram:
            return true
        case .openaiWhisper, .assemblyAI:
            return false // Batch processing only
        }
    }

    var supportsMedicalVocabulary: Bool {
        switch self {
        case .googleCloud, .assemblyAI:
            return true // Can be configured with medical terminology
        case .appleSpeech, .openaiWhisper, .deepgram:
            return false
        }
    }
}

enum TranscriptionStatus: String, Codable {
    case recording = "Recording"
    case processing = "Processing"
    case completed = "Completed"
    case failed = "Failed"
    case needsReview = "Needs Review"
}

// MARK: - Transcription Segment

struct TranscriptionSegment: Identifiable, Codable {
    let id: UUID
    var text: String
    var startTime: TimeInterval // Seconds from start
    var endTime: TimeInterval
    var confidence: Double
    var speaker: Int? // Speaker ID for multi-speaker scenarios

    init(
        id: UUID = UUID(),
        text: String,
        startTime: TimeInterval,
        endTime: TimeInterval,
        confidence: Double,
        speaker: Int? = nil
    ) {
        self.id = id
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.confidence = confidence
        self.speaker = speaker
    }

    var duration: TimeInterval {
        endTime - startTime
    }
}

// MARK: - Voice Command

struct VoiceCommand: Codable {
    let command: String
    let action: VoiceCommandAction
    let aliases: [String]

    init(command: String, action: VoiceCommandAction, aliases: [String] = []) {
        self.command = command
        self.action = action
        self.aliases = aliases
    }
}

enum VoiceCommandAction: String, Codable {
    // SOAP Note sections
    case startSubjective = "Start Subjective"
    case startObjective = "Start Objective"
    case startAssessment = "Start Assessment"
    case startPlan = "Start Plan"

    // Formatting
    case newParagraph = "New Paragraph"
    case newLine = "New Line"
    case addBulletPoint = "Add Bullet Point"

    // Editing
    case undoLast = "Undo Last"
    case deleteLast = "Delete Last"
    case clearSection = "Clear Section"

    // Navigation
    case saveNote = "Save Note"
    case completeNote = "Complete Note"
    case cancelDictation = "Cancel Dictation"
}

// MARK: - Medical Vocabulary

struct MedicalVocabulary: Codable {
    let terms: [MedicalTerm]
    let abbreviations: [String: String] // Abbreviation -> Full term
    let commonPhrases: [String]

    init(
        terms: [MedicalTerm] = [],
        abbreviations: [String: String] = [:],
        commonPhrases: [String] = []
    ) {
        self.terms = terms
        self.abbreviations = abbreviations
        self.commonPhrases = commonPhrases
    }

    static var massageTherapyDefault: MedicalVocabulary {
        return MedicalVocabulary(
            terms: [
                // Body parts
                MedicalTerm(term: "trapezius", category: .anatomy),
                MedicalTerm(term: "latissimus dorsi", category: .anatomy),
                MedicalTerm(term: "gastrocnemius", category: .anatomy),
                MedicalTerm(term: "soleus", category: .anatomy),
                MedicalTerm(term: "quadriceps", category: .anatomy),
                MedicalTerm(term: "hamstrings", category: .anatomy),
                MedicalTerm(term: "gluteal", category: .anatomy),
                MedicalTerm(term: "pectoralis", category: .anatomy),
                MedicalTerm(term: "deltoid", category: .anatomy),
                MedicalTerm(term: "cervical", category: .anatomy),
                MedicalTerm(term: "thoracic", category: .anatomy),
                MedicalTerm(term: "lumbar", category: .anatomy),
                MedicalTerm(term: "sacral", category: .anatomy),

                // Conditions
                MedicalTerm(term: "myalgia", category: .diagnosis),
                MedicalTerm(term: "fibromyalgia", category: .diagnosis),
                MedicalTerm(term: "sciatica", category: .diagnosis),
                MedicalTerm(term: "tendinitis", category: .diagnosis),
                MedicalTerm(term: "bursitis", category: .diagnosis),
                MedicalTerm(term: "edema", category: .observation),
                MedicalTerm(term: "erythema", category: .observation),
                MedicalTerm(term: "atrophy", category: .observation),
                MedicalTerm(term: "hypertrophy", category: .observation),

                // Techniques
                MedicalTerm(term: "effleurage", category: .technique),
                MedicalTerm(term: "petrissage", category: .technique),
                MedicalTerm(term: "tapotement", category: .technique),
                MedicalTerm(term: "friction", category: .technique),
                MedicalTerm(term: "myofascial release", category: .technique),
                MedicalTerm(term: "trigger point therapy", category: .technique),
                MedicalTerm(term: "deep tissue", category: .technique),
                MedicalTerm(term: "Swedish massage", category: .technique),
                MedicalTerm(term: "sports massage", category: .technique),

                // Assessments
                MedicalTerm(term: "range of motion", category: .assessment),
                MedicalTerm(term: "palpation", category: .assessment),
                MedicalTerm(term: "postural assessment", category: .assessment),
                MedicalTerm(term: "gait analysis", category: .assessment)
            ],
            abbreviations: [
                "ROM": "range of motion",
                "TP": "trigger point",
                "MT": "massage therapy",
                "STM": "soft tissue mobilization",
                "MFR": "myofascial release",
                "DTM": "deep tissue massage",
                "LMT": "licensed massage therapist",
                "SOAP": "subjective objective assessment plan"
            ],
            commonPhrases: [
                "Client reports",
                "Upon palpation",
                "Notable tension in",
                "Restricted range of motion",
                "Decreased flexibility",
                "Tenderness to touch",
                "Client tolerated treatment well",
                "No adverse reactions",
                "Home care instructions provided",
                "Follow up in"
            ]
        )
    }
}

struct MedicalTerm: Codable {
    let term: String
    let category: TermCategory
    let pronunciation: String?

    init(term: String, category: TermCategory, pronunciation: String? = nil) {
        self.term = term
        self.category = category
        self.pronunciation = pronunciation
    }
}

enum TermCategory: String, Codable {
    case anatomy = "Anatomy"
    case diagnosis = "Diagnosis"
    case observation = "Observation"
    case technique = "Technique"
    case assessment = "Assessment"
    case treatment = "Treatment"
}

// MARK: - Dictation Session

struct DictationSession: Identifiable, Codable {
    let id: UUID
    var appointmentId: UUID?
    var soapNoteId: UUID?
    var startTime: Date
    var endTime: Date?
    var currentSection: SOAPSection
    var transcriptions: [VoiceTranscription]
    var status: DictationStatus
    var autoSaveEnabled: Bool

    init(
        id: UUID = UUID(),
        appointmentId: UUID? = nil,
        soapNoteId: UUID? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        currentSection: SOAPSection = .subjective,
        transcriptions: [VoiceTranscription] = [],
        status: DictationStatus = .active,
        autoSaveEnabled: Bool = true
    ) {
        self.id = id
        self.appointmentId = appointmentId
        self.soapNoteId = soapNoteId
        self.startTime = startTime
        self.endTime = endTime
        self.currentSection = currentSection
        self.transcriptions = transcriptions
        self.status = status
        self.autoSaveEnabled = autoSaveEnabled
    }

    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }

    var totalWords: Int {
        transcriptions.reduce(0) { $0 + $1.wordCount }
    }
}

enum DictationStatus: String, Codable {
    case active = "Active"
    case paused = "Paused"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

enum SOAPSection: String, Codable {
    case subjective = "Subjective"
    case objective = "Objective"
    case assessment = "Assessment"
    case plan = "Plan"
}

// MARK: - Audio Recording Settings

struct AudioRecordingSettings: Codable {
    var sampleRate: Double // Hz (e.g., 16000, 44100)
    var bitDepth: Int // Bits (e.g., 16, 24)
    var channels: Int // 1 = mono, 2 = stereo
    var format: AudioFormat
    var quality: AudioQuality

    init(
        sampleRate: Double = 16000, // 16kHz is standard for speech
        bitDepth: Int = 16,
        channels: Int = 1, // Mono for speech
        format: AudioFormat = .wav,
        quality: AudioQuality = .medium
    ) {
        self.sampleRate = sampleRate
        self.bitDepth = bitDepth
        self.channels = channels
        self.format = format
        self.quality = quality
    }

    static var optimizedForSpeech: AudioRecordingSettings {
        return AudioRecordingSettings(
            sampleRate: 16000,
            bitDepth: 16,
            channels: 1,
            format: .wav,
            quality: .medium
        )
    }
}

enum AudioFormat: String, Codable {
    case wav = "WAV"
    case mp3 = "MP3"
    case m4a = "M4A"
    case flac = "FLAC"
}

enum AudioQuality: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case maximum = "Maximum"

    var bitrate: Int {
        switch self {
        case .low: return 32000 // 32 kbps
        case .medium: return 64000 // 64 kbps
        case .high: return 128000 // 128 kbps
        case .maximum: return 256000 // 256 kbps
        }
    }
}

// MARK: - Statistics

struct VoiceRecognitionStatistics {
    let totalTranscriptions: Int
    let totalDuration: TimeInterval // Total audio hours transcribed
    let averageConfidence: Double
    let totalWords: Int
    let averageWordsPerMinute: Double
    let mostUsedService: TranscriptionService?
    let successRate: Double // Percentage of successful transcriptions

    init(
        totalTranscriptions: Int = 0,
        totalDuration: TimeInterval = 0,
        averageConfidence: Double = 0,
        totalWords: Int = 0,
        averageWordsPerMinute: Double = 0,
        mostUsedService: TranscriptionService? = nil,
        successRate: Double = 0
    ) {
        self.totalTranscriptions = totalTranscriptions
        self.totalDuration = totalDuration
        self.averageConfidence = averageConfidence
        self.totalWords = totalWords
        self.averageWordsPerMinute = averageWordsPerMinute
        self.mostUsedService = mostUsedService
        self.successRate = successRate
    }
}

/*
 VOICE RECOGNITION INTEGRATION OPTIONS:

 1. Apple Speech Framework (On-Device)
    Pros:
    - Free, built-in
    - Works offline
    - Privacy-focused (on-device processing)
    - Real-time transcription
    - Good for English

    Cons:
    - Limited language support
    - No medical vocabulary customization
    - Lower accuracy than cloud services
    - Requires user permission

    Implementation:
    import Speech
    - Request authorization: SFSpeechRecognizer.requestAuthorization()
    - Create recognizer: SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    - Use SFSpeechAudioBufferRecognitionRequest for real-time
    - Or SFSpeechURLRecognitionRequest for audio files

 2. Google Cloud Speech-to-Text
    Pros:
    - High accuracy
    - Medical vocabulary support
    - 120+ languages
    - Real-time and batch processing
    - Speaker diarization
    - Automatic punctuation

    Cons:
    - Requires internet
    - Paid service ($0.006/15 seconds)
    - Privacy concerns (cloud processing)

    API:
    POST https://speech.googleapis.com/v1/speech:recognize
    {
      "config": {
        "encoding": "LINEAR16",
        "sampleRateHertz": 16000,
        "languageCode": "en-US",
        "enableAutomaticPunctuation": true,
        "model": "medical_dictation" // For medical terminology
      },
      "audio": {
        "content": "base64_encoded_audio"
      }
    }

 3. OpenAI Whisper
    Pros:
    - Excellent accuracy
    - Multilingual (99 languages)
    - Can run locally or via API
    - Open source model available
    - Good with accents and noise

    Cons:
    - Batch processing only (not real-time)
    - API costs $0.006/minute
    - Slower than real-time services
    - Local model requires significant compute

    API:
    POST https://api.openai.com/v1/audio/transcriptions
    Headers:
      Authorization: Bearer YOUR_API_KEY
    Body: multipart/form-data
      file: audio.wav
      model: whisper-1
      language: en
      response_format: json

 4. AssemblyAI
    Pros:
    - Medical transcription model
    - Speaker diarization
    - Automatic chapter detection
    - Sentiment analysis
    - PII redaction (HIPAA-ready)

    Cons:
    - Paid service
    - Batch processing only
    - Requires internet

 5. Deepgram
    Pros:
    - Real-time streaming
    - Medical terminology support
    - Low latency
    - Custom vocabulary
    - Competitive pricing

    Cons:
    - Paid service
    - Newer platform
    - Requires internet

 RECOMMENDED APPROACH:

 Primary: Apple Speech Framework
 - Free, on-device, real-time
 - Good for quick notes during sessions
 - Privacy-compliant

 Fallback/Enhancement: OpenAI Whisper API
 - For recorded audio that needs higher accuracy
 - Batch processing after session
 - Better handling of medical terms with custom prompts

 IMPLEMENTATION CHECKLIST:

 1. Audio Recording:
    - Request microphone permission
    - Use AVAudioRecorder or AVAudioEngine
    - Save to temporary file
    - Support pause/resume

 2. Real-time Transcription (Apple Speech):
    - Create SFSpeechRecognizer
    - Set up audio buffer
    - Handle partial results
    - Display live transcription

 3. Batch Processing (Whisper):
    - Upload audio file
    - Poll for completion
    - Retrieve transcription
    - Parse and format

 4. Voice Commands:
    - Detect command phrases
    - Execute actions (navigate sections, format text)
    - Provide audio feedback

 5. Medical Vocabulary:
    - Build custom dictionary
    - Post-process transcription
    - Replace common errors
    - Suggest corrections

 6. HIPAA Compliance:
    - Encrypt audio files at rest
    - Secure transmission
    - Audit logging
    - Data retention policy
    - Patient consent
 */
