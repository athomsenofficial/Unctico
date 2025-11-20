# Unctico Local Setup Guide

## Project Overview

**Unctico** is a comprehensive iOS-native business management platform for massage therapists built with SwiftUI and Swift 6.2.

## Repository Analysis

### Branches Analyzed:
1. **main** - Contains planning documentation only
2. **claude/build-frontend-tasklist-01CUzLuMDkkBiY25KsQvdu6R** - Most complete implementation with Phase 3 features
3. **claude/access-unctico-01NgP3AfZwi7jaW9TBETFuSv** - Front-end design tasks and structured code
4. **claude/github-app-creation-01MPYe5XWLVLJQERDCdmEfQL** - Phase 1 core foundation

### Current Branch: claude/build-frontend-tasklist-01CUzLuMDkkBiY25KsQvdu6R

This is the most feature-complete branch with:
- ✅ Complete SOAP notes system
- ✅ Client management with intake forms
- ✅ Appointment scheduling with calendar
- ✅ Payment processing and invoicing
- ✅ Insurance billing and claims management
- ✅ Advanced analytics and reporting
- ✅ Team/staff management
- ✅ Marketing automation

## Project Structure

```
Unctico/
├── Unctico/
│   ├── Assets.xcassets/     # App images and assets
│   ├── Core/                # Core app functionality
│   ├── Data/                # Data persistence layer
│   ├── Models/              # Data models
│   ├── Services/            # Business logic services
│   ├── Theme/               # UI theming
│   ├── Views/               # SwiftUI views
│   ├── Preview Content/     # Preview assets
│   ├── Info.plist          # App configuration
│   └── UncticoApp.swift    # App entry point
├── Package.swift            # Swift Package configuration
└── README_*.md             # Documentation files
```

## Current Status

### ⚠️ IMPORTANT: Xcode Required

This is an **iOS application** that requires:
- **Xcode 15+** (for iOS 16+ development)
- **macOS 13+**
- **iOS Simulator** or physical iOS device

The current environment has Swift 6.2 available but **does not have Xcode installed**, which means:
- ❌ Cannot build the iOS app
- ❌ Cannot run in iOS Simulator
- ❌ Cannot launch the application GUI

### What IS Available:
- ✅ All source code is downloaded
- ✅ All branches have been reviewed
- ✅ Project structure is intact
- ✅ Swift compiler is available (but only for macOS, not iOS)

## How to Set Up and Run Locally

### Prerequisites:
1. Install Xcode from the Mac App Store (free)
2. Open Xcode and install additional components when prompted
3. Accept Xcode license: `sudo xcodebuild -license accept`

### Setup Steps:

#### Option 1: Create Xcode Project (Recommended)

1. **Open Xcode**

2. **Create New Project:**
   - File → New → Project
   - Choose "iOS" → "App"
   - Product Name: `Unctico`
   - Team: Your development team
   - Organization Identifier: `com.yourcompany.unctico`
   - Interface: SwiftUI
   - Language: Swift
   - Click "Next" and choose a location

3. **Replace Source Files:**
   ```bash
   # Navigate to your new Xcode project
   cd ~/path/to/your/new/Unctico

   # Copy the Unctico source code
   rm -rf Unctico/*
   cp -r /Users/drew/Coding/Programs/Unctico/Unctico/* Unctico/
   ```

4. **Add Files to Xcode:**
   - Drag all folders from `Unctico/` directory into Xcode's Project Navigator
   - Check "Copy items if needed"
   - Check "Create groups"
   - Select your target

5. **Build and Run:**
   - Select a simulator (e.g., iPhone 15 Pro)
   - Click the "Play" button or press Cmd+R

#### Option 2: Open with Swift Package

1. **Open Terminal and navigate:**
   ```bash
   cd /Users/drew/Coding/Programs/Unctico
   ```

2. **Open in Xcode:**
   ```bash
   open Package.swift
   ```

   Note: This will open as a package, but you'll need to create a scheme to run the app.

3. **Create an App Target:**
   - In Xcode: File → New → Target
   - Choose "iOS" → "App"
   - Configure and link to the package

### Running the App:

Once set up in Xcode:

```bash
# Build the project
xcodebuild -scheme Unctico -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Or use Xcode GUI:
# 1. Open project in Xcode
# 2. Select simulator
# 3. Press Cmd+R to build and run
```

## Key Features Available for Testing

### 1. Client Management (Unctico/Views/Clients/)
- Create and manage client profiles
- Digital intake forms
- Medical history tracking
- Consent forms

### 2. SOAP Notes (Unctico/Views/SOAPNotes/)
- Subjective documentation with voice-to-text
- Objective assessment tools
- Assessment and planning
- Session documentation

### 3. Scheduling (Unctico/Views/Schedule/)
- Calendar view
- Appointment booking
- Availability management
- Automated reminders

### 4. Payments (Unctico/Services/PaymentService.swift)
- Payment processing
- Invoice generation
- Payment tracking

### 5. Insurance Billing (Unctico/Services/InsuranceBillingService.swift)
- Eligibility verification
- Claims generation
- ERA processing
- Denial management

### 6. Analytics (Unctico/Services/AnalyticsService.swift)
- Revenue tracking
- Client analytics
- Performance metrics
- Custom reports

### 7. Team Management (Unctico/Services/TeamManagementService.swift)
- Staff scheduling
- Performance tracking
- Commission calculations

## Database & Data Storage

The app uses SwiftData (iOS native) for data persistence:
- Location: `Unctico/Data/`
- Automatic iCloud sync support
- Encrypted local storage

## Testing the App

### Manual Testing Flow:
1. **Launch app** → Should show onboarding/login screen
2. **Create account** → Set up practice information
3. **Add a client** → Test intake form flow
4. **Create SOAP note** → Test clinical documentation
5. **Schedule appointment** → Test calendar functionality
6. **Process payment** → Test payment flow (use test mode)
7. **View analytics** → Check dashboard and reports

### Test Data:
The app includes sample data generators for testing. Check:
- `Unctico/Data/SampleData.swift` (if exists)
- Preview providers in view files

## Known Issues & Limitations

1. **No Xcode Project File**: The repository contains source code but not a full Xcode project
2. **Package.swift Configuration**: May need adjustment for iOS app target
3. **Dependencies**: Check Package.swift for any external dependencies
4. **API Keys**: Insurance billing and payment features may require API credentials

## Next Steps

To make this fully functional:

1. **Install Xcode** on a Mac
2. **Create proper iOS app project** structure
3. **Configure signing** with Apple Developer account (free for testing)
4. **Add API keys** for:
   - Payment processing (Stripe/Square)
   - Insurance verification
   - Email/SMS services
5. **Test on simulator** or physical device
6. **Configure entitlements** for:
   - iCloud (data sync)
   - HealthKit (if needed)
   - Notifications

## Documentation Files

- `README_PHASE2.md` - Phase 2 implementation details
- `README_PHASE3.md` - Phase 3 features (current)
- `README_TECHNICAL.md` - Technical architecture
- `README_DATA_TESTING.md` - Data testing guide
- `massage-therapist-business-operations-detailed-tasks` - Complete feature list (1000+ tasks)

## Support

The codebase is well-structured and follows iOS development best practices. Each service is modular and can be tested independently once Xcode is set up.

---

**Status**: Ready for Xcode setup and local development ✅
**Blocker**: Requires Xcode installation to build and run iOS app ⚠️
