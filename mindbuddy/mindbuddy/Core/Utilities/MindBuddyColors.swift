import SwiftUI

// MARK: - MindBuddy Color Theme
extension Color {
    struct MindBuddy {
        // Background Colors
        static let background = Color(red: 0.06, green: 0.05, blue: 0.10)
        static let cardBackground = Color.white.opacity(0.05)
        static let numberBackground = Color.white.opacity(0.10)
        
        // Accent Colors
        static let primaryAccent = Color(red: 0.31, green: 0.27, blue: 0.90)
        static let secondaryAccent = Color(red: 0.75, green: 0.15, blue: 0.83)
        
        // Text Colors
        static let textPrimary = Color.white
        static let textSecondary = Color(red: 0.58, green: 0.64, blue: 0.72)
        static let textTertiary = Color(red: 0.80, green: 0.84, blue: 0.88)
        
        // Semantic Colors
        static let success = Color(red: 0.20, green: 0.80, blue: 0.40)
        static let warning = Color(red: 1.00, green: 0.75, blue: 0.00)
        static let error = Color(red: 0.95, green: 0.20, blue: 0.20)
    }
}

// MARK: - Color Assets (Alternative approach using Assets catalog)
// If you prefer using Asset Catalog colors, create these in Assets.xcassets:
/*
 1. Open Assets.xcassets
 2. Right-click and choose "New Color Set"
 3. Name it appropriately (e.g., "MindBuddyBackground")
 4. Set the color values for Any Appearance and Dark Appearance
 5. Use in code: Color("MindBuddyBackground")
 */

// MARK: - Dynamic Color Extension
extension Color {
    /// Creates a color that adapts to light/dark mode
    static func mindBuddyAdaptive(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - Gradient Definitions
extension LinearGradient {
    static let mindBuddyPrimary = LinearGradient(
        colors: [Color.MindBuddy.primaryAccent, Color.MindBuddy.secondaryAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Shadow Styles
extension View {
    func mindBuddyCardShadow() -> some View {
        self.shadow(color: .white.opacity(0.1), radius: 0)
    }
    
    func mindBuddyButtonShadow() -> some View {
        self.shadow(color: .black.opacity(0.1), radius: 6, y: 4)
    }
}