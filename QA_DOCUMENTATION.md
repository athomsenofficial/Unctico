# QA Documentation - Unctico Massage Therapy App

## Testing Guide for Quality Assurance Representatives

This document provides step-by-step testing instructions for each feature of the Unctico app.

---

## Phase 1: Core Foundation

### 1. App Architecture Setup
**Status**: ✅ Complete

**What was built**:
- Organized folder structure separating concerns (Models, Views, ViewModels, Services)
- Centralized components for reusability
- Core infrastructure for database, authentication, networking, and storage

**QA Testing**: N/A (Infrastructure only)

---

### 2. Secure Data Storage
**Status**: 🔄 In Progress

**What it does**:
- Stores all sensitive client data with encryption
- Uses Core Data for local database
- Automatic data synchronization
- Backup and restore capabilities

**How to test**:
1. Create a new client record with personal information
2. Close the app completely
3. Reopen the app
4. Verify the client data is still present
5. Check that data cannot be accessed without authentication

**Expected behavior**:
- All data persists after app restart
- Data is encrypted at rest
- No data loss occurs

---

### 3. User Authentication
**Status**: ✅ Complete

**What it does**:
- Secure login with Face ID/Touch ID
- Passcode fallback option
- Session management
- Auto-logout after inactivity

**How to test**:
1. First launch: Set up Face ID/Touch ID
2. Close app and reopen - should require authentication
3. Try wrong passcode 3 times - should lock for 1 minute
4. Test auto-logout after 5 minutes of inactivity
5. Verify background app switching requires re-authentication

**Expected behavior**:
- Biometric authentication prompt appears immediately
- Passcode entry works as fallback
- Account locks after 3 failed attempts
- Auto-logout triggers after 5 minutes in background

---

### 4. Main Navigation
**Status**: ✅ Complete

**What it does**:
- Tab-based navigation with 5 main sections
- Dashboard, Clients, Calendar, Notes, More
- Smooth transitions between screens

**How to test**:
1. Login and verify 5 tabs appear at bottom
2. Tap each tab and verify screen changes
3. Navigate through app and verify back buttons work
4. Check that selected tab is highlighted

**Expected behavior**:
- All tabs are accessible
- Navigation is smooth and responsive
- No crashes when switching tabs

---

### 5. Client Management
**Status**: ✅ Complete

**What it does**:
- Add new clients with personal information
- View client list with search
- View client details and history
- Edit and delete clients

**How to test**:
1. Tap "Clients" tab
2. Tap "+" button to add new client
3. Fill in: First Name, Last Name, Email, Phone, Date of Birth
4. Tap "Save Client"
5. Verify client appears in list
6. Tap client to view details
7. Search for client by name or email
8. Swipe to delete client

**Expected behavior**:
- New clients are saved successfully
- Client list shows all clients alphabetically
- Search works for names, email, and phone
- Client details show all information
- Delete removes client and their data

---

### 6. SOAP Notes with Voice Input
**Status**: ✅ Complete

**What it does**:
- Create clinical SOAP notes (Subjective, Objective, Assessment, Plan)
- Voice-to-text input for all sections
- Pain and stress level sliders
- Save and view SOAP notes

**How to test Voice Input**:
1. Tap "Notes" tab, then "+" to create new note
2. Select a client
3. Tap microphone icon next to "Chief Complaint"
4. Grant microphone permission when prompted
5. Speak clearly: "Patient reports lower back pain"
6. Tap microphone again to stop recording
7. Verify text appears in the field
8. Repeat for Objective, Assessment, and Plan sections

**How to test Manual Entry**:
1. Tap into any text field and type manually
2. Use sliders for Pain Level (0-10)
3. Use sliders for Stress Level (0-10)
4. Fill in all four SOAP sections
5. Tap "Save SOAP Note"

**How to test Viewing**:
1. From Notes list, tap any note
2. Verify all sections display correctly
3. Check pain level shows with color coding:
   - Green (0-3), Yellow (4-6), Orange (7-8), Red (9-10)
4. Verify client name and date appear
5. Check voice transcription is preserved

**Expected behavior**:
- Voice recognition works accurately
- Text appears in real-time as you speak
- Microphone icon turns red when recording
- Notes save with all information
- Notes are searchable by client
- Color coding helps identify severity

---

### 7. Dashboard
**Status**: ✅ Complete

**What it does**:
- Shows today's appointments
- Displays statistics (appointments, completed, revenue)
- Quick action buttons
- Welcome message with user name

**How to test**:
1. Login and view dashboard
2. Verify welcome message shows your name
3. Check "Today's Summary" shows:
   - Total appointments count
   - Completed appointments
   - Revenue for the day
4. Verify "Today's Schedule" lists appointments
5. Test quick action buttons:
   - Add New Client
   - Schedule Appointment
   - Create SOAP Note

**Expected behavior**:
- Statistics update in real-time
- Appointments shown in chronological order
- Quick actions navigate to correct screens
- Empty states show helpful messages

---

### 8. Calendar View
**Status**: ✅ Complete

**What it does**:
- Visual calendar to select dates
- Shows appointments for selected date
- Add appointments from calendar

**How to test**:
1. Tap "Calendar" tab
2. Tap different dates in calendar
3. Verify appointments update for selected date
4. Tap "+" to add appointment
5. Select date with no appointments - verify empty state

**Expected behavior**:
- Calendar updates when date selected
- Appointments display for correct date
- Empty dates show "No appointments" message
- Add button opens appointment form

---

