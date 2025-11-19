# Local Database & Testing Guide

## Overview

The app uses a **simple JSON-based local storage system** for testing and development. Data is automatically persisted to the device's documents directory and loaded on app launch.

## Architecture

### Data Persistence Layer

```
Data/
├── LocalStorageManager.swift      # JSON file-based storage
├── MockDataGenerator.swift        # Generates realistic test data
└── Repositories/
    ├── ClientRepository.swift          # Manages client data
    ├── AppointmentRepository.swift     # Manages appointments
    ├── SOAPNoteRepository.swift        # Manages clinical notes
    └── TransactionRepository.swift     # Manages financial records
```

### How It Works

1. **Automatic Mock Data Generation**
   - When the app launches, if no data exists, mock data is automatically generated
   - This provides a realistic testing environment immediately

2. **JSON Storage**
   - Data is stored in the app's documents directory as JSON files
   - Clients: `clients.json`
   - Appointments: `appointments.json`
   - SOAP Notes: `soapNotes.json`
   - Transactions: `transactions.json`

3. **Repository Pattern**
   - Each repository is a singleton (`shared` instance)
   - Uses `@Published` properties for reactive UI updates
   - Automatically saves after CRUD operations

## Using the Data Layer

### Accessing Data

All views now use the repository pattern:

```swift
// In any view
@ObservedObject private var clientRepo = ClientRepository.shared
@ObservedObject private var appointmentRepo = AppointmentRepository.shared
@ObservedObject private var soapNoteRepo = SOAPNoteRepository.shared
@ObservedObject private var transactionRepo = TransactionRepository.shared
```

### CRUD Operations

#### **Clients**

```swift
// Get all clients
let allClients = ClientRepository.shared.clients

// Add a client
let newClient = Client(firstName: "John", lastName: "Doe")
ClientRepository.shared.addClient(newClient)

// Update a client
ClientRepository.shared.updateClient(updatedClient)

// Delete a client
ClientRepository.shared.deleteClient(client)

// Search clients
let results = ClientRepository.shared.searchClients(query: "john")

// Get specific client
if let client = ClientRepository.shared.getClient(by: clientId) {
    print(client.fullName)
}
```

#### **Appointments**

```swift
// Get today's appointments
let today = AppointmentRepository.shared.getTodaysAppointments()

// Get appointments for a specific date
let dateAppointments = AppointmentRepository.shared.getAppointments(for: someDate)

// Get appointments for a client
let clientAppointments = AppointmentRepository.shared.getAppointments(for: clientId)

// Add appointment
let appointment = Appointment(...)
AppointmentRepository.shared.addAppointment(appointment)

// Get upcoming appointments
let upcoming = AppointmentRepository.shared.getUpcomingAppointments(limit: 5)
```

#### **SOAP Notes**

```swift
// Get all notes for a client
let clientNotes = SOAPNoteRepository.shared.getSOAPNotes(for: clientId)

// Get note for a specific session
if let note = SOAPNoteRepository.shared.getSOAPNote(for: sessionId) {
    print(note.subjective.chiefComplaint)
}

// Add SOAP note
let note = SOAPNote(...)
SOAPNoteRepository.shared.addSOAPNote(note)

// Get recent notes
let recent = SOAPNoteRepository.shared.getRecentSOAPNotes(limit: 10)

// Get average pain level for client
let avgPain = SOAPNoteRepository.shared.getAveragePainLevel(for: clientId)
```

#### **Transactions**

```swift
// Get transactions in date range
let monthRange = TransactionRepository.shared.getThisMonthRange()
let transactions = TransactionRepository.shared.getTransactions(in: monthRange)

// Get total revenue
let revenue = TransactionRepository.shared.getTotalRevenue(in: monthRange)

// Get total expenses
let expenses = TransactionRepository.shared.getTotalExpenses(in: monthRange)

// Get net income
let netIncome = TransactionRepository.shared.getNetIncome(in: monthRange)

// Add transaction
let transaction = Transaction(
    description: "Swedish Massage",
    amount: 80.00,
    type: .income,
    category: "Service Revenue"
)
TransactionRepository.shared.addTransaction(transaction)
```

## Mock Data

### What's Generated

When the app first launches, it automatically generates:

- **20 Clients** with realistic:
  - Names, emails, phone numbers
  - Medical histories (conditions, allergies, medications)
  - Preferences (pressure, temperature, music)
  - Dates of birth

- **50 Appointments** spread over:
  - Last 30 days (past appointments - completed/cancelled)
  - Today (in progress/confirmed)
  - Next 30 days (scheduled)
  - Various service types and durations

- **30 SOAP Notes** for completed appointments with:
  - Chief complaints
  - Pain and stress levels
  - Body locations worked
  - Treatment plans and progress notes

- **100 Transactions** including:
  - Service revenue (massages)
  - Product sales
  - Operating expenses (rent, supplies, insurance)
  - Spread over last 90 days

### Resetting Data

To reset the database with fresh mock data:

```swift
// Reset individual repositories
ClientRepository.shared.resetWithMockData(count: 20)
AppointmentRepository.shared.resetWithMockData(clients: clients, count: 50)
SOAPNoteRepository.shared.resetWithMockData(clients: clients, appointments: appointments, count: 30)
TransactionRepository.shared.resetWithMockData(count: 100)

// Clear all data
LocalStorageManager.shared.clearAll()
```

## Testing Scenarios

### Test Complete Workflow

1. **Launch app** → Mock data automatically loads
2. **View Dashboard** → See today's appointments, week's revenue
3. **Browse Clients** → See 20 clients with full profiles
4. **Check Schedule** → See appointments spread across dates
5. **View SOAP Notes** → See clinical documentation
6. **Review Financials** → See revenue/expense breakdown

### Test Data Persistence

1. Add a new client
2. Close the app completely
3. Relaunch → Your client is still there!

### Test Search & Filtering

```swift
// Search clients by name
let results = ClientRepository.shared.searchClients(query: "sarah")

// Filter appointments by status
let completed = AppointmentRepository.shared.getAppointments(with: .completed)

// Get appointments in date range
let calendar = Calendar.current
let start = calendar.startOfDay(for: Date())
let end = calendar.date(byAdding: .day, value: 7, to: start)!
let weekAppointments = AppointmentRepository.shared.getAppointments(in: start...end)
```

### Test Financial Analytics

```swift
let repo = TransactionRepository.shared

// This week's financials
let weekRange = repo.getThisWeekRange()
let weekRevenue = repo.getTotalRevenue(in: weekRange)
let weekExpenses = repo.getTotalExpenses(in: weekRange)
let weekNet = repo.getNetIncome(in: weekRange)

print("Week Revenue: $\(weekRevenue)")
print("Week Expenses: $\(weekExpenses)")
print("Week Net: $\(weekNet)")
```

## Data Flow Diagram

```
User Interaction
      ↓
SwiftUI View (@ObservedObject)
      ↓
Repository (.shared singleton)
      ↓
LocalStorageManager
      ↓
JSON Files (Documents Directory)
```

## Console Output

When running the app, you'll see helpful logs:

```
📦 No clients found, generating mock data...
✅ Saved 20 items to clients
📦 No appointments found, generating mock data...
✅ Saved 50 items to appointments
📦 No SOAP notes found, generating mock data...
✅ Saved 30 items to soapNotes
📦 No transactions found, generating mock data...
✅ Saved 100 items to transactions
```

## File Locations

On iOS Simulator/Device, data is stored in:
```
/Users/[username]/Library/Developer/CoreSimulator/Devices/[UUID]/data/Containers/Data/Application/[UUID]/Documents/
├── clients.json
├── appointments.json
├── soapNotes.json
└── transactions.json
```

## Benefits of This Approach

1. **Zero Configuration** - Works immediately on first launch
2. **Realistic Data** - 20 clients, 50 appointments, 30 notes, 100 transactions
3. **Persistent** - Data survives app restarts
4. **Simple** - No database setup required
5. **Testable** - Easy to reset and regenerate
6. **Observable** - UI updates automatically with `@Published`
7. **Type-Safe** - Uses Swift `Codable`

## Next Steps

This local storage is perfect for:
- ✅ Development and testing
- ✅ Prototyping and demos
- ✅ Learning the app structure

For production, you would migrate to:
- **Core Data** - For offline-first iOS apps
- **iCloud + CloudKit** - For cloud sync
- **Backend API** - For multi-platform support

The repository pattern makes this migration easy - just swap out `LocalStorageManager` with a different implementation!

## Example: Full Testing Session

```swift
// 1. Launch app
// Mock data automatically loads

// 2. View a client
let sarah = ClientRepository.shared.clients.first { $0.firstName == "Sarah" }
print(sarah?.preferences.pressureLevel) // .medium

// 3. Check her appointments
let sarahAppts = AppointmentRepository.shared.getAppointments(for: sarah!.id)
print("Sarah has \(sarahAppts.count) appointments")

// 4. View her SOAP notes
let sarahNotes = SOAPNoteRepository.shared.getSOAPNotes(for: sarah!.id)
if let lastNote = sarahNotes.first {
    print("Last pain level: \(lastNote.subjective.painLevel)/10")
}

// 5. Add a new appointment for Sarah
let newAppt = Appointment(
    clientId: sarah!.id,
    serviceType: .deepTissue,
    startTime: Date(),
    duration: 5400 // 90 minutes
)
AppointmentRepository.shared.addAppointment(newAppt)

// 6. Check financial metrics
let monthRevenue = TransactionRepository.shared.getTotalRevenue(
    in: TransactionRepository.shared.getThisMonthRange()
)
print("This month's revenue: $\(monthRevenue)")
```

---

**Ready to test!** 🎉 Just run the app and start exploring the mock data!
