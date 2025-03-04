import SwiftUI

// MARK: - Color Theme Protocol
protocol ColorThemeProvider {
    var background: Color { get }
    var secondaryBackground: Color { get }
    var primaryText: Color { get }
    var secondaryText: Color { get }
    var tertiaryText: Color { get }
    var accent: Color { get }
    var disabled: Color { get }
    var staticBlack: Color { get }
    var staticWhite: Color { get }
}

// MARK: - Default Implementation
struct DefaultColorTheme: ColorThemeProvider {
    let background = Color("Background")
    let secondaryBackground = Color("SecondaryBackground")
    let primaryText = Color("PrimaryText")
    let secondaryText = Color("SecondaryText")
    let tertiaryText = Color("TertiaryText")
    let accent = Color("Accent")
    let disabled = Color("Disabled")
    let staticBlack = Color.black
    let staticWhite = Color.white
}

// MARK: - Theme Manager
final class ThemeManager {
    static let shared = ThemeManager()
    private var currentTheme: ColorThemeProvider
    
    private init(theme: ColorThemeProvider = DefaultColorTheme()) {
        self.currentTheme = theme
    }
    
    func setTheme(_ theme: ColorThemeProvider) {
        currentTheme = theme
    }
    
    var theme: ColorThemeProvider {
        currentTheme
    }
}

// MARK: - Color Extension
extension Color {
    static var theme: ColorThemeProvider {
        ThemeManager.shared.theme
    }
    
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 