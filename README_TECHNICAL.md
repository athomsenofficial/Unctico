# Unctico - Technical Documentation

## iOS Massage Therapy Practice Management Application

### Architecture Overview

**Platform**: iOS 16+
**Framework**: SwiftUI
**Architecture**: MVVM (Model-View-ViewModel)
**Language**: Swift 5.9+

### Project Structure

```
Unctico/
├── UncticoApp.swift              # Main app entry point
├── Core/
│   ├── AppState.swift            # Global app state management
│   └── RootView.swift            # Root navigation coordinator
├── Models/
│   ├── Client.swift              # Client data model with preferences & medical history
│   ├── SOAPNote.swift            # SOAP notes (Subjective, Objective, Assessment, Plan)
│   └── Appointment.swift         # Appointment scheduling model
├── Views/
│   ├── Authentication/
│   │   └── AuthenticationView.swift
│   ├── Dashboard/
│   │   └── DashboardView.swift   # Main dashboard with metrics
│   ├── Clients/
│   │   └── ClientsView.swift     # Client management & profiles
│   ├── Schedule/
│   │   └── ScheduleView.swift    # Appointment calendar
│   ├── Documentation/
│   │   └── DocumentationView.swift  # SOAP notes interface
│   ├── Financial/
│   │   └── FinancialView.swift   # Financial tracking
│   └── Settings/
│       └── SettingsView.swift    # App settings & configuration
└── Theme/
    └── ColorTheme.swift          # Calming, spa-like color scheme

```

### Design Philosophy

#### Massage-Specific Ideology

The UI/UX is designed around the **calming, therapeutic nature** of massage therapy:

1. **Calming Color Palette**
   - Tranquil Teal: Primary actions
   - Soothing Green: Success states, revenue
   - Calming Blue: Information, clinical data
   - Soft Lavender: Secondary elements
   - Warm Beige: Backgrounds

2. **Streamlined Interactions**
   - Minimal cognitive load
   - Quick access to frequently used features
   - Voice input for clinical notes (hands-free documentation)
   - Large touch targets for easy interaction

3. **Professional Yet Approachable**
   - Clean, modern interface
   - Soft shadows and rounded corners
   - Ample white space
   - Therapeutic imagery (figure.walk icon)

### Key Features Implemented

#### 1. Authentication
- Biometric authentication support
- Secure login flow
- Session management

#### 2. Dashboard
- Today's appointments overview
- Weekly revenue metrics
- Quick action cards
- Pending tasks tracking

#### 3. Client Management
- Comprehensive client profiles
- Medical history tracking
- Preferences (pressure, temperature, music)
- Contact information management
- Quick actions (book, message, view notes)

#### 4. SOAP Notes
- Four-section clinical documentation
- Voice-to-text input capability
- Pain scale tracking (0-10)
- Body location mapping
- Treatment response tracking
- Home care instructions
- Follow-up planning

#### 5. Appointment Scheduling
- Day/Week/Month views
- Service type categorization
- Duration management
- Status tracking (scheduled, confirmed, in progress, completed)
- Visual timeline

#### 6. Financial Management
- Revenue vs. expenses tracking
- Period-based filtering
- Transaction history
- Quick actions (payments, expenses, invoices)
- Net income calculation

#### 7. Settings
- Business information
- Services & pricing configuration
- HIPAA compliance tools
- License management
- Backup & sync
- Theme customization

### Code Principles

#### Clean, Readable Code
- **Single Responsibility**: Each view and component has one clear purpose
- **Reusable Components**:
  - `SectionCard`: Reusable card wrapper
  - `StatusBadge`: Consistent status indicators
  - `EmptyStateView`: Standard empty state messaging
  - `QuickActionButton`: Uniform action buttons

#### Streamlined Structure
- Views broken into logical, composable components
- No code duplication
- Consistent naming conventions
- Clear separation of concerns

#### Example Pattern - Reusable Components

```swift
// Single function for creating action cards
struct ActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    // Single implementation used throughout the app
}
```

### Data Models

#### Client Model
- Personal information
- Contact details
- Medical history (conditions, medications, allergies)
- Preferences (pressure, temperature, communication)
- Codable for persistence

#### SOAP Note Model
- **Subjective**: Chief complaint, pain level, sleep, stress
- **Objective**: Body locations, muscle tension, ROM, trigger points
- **Assessment**: Diagnosis, progress, treatment response
- **Plan**: Frequency, home care, exercises, follow-up

#### Appointment Model
- Service types (Swedish, Deep Tissue, Sports, Prenatal, etc.)
- Scheduling information
- Status tracking
- Duration management

### Privacy & Compliance

#### HIPAA Considerations
- Encrypted data storage
- Secure authentication
- Audit logging capability
- Privacy-first design

#### Permissions Required
- Speech Recognition (voice-to-text SOAP notes)
- Microphone (voice input)
- Camera (before/after photos)
- Photo Library (clinical documentation)
- Location (mileage tracking for mobile therapists)

### Next Development Phases

#### Phase 1 Completion ✅
- ✅ Core navigation structure
- ✅ Client management
- ✅ SOAP notes interface
- ✅ Basic scheduling
- ✅ Dashboard metrics
- ✅ Financial overview

#### Phase 2 Priorities
- [ ] Core Data integration for persistence
- [ ] Voice recognition implementation
- [ ] Payment processing integration
- [ ] PDF invoice generation
- [ ] Email/SMS communication
- [ ] iCloud sync

#### Phase 3 Priorities
- [ ] Insurance billing (CMS-1500 forms)
- [ ] Advanced analytics
- [ ] Automated marketing campaigns
- [ ] Team management features
- [ ] Inventory tracking

### Technology Stack

- **UI**: SwiftUI
- **Data Persistence**: Core Data (to be implemented)
- **Voice Input**: Speech framework
- **Networking**: URLSession / Combine
- **Authentication**: LocalAuthentication (Face ID / Touch ID)
- **Cloud Sync**: iCloud / CloudKit
- **Payment Processing**: Stripe / Square (integration planned)

### Coding Standards

1. **Naming**: Clear, descriptive names
2. **Comments**: Only when necessary (self-documenting code preferred)
3. **File Organization**: Grouped by feature, not type
4. **SwiftUI Best Practices**:
   - View extraction for complex UIs
   - @State for local state
   - @EnvironmentObject for shared state
   - @Binding for parent-child communication

### Performance Considerations

- Lazy loading of lists
- Efficient state management
- Minimize view re-renders
- Background data processing
- Image optimization
- Offline-first architecture (planned)

---

**Status**: Initial frontend implementation complete
**Next Steps**: Database integration, voice recognition, and payment processing
