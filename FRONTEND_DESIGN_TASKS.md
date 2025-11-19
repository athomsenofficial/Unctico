# Unctico iOS App - Front-End Design Task List

Complete mobile screen design and implementation roadmap for the Unctico massage therapy practice management application.

---

## Overview

This document outlines all front-end screens, user flows, and UI/UX components needed to create a professional, intuitive mobile application. Each phase builds upon the previous, following iOS design guidelines and best practices.

**Total Screens Estimated:** 85+ unique screens/views
**Design System:** iOS 17+ with SwiftUI
**Design Philosophy:** Clean, accessible, HIPAA-compliant, therapist-focused

---

# Phase 1: Core Foundation (Months 1-2)

## Sprint 1: Authentication & Onboarding (Week 1-2)

### Authentication Screens
- [x] **Login Screen**
  - Email/password fields with validation
  - "Remember me" toggle
  - "Forgot password" link
  - Biometric login option (Face ID/Touch ID)
  - Professional color scheme (calming blues/greens)
  - Keyboard handling and error states

- [x] **Registration Screen**
  - Multi-step form (Personal Info → Business Info → Credentials)
  - Progress indicator (1 of 3, 2 of 3, 3 of 3)
  - License number validation
  - Terms of service acceptance
  - HIPAA acknowledgment
  - Email verification flow

- [ ] **Onboarding Screens** (3-5 screens)
  - Welcome screen with app value proposition
  - Feature highlights (SOAP notes, scheduling, billing, taxes)
  - Quick tutorial on key features
  - Permission requests (notifications, location for mileage)
  - Initial setup wizard (business info, working hours)

- [ ] **Password Reset Flow**
  - Email entry screen
  - Verification code input
  - New password creation
  - Success confirmation

### Profile Setup
- [ ] **Business Profile Setup**
  - Business name and type
  - License information
  - Business address
  - Contact information
  - Tax ID (EIN/SSN)
  - Profile photo upload

- [ ] **Working Hours Setup**
  - Visual weekly schedule builder
  - Drag-to-set time blocks
  - Break time configuration
  - Time zone selection

---

## Sprint 2: Main Navigation & Dashboard (Week 3-4)

### Navigation Structure
- [x] **Main Tab Bar** (5 tabs)
  - Dashboard (house icon)
  - Clients (person.2 icon)
  - Schedule (calendar icon)
  - SOAP Notes (doc.text icon)
  - More (ellipsis.circle icon)

- [ ] **Side Menu / Settings** (accessible from More tab)
  - Profile section with photo
  - Business settings
  - Notification preferences
  - Security settings
  - Help & support
  - Logout option

### Dashboard Screen
- [x] **Main Dashboard**
  - Welcome header with therapist name and current date
  - Today's summary card (appointments, income, pending tasks)
  - **Stats Cards Grid** (2x2):
    - Today's appointments (with count and next appointment time)
    - This week's revenue (with trend indicator)
    - Pending SOAP notes (with count)
    - Upcoming deadlines (with nearest deadline)

  - **Quick Actions Section**:
    - New appointment button (prominent)
    - New SOAP note
    - Record payment
    - Add expense
    - Log mileage

  - **Today's Schedule Section**:
    - Timeline view of today's appointments
    - Status indicators (confirmed, in-progress, completed)
    - Tap to view details

  - **Alerts & Notifications Section**:
    - Overdue SOAP notes
    - Upcoming tax deadlines
    - Missing receipts
    - Appointment reminders

- [ ] **Dashboard Widgets** (iOS 17 widgets)
  - Today's appointments widget
  - Revenue this week widget
  - Next deadline widget

---

# Phase 2: Client Management & Clinical Documentation (Months 2-3)

## Sprint 3: Client Management (Week 5-6)

### Client List & Search
- [x] **Clients List Screen**
  - Alphabetical section headers
  - Search bar with real-time filtering
  - Client cards showing:
    - Profile photo (or initials)
    - Full name
    - Last appointment date
    - Next appointment (if scheduled)
    - Status indicator (active/inactive)
  - Floating action button for "Add Client"
  - Swipe actions (edit, delete, archive)
  - Filter options (active, inactive, new, all)

- [ ] **Add Client Screen**
  - Photo picker (camera or library)
  - Personal information form
  - Contact information (phone, email)
  - Emergency contact
  - Preferred appointment times
  - Payment preferences
  - Special notes/preferences
  - Form validation with inline errors
  - Save draft functionality

- [ ] **Edit Client Screen**
  - Same as Add Client with pre-filled data
  - Delete client option (with confirmation)
  - Archive client option

### Client Detail Screen
- [x] **Client Profile Overview**
  - Large profile photo at top
  - Contact information cards (tap to call/email/text)
  - Quick stats (total visits, lifetime value, last visit)

  - **Tabs Navigation**:
    1. Overview
    2. Appointments
    3. Clinical
    4. Billing

  - **Overview Tab**:
    - Personal information
    - Emergency contact
    - Preferences and notes
    - Edit button

  - **Appointments Tab**:
    - Upcoming appointments list
    - Past appointments list
    - Book new appointment button
    - Appointment history with status

  - **Clinical Tab**:
    - Intake form (view/edit)
    - Medical history (view/edit)
    - SOAP notes list
    - Treatment progress charts

  - **Billing Tab**:
    - Outstanding balance (prominent)
    - Invoices list
    - Payment history
    - Create invoice button

---

## Sprint 4: Clinical Documentation - Intake Forms (Week 7-8)

### Intake Form Screens
- [x] **Intake Form Main Screen**
  - Completion progress indicator
  - Collapsible sections with completion badges
  - Section headers with icons
  - Navigation between sections

- [ ] **Section 1: Personal Information**
  - Occupation
  - Marital status
  - Referral source
  - Date of birth
  - Auto-calculate age display

- [ ] **Section 2: Chief Complaint**
  - Text area for description
  - Pain level slider (0-10) with color coding
  - Body area selector (visual diagram)
  - Duration picker
  - "When is it worse?" field
  - "What makes it better?" field

- [ ] **Section 3: Medical History**
  - Current conditions checklist
  - Medications list (add/remove)
  - Allergies list with severity
  - Surgeries list with dates
  - Pregnancy status (if applicable)
  - Visual indicators for contraindications

- [ ] **Section 4: Lifestyle Factors**
  - Sleep quality slider
  - Stress level slider
  - Exercise frequency picker
  - Water intake tracker
  - Tobacco use toggle
  - Alcohol consumption picker

- [ ] **Section 5: Massage Preferences**
  - Previous massage experience toggle
  - Preferred pressure level
  - Areas to focus (body diagram)
  - Areas to avoid (body diagram)
  - Special concerns text area

- [ ] **Section 6: Consents**
  - Informed consent checkbox with view terms
  - HIPAA notice acknowledgment
  - SMS consent for reminders
  - Photo/video consent
  - Signature capture pad
  - Date auto-fill

- [ ] **Intake Form Review Screen**
  - Summary of all sections
  - Completion checklist
  - Edit any section button
  - Submit/Save button
  - PDF export option

---

## Sprint 5: Clinical Documentation - Medical History (Week 9-10)

### Medical History Screens
- [x] **Medical History Dashboard**
  - Summary cards (conditions, medications, allergies, surgeries)
  - Warning badges for critical items
  - Last updated date
  - Quick add buttons

- [ ] **Active Conditions Screen**
  - List of current health conditions
  - Diagnosis date for each
  - Status indicators
  - Add/edit/remove functionality
  - Search/filter conditions

- [ ] **Add/Edit Condition Screen**
  - Condition name (searchable dropdown or free text)
  - Diagnosis date picker
  - Severity selector
  - Notes text area
  - Save button

- [ ] **Medications List Screen**
  - Medication cards showing name, dosage, frequency
  - Purpose/indication
  - Start date
  - Add medication button
  - Swipe to edit/delete

- [ ] **Add/Edit Medication Screen**
  - Medication name (searchable)
  - Dosage field
  - Frequency picker (daily, twice daily, as needed, etc.)
  - Purpose text area
  - Start date
  - Save button

- [ ] **Allergies List Screen**
  - Allergy cards with severity color coding
  - Allergen name
  - Reaction description
  - Severity badges (mild, moderate, severe, anaphylactic)
  - Add allergy button

- [ ] **Add/Edit Allergy Screen**
  - Allergen name
  - Reaction description
  - Severity picker with visual indicators
  - Date discovered
  - Save button

- [ ] **Surgical History Screen**
  - Timeline view of surgeries
  - Procedure name
  - Date
  - Relevant notes
  - Add surgery button

- [ ] **Add/Edit Surgery Screen**
  - Procedure name
  - Date picker
  - Location/hospital (optional)
  - Notes text area
  - Save button

- [ ] **Injury History Screen**
  - List of past injuries
  - Date of injury
  - Affected body areas
  - Resolution status
  - Add injury button

- [ ] **Women's Health Screen** (if applicable)
  - Pregnancy status toggle
  - Trimester selector
  - Due date picker
  - Nursing status toggle
  - Menopause status
  - Related notes

---

## Sprint 6: Clinical Documentation - SOAP Notes (Week 11-12)

### SOAP Notes Screens
- [x] **SOAP Notes List Screen**
  - Chronological list (newest first)
  - Filter by client
  - Filter by date range
  - Completion status badges
  - Search functionality
  - Create new SOAP note button

- [ ] **Create SOAP Note Screen**
  - Client selector (searchable dropdown)
  - Session date/time picker
  - Duration selector (30/60/90/120 min)

  - **Subjective Section**:
    - Large text area
    - Voice-to-text button (with recording indicator)
    - Word count display
    - Template suggestions

  - **Objective Section**:
    - Techniques used (multi-select chips)
    - Body areas worked (visual selector)
    - Pressure level slider with labels
    - Modalities used (multi-select)
    - Text area for observations
    - Voice-to-text button

  - **Assessment Section**:
    - Text area for assessment
    - Progress indicators
    - Voice-to-text button
    - Quick notes (pain reduction, mobility improvement, etc.)

  - **Plan Section**:
    - Recommendations text area
    - Homework exercises
    - Follow-up frequency
    - Voice-to-text button

  - **Session Details**:
    - Client response selector
    - Adverse reactions field
    - Next appointment suggestion

  - **Actions**:
    - Save as draft
    - Mark as complete
    - Cancel (with unsaved changes warning)

- [ ] **SOAP Note Detail/View Screen**
  - Read-only view of completed note
  - All sections displayed
  - Session information header
  - Edit button (if not finalized)
  - Export as PDF
  - Email to client option
  - Link to associated appointment

- [ ] **Voice Transcription Interface**
  - Microphone button with visual feedback
  - Recording timer
  - Waveform visualization
  - Pause/resume recording
  - Cancel/save transcription
  - Section selector (which SOAP section to append to)

- [ ] **SOAP Note Templates Screen**
  - Pre-defined templates list
  - Create custom template
  - Edit existing templates
  - Template categories (sports massage, prenatal, deep tissue, etc.)

---

# Phase 3: Scheduling & Appointments (Months 3-4)

## Sprint 7: Calendar & Scheduling (Week 13-14)

### Calendar Views
- [x] **Main Calendar Screen**
  - View mode selector (Day/Week/Month tabs)
  - Date navigation (prev/next, today button)
  - Current date indicator

  - **Day View**:
    - Hourly timeline (8am-8pm scrollable)
    - Appointment blocks with client name and service
    - Status color coding
    - Tap to view details
    - Long-press to create appointment
    - Time slot indicators (available/busy)

  - **Week View**:
    - 7-day horizontal grid
    - Day headers with date
    - Appointment indicators per day
    - Tap day to switch to day view
    - Today highlighting

  - **Month View**:
    - Calendar grid with weekday headers
    - Appointment count dots per day
    - Different colors for different statuses
    - Tap day to switch to day view
    - Current date highlighting

- [ ] **Calendar Legend Screen**
  - Status color key
  - Icon explanations
  - Appointment types
  - Availability indicators

### Appointment Management
- [x] **Book Appointment Screen**
  - Client selector (searchable)
  - Date picker (calendar visual)
  - Available time slots list
  - Duration selector
  - Service type picker
  - Price field (auto-fill from service)
  - Notes field
  - Recurring options toggle

  - **Recurring Settings** (if enabled):
    - Frequency picker (weekly, biweekly, monthly)
    - Days of week selector
    - End date picker or occurrence count
    - Preview of generated appointments

  - Conflict detection with warnings
  - Book button

- [ ] **Appointment Detail Screen**
  - Client information card (tap to view profile)
  - Date and time (prominent)
  - Duration and service type
  - Status badge
  - Price
  - Notes

  - **Actions** (context-dependent):
    - Start appointment (if scheduled)
    - Complete appointment (if in progress)
    - Mark no-show (if scheduled/confirmed)
    - Cancel appointment
    - Reschedule
    - Send reminder
    - Add SOAP note
    - Create invoice

  - Related information:
    - Associated SOAP note (if exists)
    - Associated invoice (if exists)
    - Appointment history with this client

- [ ] **Reschedule Appointment Screen**
  - Current appointment details (read-only)
  - New date picker
  - Available time slots
  - Reason for rescheduling (optional)
  - Notify client toggle
  - Confirm reschedule button

- [ ] **Cancel Appointment Screen**
  - Appointment details
  - Cancellation reason selector
  - Additional notes
  - Refund amount (if deposit paid)
  - Notify client toggle
  - Confirm cancellation button

- [ ] **Appointment History Screen** (for a specific client)
  - List of all past appointments
  - Status indicators
  - Date and service
  - Linked SOAP notes
  - Stats (total sessions, completion rate, etc.)

---

## Sprint 8: Availability & Settings (Week 15-16)

### Availability Management
- [x] **Availability Settings Screen**
  - Working hours by day of week
  - Buffer time slider
  - Break periods list
  - Time off periods list
  - Save changes button

- [ ] **Working Hours Editor**
  - Day of week selector
  - Available toggle for each day
  - Start time picker (visual clock or list)
  - End time picker
  - Total hours display
  - Copy to other days button
  - Reset to defaults

- [ ] **Add/Edit Break Screen**
  - Break name/description
  - Days of week selector (multi-select)
  - Start time picker
  - Duration selector (15/30/45/60/90 min)
  - Recurring toggle
  - Save button

- [ ] **Add Time Off Screen**
  - Type selector (vacation, sick, conference, holiday, personal, other)
  - Start date picker
  - End date picker
  - Duration display (auto-calculated)
  - Reason/description text area
  - Full day toggle
  - Save button

- [ ] **Time Off Calendar View**
  - Visual calendar with time off highlighted
  - Color coding by type
  - Tap to view/edit
  - Filter by type
  - Year view option

### Reminder Settings
- [ ] **Reminder Preferences Screen**
  - Default reminder time selector
  - Reminder methods (email, SMS, push)
  - Custom message templates
  - Automatic vs manual sending
  - Batch reminder settings

- [ ] **Send Reminders Screen**
  - List of upcoming appointments needing reminders
  - Select all/individual selection
  - Preview message
  - Send timing
  - Send button

---

# Phase 4: Billing & Payments (Months 4-5)

## Sprint 9: Invoicing (Week 17-18)

### Invoice Management
- [x] **Invoice List Screen**
  - Search bar
  - Status filter chips (All, Draft, Sent, Paid, Overdue)
  - Invoice cards showing:
    - Invoice number
    - Client name
    - Amount and balance
    - Due date with overdue indicator
    - Status badge
  - Sort options (date, amount, client)
  - Create invoice button

- [ ] **Create Invoice Screen**
  - Client selector (searchable)
  - Invoice date picker (default today)
  - Due date picker (default +30 days)

  - **Line Items Section**:
    - List of line items
    - Add line item button
    - Each item shows: description, quantity, price, total
    - Swipe to delete

  - **Calculations Display**:
    - Subtotal (auto-calculated)
    - Tax rate field (percentage)
    - Tax amount (auto-calculated)
    - Discount field
    - Total amount (prominent, auto-calculated)

  - **Additional Fields**:
    - Terms (default "Net 30")
    - Notes to client
    - Footer text

  - **Actions**:
    - Save as draft
    - Send to client
    - Cancel

- [ ] **Add Line Item Screen**
  - Item name/description
  - Quantity stepper
  - Unit price field
  - Total display (read-only, calculated)
  - Quick add from services list
  - Save button

- [x] **Invoice Detail Screen**
  - Invoice number and status
  - Client information
  - Invoice date and due date
  - Overdue warning (if applicable)

  - **Line Items List**:
    - All items with quantities and prices
    - Subtotal

  - **Calculations Section**:
    - Tax breakdown
    - Discount
    - Total
    - Amount paid
    - Balance remaining (highlighted if unpaid)

  - **Payment History**:
    - List of payments applied
    - Date, amount, method

  - **Actions**:
    - Record payment
    - Send/resend invoice
    - Edit (if draft or sent)
    - Void invoice
    - Download PDF
    - Share

- [ ] **Invoice PDF Preview**
  - Professional invoice layout
  - Business header with logo
  - Client billing address
  - Line items table
  - Payment terms
  - Payment instructions
  - Share/print options

---

## Sprint 10: Payment Processing (Week 19-20)

### Payment Screens
- [ ] **Record Payment Screen** (from invoice)
  - Invoice details (read-only)
  - Amount field (pre-filled with balance)
  - Payment date picker (default today)
  - Payment method selector
  - Reference number field (for checks/transactions)
  - Notes field
  - Apply payment button

- [x] **Payments List Screen**
  - Chronological list
  - Search by client or reference
  - Filter by method
  - Payment cards showing:
    - Client name
    - Amount
    - Date
    - Method icon
    - Status badge
    - Reference number
  - Tap for details

- [ ] **Payment Detail Screen**
  - Amount (prominent)
  - Payment date
  - Payment method with icon
  - Client information
  - Associated invoice link
  - Reference/confirmation number
  - Receipt status
  - Notes

  - **Actions**:
    - Issue refund (if applicable)
    - Send receipt
    - Edit payment
    - Delete payment (with confirmation)

- [ ] **Process Refund Screen**
  - Original payment details
  - Refund amount field (max = payment amount)
  - Refund date picker
  - Reason text area
  - Refund method (same as original)
  - Notify client toggle
  - Process refund button

- [ ] **Receipt View Screen**
  - Professional receipt layout
  - Business information
  - Payment details
  - Invoice line items
  - Payment method
  - Receipt number
  - Share/email options

### Payment Method Management
- [ ] **Saved Payment Methods Screen**
  - List of saved cards
  - Card brand icon
  - Last 4 digits
  - Expiration date
  - Default card indicator
  - Add new card button
  - Swipe to delete

- [ ] **Add Payment Method Screen**
  - Card number field with brand detection
  - Expiration date picker
  - CVV field (not stored)
  - Cardholder name
  - Billing zip code
  - Set as default toggle
  - Save card button
  - Security badges (Stripe/Square logos)

---

## Sprint 11: Billing Reports (Week 21-22)

### Billing Reports
- [x] **Billing Reports Screen**
  - Period selector (Today/Week/Month/Year)

  - **Revenue Summary Cards**:
    - Total revenue (large, green)
    - Total collected (blue)
    - Outstanding (orange)

  - **Invoice Statistics**:
    - Total invoices
    - Paid count
    - Pending count
    - Overdue count

  - **Payment Statistics**:
    - Total payments
    - Completed
    - Pending
    - Refunded

  - **Outstanding Invoices List**:
    - Top 5 or all
    - Invoice number
    - Client
    - Amount
    - Days overdue
    - Tap to view

- [ ] **Revenue Chart Screen**
  - Line chart of revenue over time
  - Bar chart of revenue by service type
  - Period selector
  - Export chart option

- [ ] **Client Revenue Report**
  - List of clients sorted by lifetime value
  - Revenue amount per client
  - Number of sessions
  - Average session value
  - Tap for client detail

---

# Phase 5: Bookkeeping & Financial Management (Months 5-6)

## Sprint 12: Expense Tracking (Week 23-24)

### Expense Screens
- [x] **Expense List Screen**
  - Category filter (horizontal scroll chips)
  - Search bar
  - Expense cards showing:
    - Category icon with color
    - Description
    - Vendor
    - Amount
    - Date
    - Tax deductible badge
    - Receipt indicator
  - Add expense button
  - Swipe to delete

- [ ] **Add Expense Screen**
  - Date picker
  - Amount field (large, prominent)
  - Category picker (visual with icons)
  - Description field
  - Vendor field
  - Payment method selector

  - **Tax Information**:
    - Tax deductible toggle (default per category)
    - Tax category notes display

  - **Receipt**:
    - Has receipt toggle
    - Attach photo button
    - Photo preview (if attached)

  - Notes field
  - Save button

- [ ] **Receipt Capture Screen**
  - Camera viewfinder
  - Photo library option
  - Crop/rotate tools
  - OCR amount detection (optional)
  - Retake/use photo buttons

- [ ] **Expense Detail Screen**
  - Category icon and color
  - Amount (large)
  - Date and vendor
  - Payment method
  - Tax deductible status with notes
  - Receipt thumbnail (tap to view full)
  - Notes
  - Edit/delete buttons

- [ ] **Receipt Viewer**
  - Full-screen image view
  - Pinch to zoom
  - Share option
  - Delete option

### Recurring Expenses
- [ ] **Recurring Expenses Screen**
  - List of recurring expense templates
  - Frequency indicator
  - Next occurrence date
  - Amount
  - Add recurring expense button

- [ ] **Add Recurring Expense Screen**
  - All expense fields
  - Frequency picker
  - Start date
  - End date or occurrence count
  - Preview of future expenses
  - Save button

---

## Sprint 13: Income Tracking (Week 25-26)

### Income Screens
- [x] **Income List Screen**
  - Category filter
  - Search bar
  - Income cards showing:
    - Category icon with color
    - Description
    - Source
    - Amount (green)
    - Date
    - Automatic income badge
    - Payment method
  - Add income button
  - Filter: automatic vs manual

- [ ] **Add Income Screen**
  - Date picker
  - Amount field (large, green)
  - Category picker (visual with icons)
  - Description field
  - Source field
  - Payment method selector
  - Taxable income toggle
  - Notes field
  - Save button

- [ ] **Income Detail Screen**
  - Category icon and color
  - Amount (large, green)
  - Date and source
  - Payment method
  - Type indicator (appointment/invoice/manual)
  - Taxable status with notes
  - Linked appointment or invoice
  - Notes
  - Edit/delete buttons

### Income Analytics
- [ ] **Income Analytics Screen**
  - Month-over-month comparison chart
  - Income by category pie chart
  - Income by payment method breakdown
  - Best performing days/times
  - Average session value
  - Period selector

---

## Sprint 14: Financial Reports (Week 27-28)

### Financial Reporting
- [x] **Financial Reports Dashboard**
  - Report type tabs (P&L / Cash Flow / Tax)
  - Period selector (Month/Quarter/Year)
  - Year picker

- [ ] **Profit & Loss Report**
  - Net income (large, color-coded)
  - Profit margin percentage

  - **Income Section**:
    - Total income
    - Income by category breakdown
    - Category icons and amounts

  - **Expenses Section**:
    - Total expenses
    - Expense by category breakdown
    - Category icons and amounts

  - Export as PDF
  - Share report

- [ ] **Cash Flow Report**
  - Net cash flow (large)
  - Total cash in/out

  - **Cash Inflow Section**:
    - By payment method
    - Cash, check, credit card, other
    - Icons and amounts

  - Export/share options

- [ ] **Tax Report**
  - Net taxable income (large)
  - Total income vs taxable income
  - Total expenses vs deductible expenses

  - **Missing Receipts Alert**:
    - Count and total amount
    - List of expenses needing receipts
    - Tap to add receipt

  - Export for accountant

- [ ] **Comparison Reports Screen**
  - Year-over-year comparison
  - Month-over-month trends
  - Visual charts and graphs
  - Key metrics dashboard

---

# Phase 6: Tax Management (Months 6-7)

## Sprint 15: Tax Dashboard & Calculations (Week 29-30)

### Tax Management
- [x] **Tax Dashboard Screen**
  - Year selector

  - **Quarterly Estimate Section**:
    - Quarter selector (Q1-Q4)
    - Quarterly payment amount (large, prominent)
    - Net profit
    - Self-employment tax
    - Federal income tax
    - State tax (if enabled)
    - Total annual tax estimate

  - **Year-to-Date Summary**:
    - Gross income card
    - Expenses card
    - Net profit card
    - Total tax card
    - Effective tax rate

  - **Upcoming Deadlines**:
    - Next 5 deadlines
    - Days until
    - Status indicators

  - **Quick Actions Grid**:
    - Mileage log
    - Schedule C
    - Deadlines
    - Form 1099

- [ ] **Tax Settings Screen**
  - Filing status selector
  - State tax toggle
  - State tax rate slider
  - Home office square footage
  - Estimated quarterly tax preferences
  - Save settings

### Tax Calculations
- [ ] **Quarterly Estimate Detail Screen**
  - Quarter and year header
  - Calculation breakdown (detailed)
  - Income summary
  - Expense summary
  - Tax calculations step-by-step
  - Payment voucher download
  - Mark as paid option

- [ ] **Tax Calculator Tool**
  - Income input
  - Deductions input
  - Filing status
  - Real-time calculation
  - Comparison tool (different scenarios)
  - Save estimate

---

## Sprint 16: Mileage Tracking (Week 31-32)

### Mileage Screens
- [x] **Mileage Log Screen**
  - Year filter
  - Summary cards (total miles, deduction, trip count)
  - Search logs
  - Mileage log list:
    - Purpose icon
    - Start → End locations
    - Business purpose
    - Miles and deduction
    - Date
    - Round trip indicator
  - Add mileage button

- [ ] **Add Mileage Log Screen**
  - Date picker
  - Start location field (with GPS option)
  - End location field (with GPS option)
  - Miles field
  - Round trip toggle
  - Purpose selector (8 types with icons)
  - Business purpose description
  - Non-deductible warning (if office commute)
  - Auto-calculate from GPS option
  - Save button

- [ ] **GPS Mileage Tracker**
  - Start trip button
  - Live tracking map
  - Distance counter (real-time)
  - End trip button
  - Auto-fill trip details

- [ ] **Mileage Report Screen**
  - Total miles by purpose
  - Total deduction
  - IRS rate display
  - Period selector
  - Export for taxes
  - Monthly breakdown chart

---

## Sprint 17: Tax Forms & Deadlines (Week 33-34)

### Schedule C
- [x] **Schedule C View**
  - Year selector
  - Business information section
  - Net profit/loss (large)

  - **Part I: Income**:
    - Gross receipts by category
    - Total income

  - **Part II: Expenses**:
    - All IRS expense lines
    - Line numbers and amounts
    - Mileage deduction included
    - Total expenses

  - **Part IV: Vehicle**:
    - Business miles
    - Mileage deduction
    - IRS rate

  - Export as PDF
  - Export to CSV
  - Share with accountant

### Tax Deadlines
- [x] **Tax Deadlines Screen**
  - Filter chips (All/Upcoming/Overdue/Completed)
  - Year filter
  - Deadline cards:
    - Type icon and color
    - Display title with quarter
    - Due date
    - Days until/overdue
    - Status badge
    - Amount paid
  - Tap to mark complete

- [ ] **Deadline Detail Screen**
  - Deadline type and description
  - Due date (large)
  - Days until/overdue indicator
  - Related information
  - Payment amount (if completed)
  - Confirmation number
  - Mark complete button
  - Set reminder button

- [ ] **Complete Deadline Screen**
  - Deadline info (read-only)
  - Amount paid field
  - Confirmation number field
  - Payment date picker
  - Notes
  - Mark complete button

- [ ] **Tax Calendar View**
  - Year calendar with deadlines marked
  - Color coding by type
  - Tap date for details
  - Add custom deadline

### Form 1099
- [ ] **Form 1099 List Screen**
  - Year filter
  - Status filter (needs filing/filed/below threshold)
  - 1099 cards:
    - Recipient name
    - Total compensation
    - Status badge
    - Filing required indicator
  - Add 1099 button

- [ ] **Add Form 1099 Screen**
  - Year selector
  - Recipient information form
  - Tax ID field
  - Address fields
  - Recipient type selector
  - Save button

- [ ] **Form 1099 Detail Screen**
  - Recipient information
  - Total compensation (Box 1)
  - Federal tax withheld (Box 4)
  - Payment list
  - Add payment button
  - Filing status
  - Mark as filed
  - Export form

- [ ] **Add 1099 Payment Screen**
  - Date picker
  - Amount field
  - Category selector
  - Description
  - Check/invoice number
  - Save button

---

# Phase 7: Settings & Advanced Features (Months 7-8)

## Sprint 18: Business Settings (Week 35-36)

### Business Profile
- [ ] **Business Settings Screen**
  - Business name
  - Business type selector
  - License information
  - License expiration date
  - Business address
  - Phone number
  - Email
  - Website (optional)
  - Tax ID (EIN/SSN)
  - Logo upload
  - Save changes

- [ ] **License Management Screen**
  - License number
  - License type
  - State
  - Issue date
  - Expiration date
  - Expiration alert settings
  - Upload license copy
  - Renewal reminders

- [ ] **Service Types Setup**
  - List of service types
  - Add service button
  - Service cards:
    - Service name
    - Duration
    - Price
    - Description
    - Active toggle
  - Edit/delete services

- [ ] **Add/Edit Service Screen**
  - Service name
  - Duration picker
  - Price field
  - Description
  - Color selector
  - Active toggle
  - Save button

---

## Sprint 19: User Settings & Preferences (Week 37-38)

### Profile Settings
- [ ] **Profile Screen**
  - Profile photo (large, editable)
  - Full name
  - Email
  - Phone
  - License display
  - Edit button

- [ ] **Edit Profile Screen**
  - Photo picker
  - Name fields
  - Email field
  - Phone field
  - Save changes

- [ ] **Account Security Screen**
  - Change password
  - Two-factor authentication toggle
  - Biometric login toggle (Face ID/Touch ID)
  - Active sessions list
  - Sign out of all devices

- [ ] **Change Password Screen**
  - Current password field
  - New password field
  - Confirm password field
  - Password strength indicator
  - Save button

### Notification Settings
- [ ] **Notification Preferences Screen**
  - **Appointment Reminders**:
    - Enabled toggle
    - Timing selector (24hr, 1hr, custom)
    - Methods (push, email, SMS)

  - **Payment Reminders**:
    - Enabled toggle
    - Overdue invoice alerts

  - **SOAP Note Reminders**:
    - Enabled toggle
    - Timing after appointment

  - **Tax Deadline Alerts**:
    - Enabled toggle
    - Days before deadline

  - **System Notifications**:
    - App updates
    - Feature announcements
    - Tips and tutorials

- [ ] **Do Not Disturb Settings**
  - Enable DND toggle
  - Start time
  - End time
  - Days of week
  - Emergency override

---

## Sprint 20: Data Management & Export (Week 39-40)

### Data & Privacy
- [ ] **Data Management Screen**
  - **Export Data Section**:
    - Export all data button
    - Export by type (clients, appointments, invoices, etc.)
    - Export date range selector
    - Format selector (PDF, CSV, JSON)

  - **Backup & Sync**:
    - iCloud sync toggle
    - Last backup date
    - Backup now button
    - Auto-backup settings

  - **Storage**:
    - Used storage display
    - Breakdown by type
    - Clear cache button

- [ ] **Privacy & HIPAA Screen**
  - HIPAA compliance information
  - Data encryption status
  - Access log
  - Privacy policy
  - Terms of service

- [ ] **Data Export Progress Screen**
  - Export type
  - Progress indicator
  - Estimated time remaining
  - Cancel export
  - Download when complete

### Import Data
- [ ] **Import Data Screen**
  - Import type selector
  - File picker
  - CSV mapping tool
  - Preview imported data
  - Duplicate handling options
  - Import button

- [ ] **Import Mapping Screen**
  - CSV column preview
  - Map to app fields
  - Required field indicators
  - Example data preview
  - Continue button

---

## Sprint 21: Help & Support (Week 41-42)

### Help & Documentation
- [ ] **Help Center Screen**
  - Search bar
  - **Quick Start Guide**:
    - Setting up your account
    - Adding your first client
    - Booking appointments
    - Creating SOAP notes
    - Managing invoices

  - **Video Tutorials**:
    - Category list
    - Video thumbnails
    - Duration indicators

  - **FAQ Section**:
    - Categorized questions
    - Expandable answers
    - Search functionality

  - **Contact Support**:
    - Email support
    - Phone support
    - Live chat (if available)

- [ ] **Tutorial Screens** (interactive)
  - Step-by-step walkthroughs
  - Interactive elements
  - Skip tutorial option
  - Progress indicator
  - Complete and exit

- [ ] **What's New Screen**
  - Recent updates list
  - Feature highlights
  - Version history
  - Dismiss button

### Feedback & Support
- [ ] **Send Feedback Screen**
  - Feedback type selector (bug, feature request, general)
  - Description text area
  - Screenshot attachment option
  - Device info auto-included
  - Email for follow-up
  - Submit button

- [ ] **Support Ticket Screen**
  - Issue description
  - Category selector
  - Priority indicator
  - Attachment options
  - Submit button

- [ ] **Support History Screen**
  - List of submitted tickets
  - Status indicators
  - Date submitted
  - Tap to view responses

---

# Phase 8: Advanced Features & Optimization (Months 8-9)

## Sprint 22: Analytics & Insights (Week 43-44)

### Business Analytics
- [ ] **Analytics Dashboard**
  - **Overview Cards**:
    - Total clients
    - Active clients
    - Client retention rate
    - Average session value

  - **Revenue Charts**:
    - Revenue trend (line chart)
    - Revenue by service (pie chart)
    - Revenue by day of week (bar chart)

  - **Appointment Analytics**:
    - Booking trends
    - Cancellation rate
    - No-show rate
    - Peak hours heatmap

  - **Client Analytics**:
    - New vs returning clients
    - Client lifetime value
    - Client acquisition sources

- [ ] **Revenue Analytics Screen**
  - Period comparison
  - Revenue forecasting
  - Goal tracking
  - Trends analysis
  - Export reports

- [ ] **Client Insights Screen**
  - Client demographics (if tracked)
  - Service preferences
  - Booking patterns
  - Retention analysis
  - At-risk clients identification

- [ ] **Appointment Analytics Screen**
  - Utilization rate
  - Most popular times
  - Service popularity
  - Cancellation patterns
  - Optimization suggestions

### Goals & Targets
- [ ] **Goals Screen**
  - Revenue goals
  - Client goals
  - Appointment goals
  - Progress indicators
  - Add/edit goals

- [ ] **Set Goal Screen**
  - Goal type selector
  - Target amount/number
  - Time period
  - Start date
  - Track progress toggle
  - Save button

---

## Sprint 23: Marketing & Client Communication (Week 45-46)

### Client Communication
- [ ] **Client Communication Hub**
  - Message templates
  - Appointment reminders
  - Thank you messages
  - Birthday messages
  - Promotional messages
  - Message history

- [ ] **Create Message Screen**
  - Recipient selector (individual or group)
  - Template selector
  - Message text area
  - Personalization tags
  - Schedule send option
  - Send now or schedule

- [ ] **Email Campaign Screen**
  - Campaign name
  - Recipient list
  - Email template
  - Subject line
  - Preview
  - Schedule send
  - Track opens/clicks

### Promotions & Packages
- [ ] **Promotions Screen**
  - Active promotions list
  - Create promotion button
  - Promotion cards:
    - Promotion name
    - Discount amount/percentage
    - Valid dates
    - Usage count
    - Active toggle

- [ ] **Create Promotion Screen**
  - Promotion name
  - Type selector (percentage, fixed amount, free session)
  - Value field
  - Valid from/to dates
  - Applicable services
  - Max usage limit
  - Promo code
  - Save button

- [ ] **Packages Screen**
  - Package bundles list
  - Package cards:
    - Package name
    - Number of sessions
    - Total price
    - Price per session
    - Expiration period
  - Create package button

- [ ] **Create Package Screen**
  - Package name
  - Number of sessions
  - Services included
  - Total price
  - Expiration days
  - Description
  - Save button

---

## Sprint 24: Accessibility & Polish (Week 47-48)

### Accessibility Features
- [ ] **Accessibility Settings Screen**
  - VoiceOver optimization
  - Dynamic type support
  - Reduce motion toggle
  - High contrast mode
  - Color blind friendly colors
  - Haptic feedback toggle

- [ ] **Screen Reader Optimization**
  - All screens properly labeled
  - Logical navigation order
  - Descriptive button labels
  - Form field hints
  - Error messages clear

### UI/UX Polish
- [ ] **Dark Mode Support**
  - All screens dark mode compatible
  - Proper color contrast
  - Asset variations
  - User preference toggle

- [ ] **iPad Optimization**
  - Split view support
  - Sidebar navigation
  - Multi-column layouts
  - Keyboard shortcuts
  - Drag and drop

- [ ] **Widget Support**
  - Today's appointments widget
  - Revenue summary widget
  - Next deadline widget
  - Quick actions widget

- [ ] **App Shortcuts**
  - 3D Touch quick actions
  - Siri shortcuts
  - Spotlight search integration

### Performance Optimization
- [ ] **Performance Enhancements**
  - List view virtualization
  - Image lazy loading
  - Cache management
  - Database query optimization
  - Network request batching

- [ ] **Offline Support**
  - Offline mode indicator
  - Sync queue display
  - Conflict resolution
  - Cached data display

---

# Additional Screens & Features

## Error Handling & Edge Cases

- [ ] **Error Screen**
  - Friendly error message
  - Error code (for support)
  - Try again button
  - Contact support option
  - Go to home button

- [ ] **No Internet Screen**
  - Offline indicator
  - Limited functionality message
  - Retry connection button
  - Offline mode features

- [ ] **Empty States** (for all list screens)
  - Contextual illustration
  - Helpful message
  - Call-to-action button
  - Tutorial link

- [ ] **Loading States**
  - Skeleton screens
  - Progress indicators
  - Cancellable operations
  - Timeout handling

## Confirmations & Alerts

- [ ] **Confirmation Dialogs**
  - Delete confirmations
  - Cancel confirmations
  - Logout confirmation
  - Data export warnings
  - Destructive action warnings

- [ ] **Success Messages**
  - Toast notifications
  - Success screens
  - Completion animations
  - Next step suggestions

---

## Summary

### Total Screen Count by Phase

**Phase 1:** 15 screens (Authentication, Navigation, Dashboard)
**Phase 2:** 22 screens (Client Management, Clinical Documentation)
**Phase 3:** 18 screens (Scheduling, Appointments, Availability)
**Phase 4:** 17 screens (Billing, Payments, Reports)
**Phase 5:** 13 screens (Bookkeeping, Financial Management)
**Phase 6:** 14 screens (Tax Management, Forms, Deadlines)
**Phase 7:** 16 screens (Settings, Business Setup)
**Phase 8:** 15 screens (Analytics, Marketing, Polish)

**Total Unique Screens:** 130+ screens

### Design System Components

- Navigation bars (standard, large title)
- Tab bars
- Cards (various types)
- List rows (various types)
- Form fields (text, number, date, picker, etc.)
- Buttons (primary, secondary, destructive)
- Badges and tags
- Charts and graphs
- Progress indicators
- Empty states
- Error states
- Loading states
- Modals and sheets
- Action sheets
- Alerts and confirmations

### Key Design Principles

1. **Consistency**: Unified color scheme, typography, and spacing
2. **Clarity**: Clear hierarchy, readable text, obvious actions
3. **Accessibility**: VoiceOver support, dynamic type, high contrast
4. **Efficiency**: Quick actions, shortcuts, smart defaults
5. **Security**: Biometric authentication, encrypted data, HIPAA compliance
6. **Professionalism**: Clean design, appropriate for healthcare setting
7. **Delight**: Subtle animations, helpful feedback, thoughtful interactions

---

**Last Updated:** Sprint 11-12 Completion
**Status:** Ready for Design & Implementation
**Next Steps:** Begin Phase 1 screen designs with high-fidelity mockups
