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

// MARK: - Minimalist Liquid Glass Modifier
public struct MinimalistLiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var borderOpacity: Double = 0.22
    var glowColor: Color = .white
    var hasShadow: Bool = true
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        // Razor-sharp 0.8pt iridescent light edge
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        glowColor.opacity(borderOpacity * 1.6),
                                        Color.white.opacity(borderOpacity * 0.5),
                                        Color.white.opacity(0.04),
                                        glowColor.opacity(borderOpacity * 0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.85
                            )
                    )
                    .shadow(color: hasShadow ? Color.black.opacity(0.16) : .clear, radius: 12, x: 0, y: 6)
            )
    }
}

public extension View {
    func liquidGlass(
        cornerRadius: CGFloat = 20,
        borderOpacity: Double = 0.22,
        glowColor: Color = .white,
        hasShadow: Bool = true
    ) -> some View {
        self.modifier(MinimalistLiquidGlassModifier(
            cornerRadius: cornerRadius,
            borderOpacity: borderOpacity,
            glowColor: glowColor,
            hasShadow: hasShadow
        ))
    }
}

// MARK: - Subtle Minimalist Ambient Background
public struct LiquidAmbientBackground: View {
    var theme: GlassTheme = .obsidian
    @State private var animateGradient: Bool = false
    
    public init(theme: GlassTheme = .obsidian) {
        self.theme = theme
    }
    
    public var body: some View {
        ZStack {
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 10.0).repeatForever(autoreverses: true), value: animateGradient)
            
            GeometryReader { geo in
                // Very subtle, minimalist refractive glowing orbs
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.18), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: geo.size.width * 0.45
                        )
                    )
                    .frame(width: geo.size.width * 0.75, height: geo.size.width * 0.75)
                    .offset(x: animateGradient ? -30 : 30, y: animateGradient ? -50 : 10)
                    .blur(radius: 65)
                    .blendMode(.screen)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: geo.size.width * 0.45
                        )
                    )
                    .frame(width: geo.size.width * 0.8, height: geo.size.width * 0.8)
                    .offset(x: animateGradient ? 50 : -40, y: geo.size.height * 0.42)
                    .blur(radius: 75)
                    .blendMode(.screen)
            }
            .ignoresSafeArea()
            
            // Ultra-thin obsidian veil
            Color.black.opacity(0.12)
                .ignoresSafeArea()
        }
        .onAppear {
            animateGradient = true
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
                    .fill(isSelected ? AnyShapeStyle(color.opacity(0.3)) : AnyShapeStyle(.ultraThinMaterial))
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isSelected ? color.opacity(0.75) : Color.white.opacity(0.14),
                                lineWidth: 0.8
                            )
                    )
                    .shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Minimalist Glass Search Bar
public struct LiquidGlassSearchBar: View {
    @Binding var text: String
    var isAIModeActive: Bool
    var onToggleAIMode: () -> Void
    
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isAIModeActive ? "sparkle" : "magnifyingglass")
                .foregroundColor(isAIModeActive ? .cyan : .secondary)
                .font(.system(size: 14, weight: .semibold))
            
            TextField(isAIModeActive ? "Recherche IA (factures, urgences, voyages)..." : "Recherche universelle...", text: $text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
            }
            
            Button(action: {
                Haptics.light()
                onToggleAIMode()
            }) {
                HStack(spacing: 3) {
                    Text("IA")
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(isAIModeActive ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08))
                )
                .foregroundColor(isAIModeActive ? .cyan : .secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .liquidGlass(cornerRadius: 15, borderOpacity: isAIModeActive ? 0.45 : 0.18, glowColor: isAIModeActive ? .cyan : .white)
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
