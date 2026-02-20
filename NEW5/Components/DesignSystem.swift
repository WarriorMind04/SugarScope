import SwiftUI
// Color palette and hex initializer are defined in Color+SugarPalette.swift

// MARK: - Gradient Background (Deprecated for Minimalist)
struct SugarGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.sugarSkyBlue, Color.sugarSecondary.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Design Modifiers

// Enhanced Glassmorphism (Kept for reference, but Minimalist uses Solid)
struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// Solid white card style (Cleaner)
struct SolidCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20)) // Slightly tighter border radius
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4) // Very subtle shadow
    }
}

// Casual Typography: Lowercase, Bold
struct CasualCatchphraseModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 24, weight: .bold, design: .default))
            .textCase(.lowercase)
            .foregroundColor(Color(hex: "656d4a"))
    }
}

// Clean Data Typography: Sans-Serif, Legible
struct CleanDataModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.body, design: .default))
            .foregroundColor(.sugarDarkGray)
    }
}

struct PrimaryButtonModifier: ViewModifier {
    var backgroundColor: Color = .sugarDarkGray // Dark Gray/Black for emphasis
    
    func body(content: Content) -> some View {
        content
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16)) // Tighter radius
            .shadow(color: backgroundColor.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct SecondaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.sugarDarkGray)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.sugarOffWhite) // Slight contrast
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
    }
}

extension View {
    func minimalistBackground() -> some View {
        self.background(Color.sugarOffWhite.ignoresSafeArea())
    }

    func glassCardStyle() -> some View {
        modifier(GlassCardModifier())
    }
    
    func solidCardStyle() -> some View {
        modifier(SolidCardModifier())
    }
    
    func casualTextStyle() -> some View {
        modifier(CasualCatchphraseModifier())
    }
    
    func cleanDataStyle() -> some View {
        modifier(CleanDataModifier())
    }
    
    func primaryButtonStyle(color: Color = .sugarDarkGray) -> some View {
        modifier(PrimaryButtonModifier(backgroundColor: color))
    }
    
    func secondaryButtonStyle() -> some View {
        modifier(SecondaryButtonModifier())
    }
    
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
