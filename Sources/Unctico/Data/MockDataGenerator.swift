import Foundation

/// Generates mock data for testing
class MockDataGenerator {
    static let shared = MockDataGenerator()

    private init() {}

    // MARK: - Client Generation

    func generateClients(count: Int = 20) -> [Client] {
        let firstNames = ["Sarah", "Michael", "Jennifer", "David", "Jessica", "James", "Emily", "Robert", "Amanda", "John", "Lisa", "William", "Ashley", "Richard", "Michelle", "Thomas", "Melissa", "Daniel", "Laura", "Christopher"]
        let lastNames = ["Johnson", "Williams", "Brown", "Davis", "Miller", "Wilson", "Moore", "Taylor", "Anderson", "Thomas", "Jackson", "White", "Harris", "Martin", "Thompson", "Garcia", "Martinez", "Robinson", "Clark", "Rodriguez"]

        let conditions = [
            "Lower back pain", "Neck tension", "Shoulder stiffness",
            "Headaches", "Sciatica", "Fibromyalgia", "Arthritis"
        ]

        let allergies = ["Lavender", "Eucalyptus", "Peppermint", "Nuts", "Latex"]

        return (0..<count).map { index in
            let firstName = firstNames[index % firstNames.count]
            let lastName = lastNames[index % lastNames.count]
            let email = "\(firstName.lowercased()).\(lastName.lowercased())@email.com"
            let phone = String(format: "(555) %03d-%04d", Int.random(in: 100...999), Int.random(in: 1000...9999))

            var medicalHistory = MedicalHistory()
            if Bool.random() {
                medicalHistory.conditions = Array(conditions.shuffled().prefix(Int.random(in: 1...3)))
            }
            if Bool.random() {
                medicalHistory.allergies = Array(allergies.shuffled().prefix(Int.random(in: 0...2)))
            }
            if Bool.random() {
                medicalHistory.medications = ["Ibuprofen", "Muscle relaxants"]
            }

            var preferences = ClientPreferences()
            preferences.pressureLevel = ClientPreferences.PressureLevel.allCases.randomElement() ?? .medium
            preferences.temperaturePreference = ClientPreferences.TemperaturePreference.allCases.randomElement() ?? .neutral
            preferences.musicPreference = ["Classical", "Nature Sounds", "Spa Music", "Silence"].randomElement()
            preferences.communicationMethod = ClientPreferences.CommunicationMethod.allCases.randomElement() ?? .email

            let dateOfBirth = Calendar.current.date(byAdding: .year, value: -Int.random(in: 25...70), to: Date())

            return Client(
                firstName: firstName,
                lastName: lastName,
                email: email,
                phone: phone,
                dateOfBirth: dateOfBirth,
                medicalHistory: medicalHistory,
                preferences: preferences,
                createdAt: Date().addingTimeInterval(-TimeInterval.random(in: 0...(365*24*3600)))
            )
        }
    }

    // MARK: - Appointment Generation

    func generateAppointments(for clients: [Client], count: Int = 50) -> [Appointment] {
        guard !clients.isEmpty else { return [] }

        let serviceTypes = ServiceType.allCases
        let statuses: [AppointmentStatus] = [.scheduled, .confirmed, .inProgress, .completed, .cancelled]

        return (0..<count).map { index in
            let client = clients.randomElement()!
            let serviceType = serviceTypes.randomElement()!

            // Generate appointments spread over the last 30 days and next 30 days
            let daysOffset = Int.random(in: -30...30)
            let hour = Int.random(in: 9...17)
            let minute = [0, 15, 30, 45].randomElement()!

            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            dateComponents.day! += daysOffset
            dateComponents.hour = hour
            dateComponents.minute = minute

            let startTime = Calendar.current.date(from: dateComponents) ?? Date()

            let status: AppointmentStatus
            if daysOffset < 0 {
                status = [.completed, .cancelled, .noShow].randomElement()!
            } else if daysOffset == 0 {
                status = [.confirmed, .inProgress].randomElement()!
            } else {
                status = .scheduled
            }

            let notes = Bool.random() ? "Client prefers morning appointments" : nil

            return Appointment(
                clientId: client.id,
                serviceType: serviceType,
                startTime: startTime,
                duration: serviceType.duration,
                status: status,
                notes: notes,
                roomNumber: "Room \(Int.random(in: 1...5))",
                createdAt: startTime.addingTimeInterval(-TimeInterval.random(in: 3600...86400))
            )
        }
    }

    // MARK: - SOAP Note Generation

    func generateSOAPNotes(for clients: [Client], appointments: [Appointment], count: Int = 30) -> [SOAPNote] {
        guard !clients.isEmpty else { return [] }

        let completedAppointments = appointments.filter { $0.status == .completed }

        return (0..<min(count, completedAppointments.count)).map { index in
            let appointment = completedAppointments[index]

            var subjective = Subjective()
            subjective.chiefComplaint = [
                "Lower back pain after long work hours",
                "Tension headaches from stress",
                "Shoulder stiffness from computer work",
                "General muscle soreness from exercise",
                "Neck pain from sleeping position"
            ].randomElement()!
            subjective.painLevel = Int.random(in: 3...8)
            subjective.sleepQuality = Subjective.SleepQuality.allCases.randomElement()!
            subjective.stressLevel = Int.random(in: 4...9)

            var objective = Objective()
            objective.areasWorked = [
                BodyLocation(region: .lowerBack, side: .bilateral),
                BodyLocation(region: .shoulders, side: .bilateral),
                BodyLocation(region: .neck, side: .bilateral)
            ]
            objective.muscleTension = [
                Objective.MuscleTensionReading(location: BodyLocation(region: .lowerBack, side: .bilateral), tensionLevel: Int.random(in: 3...5)),
                Objective.MuscleTensionReading(location: BodyLocation(region: .shoulders, side: .right), tensionLevel: Int.random(in: 2...4))
            ]
            objective.palpationFindings = "Moderate tension in trapezius muscles, mild tension in lower back"

            var assessment = Assessment()
            assessment.progressNotes = "Client responding well to treatment. Pain levels decreased from previous session."
            assessment.treatmentResponse = Assessment.TreatmentResponse.allCases.randomElement()!

            var plan = Plan()
            plan.treatmentFrequency = ["Weekly", "Bi-weekly", "Every 2 weeks", "Monthly"].randomElement()!
            plan.homeCareInstructions = ["Apply ice to affected area", "Gentle stretching daily", "Maintain good posture"]
            plan.nextSessionFocus = "Continue work on shoulder tension, focus on neck mobility"
            plan.followUpDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: appointment.startTime)

            return SOAPNote(
                clientId: appointment.clientId,
                sessionId: appointment.id,
                date: appointment.startTime,
                subjective: subjective,
                objective: objective,
                assessment: assessment,
                plan: plan,
                createdAt: appointment.startTime,
                updatedAt: appointment.startTime
            )
        }
    }

    // MARK: - Transaction Generation

    func generateTransactions(count: Int = 100) -> [Transaction] {
        let incomeDescriptions = [
            "Swedish Massage - 60 min",
            "Deep Tissue Massage - 90 min",
            "Sports Massage - 60 min",
            "Prenatal Massage - 60 min",
            "Hot Stone Massage - 90 min",
            "Product Sale - Massage Oil"
        ]

        let expenseDescriptions = [
            "Massage Oil Purchase",
            "Linens and Towels",
            "Rent Payment",
            "Utilities - Electric",
            "Professional Liability Insurance",
            "Marketing - Google Ads",
            "Office Supplies",
            "Continuing Education Course",
            "License Renewal Fee"
        ]

        return (0..<count).map { _ in
            let isIncome = Bool.random()
            let type: Transaction.TransactionType = isIncome ? .income : .expense

            let description: String
            let amount: Double

            if isIncome {
                description = incomeDescriptions.randomElement()!
                amount = Double.random(in: 60...150)
            } else {
                description = expenseDescriptions.randomElement()!
                amount = Double.random(in: 20...500)
            }

            let daysAgo = Int.random(in: 0...90)
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!

            return Transaction(
                description: description,
                amount: amount,
                date: date,
                type: type,
                category: isIncome ? "Service Revenue" : "Operating Expense"
            )
        }
    }
}
