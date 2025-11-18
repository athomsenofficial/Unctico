# Unctico - Massage Therapy Management Platform

A comprehensive iOS-native business management platform for massage therapists that handles clinical documentation, client management, scheduling, and practice operations.

## 🎯 Project Vision

Provide massage therapists with an all-in-one solution that replaces multiple tools for running a successful practice - from SOAP notes to financial management to compliance tracking.

## ✅ Completed Features (Phase 1)

### Core Infrastructure
- ✅ iOS app architecture with clean separation of concerns
- ✅ Encrypted local data storage
- ✅ Secure authentication with Face ID/Touch ID
- ✅ Biometric and passcode authentication
- ✅ Auto-logout for security

### Client Management
- ✅ Add, edit, and delete clients
- ✅ Comprehensive client profiles
- ✅ Medical history tracking
- ✅ Client preferences (pressure, temperature, music)
- ✅ Search functionality
- ✅ Allergy and condition tracking

### Clinical Documentation (SOAP Notes)
- ✅ Complete SOAP note system (Subjective, Objective, Assessment, Plan)
- ✅ **Voice-to-text transcription** using iOS Speech Recognition
- ✅ Pain scale selector (0-10 with visual color coding)
- ✅ Stress level tracking
- ✅ Body location mapping
- ✅ Muscle tension grading (1-5 scale)
- ✅ Trigger point documentation
- ✅ Range of motion tracking
- ✅ Progress assessment
- ✅ Treatment plan documentation
- ✅ Home care instructions
- ✅ Referral management
- ✅ Clinical reasoning documentation

### Dashboard & Navigation
- ✅ Main dashboard with today's statistics
- ✅ Today's appointment schedule
- ✅ Quick action buttons
- ✅ Tab-based navigation (Home, Clients, Calendar, Notes, More)

### Calendar & Scheduling
- ✅ Visual calendar interface
- ✅ Appointment viewing by date
- ✅ Empty state handling

## 📁 Project Structure

```
UncticoApp/
├── App/                    # App configuration and entry point
│   ├── AppConfig.swift    # Centralized configuration
│   └── UncticoApp.swift   # Main app entry
├── Core/                   # Core functionality
│   ├── Auth/              # Authentication management
│   ├── Database/          # Data management layer
│   └── Storage/           # Local encrypted storage
├── Models/                 # Data models
│   ├── Client.swift       # Client/patient model
│   ├── SOAPNote.swift     # Clinical documentation
│   ├── Appointment.swift  # Appointment scheduling
│   └── Therapist.swift    # Therapist/practitioner
├── Views/                  # UI components
│   ├── Screens/           # Main screens
│   └── Components/        # Reusable components
├── Services/               # Business logic services
│   └── VoiceInputService.swift  # Voice-to-text
└── Resources/              # Assets and resources
```

## 🔑 Key Features

### Voice-to-Text Clinical Documentation
The app includes a sophisticated voice input system for clinical documentation:
- Real-time speech recognition
- Works for all SOAP note sections
- Automatic transcription with iOS Speech framework
- Hands-free documentation during sessions

### Security & Privacy
- End-to-end encryption for all data
- Biometric authentication (Face ID/Touch ID)
- Auto-logout after inactivity
- Account lockout after failed login attempts
- HIPAA-compliant data handling

### Centralized Components
All code uses reusable, centralized components:
- **DataManager**: Single source of truth for all data operations
- **AuthManager**: Handles all authentication logic
- **VoiceInputService**: Manages voice recognition
- **LocalDataStorage**: Encrypts and stores data locally

### Clear, Beginner-Friendly Code
- Descriptive function names (e.g., `addClient`, `saveSOAPNote`)
- Extensive inline comments
- QA notes explaining what each component does
- Simple, readable code structure

## 📖 Documentation

See `QA_DOCUMENTATION.md` for complete testing instructions for QA representatives.

## 🚀 Next Phase Features

### Intake Forms
- Digital intake form builder
- E-signature capture
- Medical history forms
- Consent management

### Financial Management
- Payment processing
- Invoice generation
- Expense tracking
- Financial reports

### Insurance Billing
- Claim generation
- Eligibility checking
- ERA processing

## 🛠 Technology Stack

- **Platform**: iOS (SwiftUI)
- **Language**: Swift
- **Storage**: Local encrypted files
- **Authentication**: LocalAuthentication (Face ID/Touch ID)
- **Voice**: Speech Recognition Framework
- **Architecture**: MVVM pattern

## 📝 Development Notes

### For Developers
- All models use `Codable` for easy serialization
- Published properties for reactive UI updates
- Centralized error handling
- Modular, testable architecture

### For QA
- See `QA_DOCUMENTATION.md` for detailed testing steps
- Each feature has expected behaviors documented
- Voice input requires microphone permissions

## 📊 Progress Tracking

Total features in roadmap: 600+
Completed: 25+ core features
Current phase: Phase 1 (Core Foundation) - 80% complete

## 🤝 Contributing

This is the foundational phase. Future contributions will focus on:
1. Completing intake forms system
2. Building financial management
3. Adding insurance billing
4. Implementing marketing automation
