import SwiftUI

extension Color {
    static let massageTheme = Color("MassageTheme")
    static let massageBackground = Color("MassageBackground")
    static let massageSecondary = Color("MassageSecondary")
    static let massageAccent = Color("MassageAccent")

    // Calming, spa-like color palette
    static let calmingBlue = Color(red: 0.5, green: 0.7, blue: 0.8)
    static let soothingGreen = Color(red: 0.6, green: 0.8, blue: 0.7)
    static let warmBeige = Color(red: 0.9, green: 0.85, blue: 0.75)
    static let softLavender = Color(red: 0.8, green: 0.75, blue: 0.85)
    static let tranquilTeal = Color(red: 0.4, green: 0.7, blue: 0.7)
}

extension ShapeStyle where Self == Color {
    static var massageTheme: Color { .massageTheme }
}
