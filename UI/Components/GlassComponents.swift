import SwiftUI

// MARK: - Haptic Feedback Manager
public struct Haptics {
    public static func light() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    public static func medium() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    public static func success() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
    }
    
    public static func warning() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
        #endif
    }
}

// MARK: - Minimalist Liquid Glass Themes
public enum GlassTheme: String, CaseIterable, Identifiable {
    case obsidian = "Obsidienne Pure (Minimaliste)"
    case aurora = "Aurore Liquide"
    case titanium = "Titane Sombre"
    case opal = "Opale Glacée"
    
    public var id: String { rawValue }
    
    public var gradientColors: [Color] {
        switch self {
        case .obsidian:
            return [
                Color(red: 0.04, green: 0.05, blue: 0.08),
                Color(red: 0.06, green: 0.07, blue: 0.11),
                Color(red: 0.02, green: 0.03, blue: 0.05)
            ]
        case .aurora:
            return [
                Color(red: 0.05, green: 0.08, blue: 0.16),
                Color(red: 0.08, green: 0.16, blue: 0.22),
                Color(red: 0.03, green: 0.04, blue: 0.08)
            ]
        case .titanium:
            return [
                Color(red: 0.09, green: 0.09, blue: 0.11),
                Color(red: 0.14, green: 0.14, blue: 0.16),
                Color(red: 0.05, green: 0.05, blue: 0.06)
            ]
        case .opal:
            return [
                Color(red: 0.12, green: 0.14, blue: 0.20),
                Color(red: 0.18, green: 0.20, blue: 0.28),
                Color(red: 0.08, green: 0.09, blue: 0.14)
            ]
        }
    }
}

// MARK: - Minimalist Liquid Glass Card Modifier
public struct MinimalistLiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var borderOpacity: Double = 0.20
    var glowColor: Color = .white
    var hasShadow: Bool = false
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        glowColor.opacity(borderOpacity * 1.5),
                                        Color.white.opacity(borderOpacity * 0.4),
                                        Color.white.opacity(0.02),
                                        glowColor.opacity(borderOpacity * 0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    )
            )
    }
}

public extension View {
    func liquidGlass(
        cornerRadius: CGFloat = 16,
        borderOpacity: Double = 0.20,
        glowColor: Color = .white,
        hasShadow: Bool = false
    ) -> some View {
        self.modifier(MinimalistLiquidGlassModifier(
            cornerRadius: cornerRadius,
            borderOpacity: borderOpacity,
            glowColor: glowColor,
            hasShadow: hasShadow
        ))
    }
}

// MARK: - Seamless Full-Screen Edge-to-Edge Ambient Background (No Ugly Square Bounds)
public struct LiquidAmbientBackground: View {
    var theme: GlassTheme = .obsidian
    
    public init(theme: GlassTheme = .obsidian) {
        self.theme = theme
    }
    
    public var body: some View {
        ZStack {
            // Base full-screen gradient covering 100% of the screen
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Soft atmospheric lighting without clipping geometry
            RadialGradient(
                colors: [Color.cyan.opacity(0.12), Color.clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 500
            )
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [Color.purple.opacity(0.10), Color.clear],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 600
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Minimalist Pill Badge
public struct LiquidPillBadge: View {
    var title: String
    var icon: String? = nil
    var color: Color = .cyan
    var isSelected: Bool = false
    var action: () -> Void
    
    public var body: some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium, design: .rounded))
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 7)
            .foregroundColor(isSelected ? .white : .secondary)
            .background(
                Capsule()
                    .fill(isSelected ? AnyShapeStyle(color.opacity(0.28)) : AnyShapeStyle(.ultraThinMaterial))
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isSelected ? color.opacity(0.7) : Color.white.opacity(0.12),
                                lineWidth: 0.8
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Provider Brand Badge View
public struct ProviderBrandBadge: View {
    var provider: EmailProvider
    var size: CGFloat = 18
    
    public var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: provider.brandColorHex).opacity(0.85))
                .frame(width: size, height: size)
            
            Image(systemName: provider.iconName)
                .font(.system(size: size * 0.50, weight: .bold))
                .foregroundColor(.white)
        }
        .overlay(
            Circle()
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.7)
        )
    }
}

// MARK: - Color Hex Extension
public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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
