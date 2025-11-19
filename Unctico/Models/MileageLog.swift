// MileageLog.swift
// Mileage tracking for IRS tax deductions

import Foundation
import CoreLocation

/// Represents a mileage log entry for tax deductions
struct MileageLog: Codable, Identifiable {
    let id: UUID
    var date: Date
    var startLocation: String
    var endLocation: String
    var purpose: MileagePurpose
    var businessPurpose: String // Detailed description
    var miles: Double
    var odometerStart: Double?
    var odometerEnd: Double?

    // Client/Appointment linking
    var clientId: UUID?
    var appointmentId: UUID?

    // Rate tracking (changes annually)
    var ratePerMile: Decimal // IRS standard mileage rate
    var deductionAmount: Decimal { Decimal(miles) * ratePerMile }

    // Location tracking (optional)
    var startCoordinates: LocationCoordinates?
    var endCoordinates: LocationCoordinates?
    var routeDistance: Double? // From GPS/mapping service

    // Metadata
    var notes: String?
    var isRoundTrip: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        startLocation: String,
        endLocation: String,
        purpose: MileagePurpose,
        businessPurpose: String,
        miles: Double,
        ratePerMile: Decimal = MileageLog.currentIRSRate()
    ) {
        self.id = id
        self.date = date
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.purpose = purpose
        self.businessPurpose = businessPurpose
        self.miles = miles
        self.ratePerMile = ratePerMile
        self.isRoundTrip = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Month and year for grouping
    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    /// Year for annual reports
    var year: Int {
        Calendar.current.component(.year, from: date)
    }

    /// Display string
    var displayString: String {
        "\(startLocation) → \(endLocation) (\(formatMiles(miles)) mi)"
    }

    /// Round trip miles
    var totalMiles: Double {
        isRoundTrip ? miles * 2 : miles
    }

    /// Total deduction including round trip
    var totalDeduction: Decimal {
        Decimal(totalMiles) * ratePerMile
    }

    // MARK: - Helper Methods

    private func formatMiles(_ miles: Double) -> String {
        String(format: "%.1f", miles)
    }

    /// Get current IRS standard mileage rate
    static func currentIRSRate(year: Int? = nil) -> Decimal {
        let taxYear = year ?? Calendar.current.component(.year, from: Date())

        // IRS standard mileage rates by year
        switch taxYear {
        case 2024: return 0.67 // 67 cents per mile
        case 2023: return 0.655 // 65.5 cents per mile
        case 2022: return 0.625 // 62.5 cents per mile (Jan-Jun), 0.585 (Jul-Dec)
        case 2021: return 0.56
        case 2020: return 0.575
        default: return 0.67 // Default to 2024 rate
        }
    }
}

// MARK: - Mileage Purpose

enum MileagePurpose: String, Codable, CaseIterable, Identifiable {
    case clientVisit = "Client Visit"
    case homeVisit = "Home Visit"
    case supplyPickup = "Supply Pickup"
    case bankDeposit = "Bank Deposit"
    case professionalMeeting = "Professional Meeting"
    case conference = "Conference/Training"
    case marketingEvent = "Marketing Event"
    case officeCommute = "Office Commute"
    case other = "Other Business"

    var id: String { rawValue }

    /// Icon for UI
    var icon: String {
        switch self {
        case .clientVisit, .homeVisit: return "person.fill"
        case .supplyPickup: return "cart.fill"
        case .bankDeposit: return "building.columns.fill"
        case .professionalMeeting: return "person.2.fill"
        case .conference: return "graduationcap.fill"
        case .marketingEvent: return "megaphone.fill"
        case .officeCommute: return "building.2.fill"
        case .other: return "car.fill"
        }
    }

    /// Whether this purpose is typically deductible
    var isDeductible: Bool {
        // Office commute is generally NOT deductible (home to regular office)
        // All other business travel is deductible
        switch self {
        case .officeCommute: return false
        default: return true
        }
    }
}

// MARK: - Location Coordinates

struct LocationCoordinates: Codable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(from location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }

    /// Calculate distance to another coordinate (in miles)
    func distance(to other: LocationCoordinates) -> Double {
        let from = CLLocation(latitude: latitude, longitude: longitude)
        let to = CLLocation(latitude: other.latitude, longitude: other.longitude)
        let meters = from.distance(from: to)
        return meters * 0.000621371 // Convert meters to miles
    }
}

// MARK: - Mileage Statistics

struct MileageStatistics {
    let totalTrips: Int
    let totalMiles: Double
    let totalDeduction: Decimal
    let byPurpose: [MileagePurpose: Double]
    let averageMilesPerTrip: Double
    let longestTrip: MileageLog?
}

// MARK: - Preview

#Preview {
    let log = MileageLog(
        startLocation: "Home",
        endLocation: "Client Location",
        purpose: .clientVisit,
        businessPurpose: "60-minute massage appointment with Jane Smith",
        miles: 12.5
    )
    return Text(log.displayString)
}
