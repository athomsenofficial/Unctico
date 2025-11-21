import Foundation
import Combine

/// Repository for staff and team management data
@MainActor
class StaffRepository: ObservableObject {
    static let shared = StaffRepository()

    @Published var staff: [StaffMember] = []
    @Published var timeOffRequests: [TimeOffRequest] = []
    @Published var rooms: [TreatmentRoom] = []
    @Published var roomAssignments: [RoomAssignment] = []
    @Published var scheduleEntries: [StaffScheduleEntry] = []

    private let staffKey = "staff_members"
    private let timeOffKey = "time_off_requests"
    private let roomsKey = "treatment_rooms"
    private let roomAssignmentsKey = "room_assignments"
    private let scheduleEntriesKey = "staff_schedule_entries"

    init() {
        loadData()
        if staff.isEmpty {
            initializeSampleData()
        }
    }

    // MARK: - Staff Management

    func addStaff(_ member: StaffMember) {
        staff.append(member)
        saveStaff()
    }

    func updateStaff(_ member: StaffMember) {
        if let index = staff.firstIndex(where: { $0.id == member.id }) {
            staff[index] = member
            saveStaff()
        }
    }

    func deleteStaff(_ member: StaffMember) {
        staff.removeAll { $0.id == member.id }
        saveStaff()
    }

    func deactivateStaff(_ member: StaffMember) {
        var updatedMember = member
        updatedMember.isActive = false
        updatedMember.terminationDate = Date()
        updateStaff(updatedMember)
    }

    func getStaff(id: UUID) -> StaffMember? {
        staff.first { $0.id == id }
    }

    func getActiveStaff() -> [StaffMember] {
        staff.filter { $0.isActive }
    }

    func getTherapists() -> [StaffMember] {
        staff.filter { $0.isActive && $0.role.canProvideServices }
    }

    func searchStaff(query: String) -> [StaffMember] {
        let lowercased = query.lowercased()
        return staff.filter {
            $0.fullName.lowercased().contains(lowercased) ||
            $0.email.lowercased().contains(lowercased) ||
            $0.phone.contains(query) ||
            $0.role.rawValue.lowercased().contains(lowercased)
        }
    }

    // MARK: - Performance Tracking

    func updatePerformanceMetrics(staffId: UUID, metrics: PerformanceMetrics) {
        if let index = staff.firstIndex(where: { $0.id == staffId }) {
            staff[index].performanceMetrics = metrics
            saveStaff()
        }
    }

    func getStaffByPerformance() -> [StaffMember] {
        staff.filter { $0.isActive && $0.performanceMetrics != nil }
            .sorted { (member1, member2) in
                guard let metrics1 = member1.performanceMetrics,
                      let metrics2 = member2.performanceMetrics else {
                    return false
                }
                return metrics1.totalRevenue > metrics2.totalRevenue
            }
    }

    // MARK: - Certifications & Training

    func addCertification(staffId: UUID, certification: Certification) {
        if let index = staff.firstIndex(where: { $0.id == staffId }) {
            staff[index].certifications.append(certification)
            saveStaff()
        }
    }

    func updateCertification(staffId: UUID, certification: Certification) {
        if let staffIndex = staff.firstIndex(where: { $0.id == staffId }),
           let certIndex = staff[staffIndex].certifications.firstIndex(where: { $0.id == certification.id }) {
            staff[staffIndex].certifications[certIndex] = certification
            saveStaff()
        }
    }

    func deleteCertification(staffId: UUID, certificationId: UUID) {
        if let staffIndex = staff.firstIndex(where: { $0.id == staffId }) {
            staff[staffIndex].certifications.removeAll { $0.id == certificationId }
            saveStaff()
        }
    }

    func addCECredit(staffId: UUID, credit: CECredit) {
        if let index = staff.firstIndex(where: { $0.id == staffId }) {
            staff[index].continuingEducation.append(credit)
            saveStaff()
        }
    }

    func getExpiringCertifications(daysAhead: Int = 30) -> [(staff: StaffMember, certification: Certification)] {
        var expiring: [(StaffMember, Certification)] = []

        for member in staff where member.isActive {
            for cert in member.certifications where cert.isExpiringSoon {
                expiring.append((member, cert))
            }
        }

        return expiring
    }

    // MARK: - Time Off Management

    func addTimeOffRequest(_ request: TimeOffRequest) {
        timeOffRequests.append(request)
        saveTimeOffRequests()
    }

    func updateTimeOffRequest(_ request: TimeOffRequest) {
        if let index = timeOffRequests.firstIndex(where: { $0.id == request.id }) {
            timeOffRequests[index] = request
            saveTimeOffRequests()
        }
    }

    func deleteTimeOffRequest(_ request: TimeOffRequest) {
        timeOffRequests.removeAll { $0.id == request.id }
        saveTimeOffRequests()
    }

    func getPendingTimeOffRequests() -> [TimeOffRequest] {
        timeOffRequests.filter { $0.isPending }.sorted { $0.requestedDate > $1.requestedDate }
    }

    func getApprovedTimeOff(staffId: UUID, dateRange: DateRange) -> [TimeOffRequest] {
        timeOffRequests.filter {
            $0.staffId == staffId &&
            $0.status == .approved &&
            $0.startDate <= dateRange.end &&
            $0.endDate >= dateRange.start
        }
    }

    func isStaffAvailable(staffId: UUID, date: Date) -> Bool {
        let dayTimeOff = timeOffRequests.filter {
            $0.staffId == staffId &&
            $0.status == .approved &&
            date >= $0.startDate &&
            date <= $0.endDate
        }
        return dayTimeOff.isEmpty
    }

    // MARK: - Room Management

    func addRoom(_ room: TreatmentRoom) {
        rooms.append(room)
        saveRooms()
    }

    func updateRoom(_ room: TreatmentRoom) {
        if let index = rooms.firstIndex(where: { $0.id == room.id }) {
            rooms[index] = room
            saveRooms()
        }
    }

    func deleteRoom(_ room: TreatmentRoom) {
        rooms.removeAll { $0.id == room.id }
        saveRooms()
    }

    func getActiveRooms() -> [TreatmentRoom] {
        rooms.filter { $0.isActive }
    }

    func assignRoom(staffId: UUID, roomId: UUID, isPrimary: Bool = false) {
        let assignment = RoomAssignment(
            staffId: staffId,
            roomId: roomId,
            isPrimary: isPrimary
        )
        roomAssignments.append(assignment)
        saveRoomAssignments()
    }

    func getRoomAssignments(staffId: UUID) -> [RoomAssignment] {
        roomAssignments.filter { $0.staffId == staffId && $0.isActive }
    }

    func getRoomsForStaff(staffId: UUID) -> [TreatmentRoom] {
        let staffRoomIds = getRoomAssignments(staffId: staffId).map { $0.roomId }
        return rooms.filter { staffRoomIds.contains($0.id) }
    }

    // MARK: - Schedule Management

    func addScheduleEntry(_ entry: StaffScheduleEntry) {
        scheduleEntries.append(entry)
        saveScheduleEntries()
    }

    func updateScheduleEntry(_ entry: StaffScheduleEntry) {
        if let index = scheduleEntries.firstIndex(where: { $0.id == entry.id }) {
            scheduleEntries[index] = entry
            saveScheduleEntries()
        }
    }

    func deleteScheduleEntry(_ entry: StaffScheduleEntry) {
        scheduleEntries.removeAll { $0.id == entry.id }
        saveScheduleEntries()
    }

    func getScheduleEntry(staffId: UUID, date: Date) -> StaffScheduleEntry? {
        let calendar = Calendar.current
        return scheduleEntries.first {
            $0.staffId == staffId && calendar.isDate($0.date, inSameDayAs: date)
        }
    }

    func getScheduleEntries(staffId: UUID, dateRange: DateRange) -> [StaffScheduleEntry] {
        scheduleEntries.filter {
            $0.staffId == staffId &&
            $0.date >= dateRange.start &&
            $0.date <= dateRange.end
        }.sorted { $0.date < $1.date }
    }

    func createWeeklySchedule(staffId: UUID, weekStartDate: Date, availability: WeeklyAvailability) {
        let calendar = Calendar.current
        var entries: [StaffScheduleEntry] = []

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) else { continue }

            let weekday = calendar.component(.weekday, from: date)
            let weekdayEnum = WeeklyAvailability.Weekday.from(weekday: weekday)
            let dayAvailability = availability.availability(for: weekdayEnum)

            if dayAvailability.isAvailable {
                // Create times for this date
                let startComponents = dayAvailability.startTime.split(separator: ":")
                let endComponents = dayAvailability.endTime.split(separator: ":")

                guard startComponents.count == 2, endComponents.count == 2,
                      let startHour = Int(startComponents[0]),
                      let startMinute = Int(startComponents[1]),
                      let endHour = Int(endComponents[0]),
                      let endMinute = Int(endComponents[1]) else {
                    continue
                }

                var startTime = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: date)!
                var endTime = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: date)!

                let entry = StaffScheduleEntry(
                    staffId: staffId,
                    date: date,
                    startTime: startTime,
                    endTime: endTime,
                    isAvailable: true
                )
                entries.append(entry)
            }
        }

        // Add all entries
        scheduleEntries.append(contentsOf: entries)
        saveScheduleEntries()
    }

    // MARK: - Statistics

    func getStatistics() -> TeamStatistics {
        let service = StaffService.shared

        // Get performance metrics for all staff
        var performanceMetrics: [UUID: PerformanceMetrics] = [:]
        for member in staff where member.isActive {
            if let metrics = member.performanceMetrics {
                performanceMetrics[member.id] = metrics
            }
        }

        return service.calculateTeamStatistics(
            staff: staff,
            timeOffRequests: timeOffRequests,
            scheduleEntries: scheduleEntries,
            performanceMetrics: performanceMetrics
        )
    }

    // MARK: - Persistence

    private func loadData() {
        if let staffData = UserDefaults.standard.data(forKey: staffKey),
           let decodedStaff = try? JSONDecoder().decode([StaffMember].self, from: staffData) {
            staff = decodedStaff
        }

        if let timeOffData = UserDefaults.standard.data(forKey: timeOffKey),
           let decodedTimeOff = try? JSONDecoder().decode([TimeOffRequest].self, from: timeOffData) {
            timeOffRequests = decodedTimeOff
        }

        if let roomsData = UserDefaults.standard.data(forKey: roomsKey),
           let decodedRooms = try? JSONDecoder().decode([TreatmentRoom].self, from: roomsData) {
            rooms = decodedRooms
        }

        if let assignmentsData = UserDefaults.standard.data(forKey: roomAssignmentsKey),
           let decodedAssignments = try? JSONDecoder().decode([RoomAssignment].self, from: assignmentsData) {
            roomAssignments = decodedAssignments
        }

        if let scheduleData = UserDefaults.standard.data(forKey: scheduleEntriesKey),
           let decodedSchedule = try? JSONDecoder().decode([StaffScheduleEntry].self, from: scheduleData) {
            scheduleEntries = decodedSchedule
        }
    }

    private func saveStaff() {
        if let encoded = try? JSONEncoder().encode(staff) {
            UserDefaults.standard.set(encoded, forKey: staffKey)
        }
    }

    private func saveTimeOffRequests() {
        if let encoded = try? JSONEncoder().encode(timeOffRequests) {
            UserDefaults.standard.set(encoded, forKey: timeOffKey)
        }
    }

    private func saveRooms() {
        if let encoded = try? JSONEncoder().encode(rooms) {
            UserDefaults.standard.set(encoded, forKey: roomsKey)
        }
    }

    private func saveRoomAssignments() {
        if let encoded = try? JSONEncoder().encode(roomAssignments) {
            UserDefaults.standard.set(encoded, forKey: roomAssignmentsKey)
        }
    }

    private func saveScheduleEntries() {
        if let encoded = try? JSONEncoder().encode(scheduleEntries) {
            UserDefaults.standard.set(encoded, forKey: scheduleEntriesKey)
        }
    }

    // MARK: - Sample Data

    private func initializeSampleData() {
        // Create sample rooms
        let room1 = TreatmentRoom(
            name: "Ocean Room",
            roomNumber: "1",
            capacity: 1,
            equipment: ["Massage Table", "Hot Stone Warmer", "Essential Oil Diffuser"],
            features: ["Ocean View", "Sound System", "Dim Lighting"]
        )

        let room2 = TreatmentRoom(
            name: "Forest Room",
            roomNumber: "2",
            capacity: 1,
            equipment: ["Massage Table", "Heating Pads", "Aromatherapy"],
            features: ["Garden View", "White Noise Machine"]
        )

        rooms = [room1, room2]
        saveRooms()

        // Create sample staff
        let owner = StaffMember(
            firstName: "Sarah",
            lastName: "Johnson",
            email: "sarah@unctico.com",
            phone: "555-0100",
            role: .owner,
            licenseNumber: "LMT-12345",
            licenseExpiration: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
            specializations: ["Deep Tissue", "Sports Massage", "Prenatal"],
            employmentType: .fullTime,
            compensation: CompensationModel(type: .salary, baseRate: 75000)
        )

        let therapist1 = StaffMember(
            firstName: "Michael",
            lastName: "Chen",
            email: "michael@unctico.com",
            phone: "555-0101",
            role: .massageTherapist,
            licenseNumber: "LMT-23456",
            licenseExpiration: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
            specializations: ["Swedish", "Deep Tissue", "Hot Stone"],
            employmentType: .fullTime,
            compensation: CompensationModel(
                type: .hourlyPlusCommission,
                baseRate: 30,
                commissionRate: 20
            )
        )

        let therapist2 = StaffMember(
            firstName: "Emily",
            lastName: "Rodriguez",
            email: "emily@unctico.com",
            phone: "555-0102",
            role: .massageTherapist,
            licenseNumber: "LMT-34567",
            licenseExpiration: Calendar.current.date(byAdding: .year, value: 2, to: Date()),
            specializations: ["Relaxation", "Aromatherapy", "Reflexology"],
            employmentType: .partTime,
            compensation: CompensationModel(
                type: .commission,
                commissionRate: 50
            )
        )

        let receptionist = StaffMember(
            firstName: "Jessica",
            lastName: "Martinez",
            email: "jessica@unctico.com",
            phone: "555-0103",
            role: .receptionist,
            employmentType: .partTime,
            compensation: CompensationModel(
                type: .hourly,
                baseRate: 18
            )
        )

        staff = [owner, therapist1, therapist2, receptionist]
        saveStaff()

        // Assign rooms to therapists
        assignRoom(staffId: owner.id, roomId: room1.id, isPrimary: true)
        assignRoom(staffId: therapist1.id, roomId: room1.id)
        assignRoom(staffId: therapist1.id, roomId: room2.id)
        assignRoom(staffId: therapist2.id, roomId: room2.id, isPrimary: true)
    }
}

// MARK: - Extensions

extension WeeklyAvailability.Weekday {
    static func from(weekday: Int) -> WeeklyAvailability.Weekday {
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
}
