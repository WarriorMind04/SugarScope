import SwiftUI

// MARK: - Color Hex Initializer
extension Color {
    
    /// Creates a `Color` from a hex string.
    ///
    /// Supports the following formats:
    /// - `"RGB"` – 3-character shorthand, e.g. `"F0A"`
    /// - `"RRGGBB"` – 6-character, e.g. `"A2DDC3"`
    /// - `"AARRGGBB"` – 8-character with alpha, e.g. `"80A2DDC3"`
    ///
    /// The leading `#` is optional and will be stripped automatically.
    ///
    /// - Parameter hex: A hex string representation of the color.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit shorthand)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit with alpha)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0) // Fallback: opaque black
        }

        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - SugarScope Palette
extension Color {
    // Backgrounds
    static let sugarPrimary      = Color(hex: "F2F4F8") // Soft warm grey
    static let sugarOffWhite     = Color(hex:"A2DDC3") // Plain off-white background
    static let sugarSkyBlue      = Color(hex: "E0F7FA") // Soft sky blue

    // Accents
    static let sugarSecondary    = Color(hex: "A2DDC3") // Mint green accent
    static let sugarPurple       = Color(hex: "8EABC4") // Soft blue-purple

    // Text
    static let sugarDarkText     = Color(hex: "1A2C38") // Primary dark text
    static let sugarDarkGray     = Color(hex: "2d6a4f") // Near-black text
    static let sugarSoftGray     = Color(hex: "8E8E93") // Secondary / placeholder text

    // Utility
    static let sugarSoftWhite    = Color(hex: "FFFFFF") // Pure white
    static let sugarAccentOrange = Color(hex: "FFAC81") // Warm orange for warnings/calories
}
