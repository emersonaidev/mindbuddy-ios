import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Design System Colors from the palette
extension Color {
    // Slate colors
    static let slate950 = Color(hex: "#020617")
    static let slate900 = Color(hex: "#0F172A")
    static let slate800 = Color(hex: "#1E293B")
    static let slate500 = Color(hex: "#64748B")
    static let slate400 = Color(hex: "#94A3B8")
    static let slate50 = Color(hex: "#F1F5F9")
    
    // Brand colors
    static let magenta600 = Color(hex: "#C026D3")
    static let purple600 = Color(hex: "#7C3AED")
    static let indigo600 = Color(hex: "#4F46E5")
}