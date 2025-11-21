import Foundation

/// Repository for managing contraindication alerts and red flags
class ContraindicationRepository {
    static let shared = ContraindicationRepository()

    private let contraindicationsKey = "contraindications"
    private let redFlagsKey = "red_flags"

    private init() {}

    // MARK: - Contraindications

    func getAllContraindications() -> [ContraindicationAlert] {
        guard let data = UserDefaults.standard.data(forKey: contraindicationsKey),
              let contraindications = try? JSONDecoder().decode([ContraindicationAlert].self, from: data) else {
            return []
        }
        return contraindications
    }

    func saveContraindication(_ contraindication: ContraindicationAlert) {
        var all = getAllContraindications()
        all.append(contraindication)
        save(contraindications: all)
    }

    func updateContraindication(_ contraindication: ContraindicationAlert) {
        var all = getAllContraindications()
        if let index = all.firstIndex(where: { $0.id == contraindication.id }) {
            all[index] = contraindication
            save(contraindications: all)
        }
    }

    func deleteContraindication(id: UUID) {
        var all = getAllContraindications()
        all.removeAll { $0.id == id }
        save(contraindications: all)
    }

    func getContraindicationsForClient(_ clientId: UUID) -> [ContraindicationAlert] {
        getAllContraindications().filter { $0.clientId == clientId }
    }

    private func save(contraindications: [ContraindicationAlert]) {
        if let data = try? JSONEncoder().encode(contraindications) {
            UserDefaults.standard.set(data, forKey: contraindicationsKey)
        }
    }

    // MARK: - Red Flags

    func getAllRedFlags() -> [RedFlagAlert] {
        guard let data = UserDefaults.standard.data(forKey: redFlagsKey),
              let redFlags = try? JSONDecoder().decode([RedFlagAlert].self, from: data) else {
            return []
        }
        return redFlags
    }

    func saveRedFlag(_ redFlag: RedFlagAlert) {
        var all = getAllRedFlags()
        all.append(redFlag)
        save(redFlags: all)
    }

    func updateRedFlag(_ redFlag: RedFlagAlert) {
        var all = getAllRedFlags()
        if let index = all.firstIndex(where: { $0.id == redFlag.id }) {
            all[index] = redFlag
            save(redFlags: all)
        }
    }

    func deleteRedFlag(id: UUID) {
        var all = getAllRedFlags()
        all.removeAll { $0.id == id }
        save(redFlags: all)
    }

    func getRedFlagsForClient(_ clientId: UUID) -> [RedFlagAlert] {
        getAllRedFlags().filter { $0.clientId == clientId }
    }

    private func save(redFlags: [RedFlagAlert]) {
        if let data = try? JSONEncoder().encode(redFlags) {
            UserDefaults.standard.set(data, forKey: redFlagsKey)
        }
    }

    // MARK: - Bulk Operations

    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: contraindicationsKey)
        UserDefaults.standard.removeObject(forKey: redFlagsKey)
    }
}
