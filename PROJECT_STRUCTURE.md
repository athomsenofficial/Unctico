# Unctico Project Structure

## Overview
Unctico is a comprehensive iOS app for massage therapy practice management, built with SwiftUI and following clean architecture principles.

## Directory Structure

```
Unctico/
├── App/
│   ├── UncticoApp.swift           # Main app entry point
│   └── MainTabView.swift          # Main tab navigation
│
├── Core/
│   ├── Authentication/
│   │   ├── AuthenticationManager.swift    # Handles login/logout
│   │   └── AuthenticationView.swift       # Login/register UI
│   │
│   ├── Database/
│   │   └── DatabaseManager.swift          # Core Data wrapper
│   │
│   ├── Security/
│   │   ├── KeychainManager.swift          # Secure storage (passwords, tokens)
│   │   └── EncryptionManager.swift        # HIPAA-compliant encryption
│   │
│   └── Utilities/
│       ├── AppStateManager.swift          # App-wide state management
│       ├── DateFormatters.swift           # Date formatting utilities
│       ├── CurrencyFormatter.swift        # Money formatting
│       └── Validator.swift                # Input validation
│
├── Features/
│   ├── Dashboard/
│   │   └── DashboardView.swift            # Main home screen
│   │
│   ├── Clients/
│   │   └── ClientsView.swift              # Client management
│   │
│   ├── Scheduling/
│   │   └── ScheduleView.swift             # Appointment calendar
│   │
│   ├── SOAPNotes/
│   │   └── SOAPNotesView.swift            # Clinical documentation
│   │
│   └── Billing/
│       └── BillingView.swift              # Invoicing & payments
│
├── Models/
│   ├── User.swift                         # Therapist user model
│   └── Client.swift                       # Client/patient model
│
└── Resources/
    └── Unctico.xcdatamodeld/              # Core Data model
```

## Architecture Principles

### 1. Clear Separation of Concerns
- **App**: Entry point and main navigation
- **Core**: Reusable infrastructure (auth, database, security)
- **Features**: Individual app features (clients, scheduling, etc.)
- **Models**: Data structures

### 2. Code Simplicity
All code is written to be:
- **Clear**: Like a toddler could read it
- **Well-commented**: Every file has a header explaining its purpose
- **Self-documenting**: Function and variable names explain what they do
- **No duplication**: Shared code lives in Core/Utilities

### 3. Security First
- Passwords and tokens stored in **Keychain** (never UserDefaults)
- SOAP notes and medical data **encrypted** using AES-256
- HIPAA compliance built into the database layer

### 4. SwiftUI Best Practices
- Environment objects for dependency injection
- State management with @Published and @State
- Reusable components extracted into separate structs
- Preview providers for every view

## Key Components

### Authentication Flow
1. User opens app → `UncticoApp` checks authentication
2. Not logged in → Show `AuthenticationView`
3. Login successful → `AuthenticationManager` saves token to Keychain
4. Logged in → Show `MainTabView`

### Data Flow
1. UI views use `@EnvironmentObject` to access managers
2. Managers (`DatabaseManager`, `AuthenticationManager`) handle business logic
3. Models (`Client`, `User`) represent data
4. Core Data entities persist data to disk

### Security Flow
1. User enters sensitive data (SOAP notes)
2. `EncryptionManager` encrypts using AES-256
3. Encrypted data saved to Core Data
4. When displaying, data is decrypted on-the-fly

## Next Steps (Phase 1, Sprints 3-4)

- [ ] Implement Core Data entities as Swift classes
- [ ] Build SOAP notes with voice-to-text
- [ ] Create detailed intake forms
- [ ] Add session documentation
- [ ] Implement client medical history

## Development Guidelines

1. **Every new file should have a header comment** explaining what it does
2. **No magic numbers** - use named constants
3. **Reuse utilities** - check Core/Utilities before creating new formatters
4. **Keep functions small** - one function, one purpose
5. **Handle errors gracefully** - always show user-friendly messages

## Testing Strategy

- Unit tests for managers (`AuthenticationManager`, `DatabaseManager`)
- Integration tests for database operations
- UI tests for critical flows (login, creating clients)
- Preview providers for visual testing during development

---

**Built with ❤️ for massage therapists**
