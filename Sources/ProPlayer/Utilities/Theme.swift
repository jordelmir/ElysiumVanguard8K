import SwiftUI

// MARK: - ProPlayer Design System

enum ProTheme {

    // MARK: - Colors

    enum Colors {
        // Primary backgrounds
        static let background = Color(nsColor: NSColor.windowBackgroundColor)
        static let deepBlack = Color(red: 0.02, green: 0.04, blue: 0.06)
        static let surfaceDark = Color(red: 0.05, green: 0.08, blue: 0.12)
        static let surfaceMedium = Color(red: 0.08, green: 0.12, blue: 0.18)
        static let surfaceLight = Color(red: 0.12, green: 0.18, blue: 0.25)

        // Accent colors
        static let accentBlue = Color(red: 0.1, green: 0.9, blue: 1.0)      // Elysium Cyan
        static let accentPurple = Color(red: 0.55, green: 0.36, blue: 1.0)    // #8C5CFF
        static let accentGreen = Color(red: 0.0, green: 0.87, blue: 0.62)     // #00DE9E
        static let accentOrange = Color(red: 1.0, green: 0.55, blue: 0.0)     // #FF8C00
        static let accentRed = Color(red: 1.0, green: 0.27, blue: 0.35)       // #FF4559

        // Gradients
        static let accentGradient = LinearGradient(
            colors: [accentBlue, accentPurple],
            startPoint: .leading,
            endPoint: .trailing
        )
        static let controlsGradient = LinearGradient(
            colors: [Color.black.opacity(0.0), Color.black.opacity(0.85)],
            startPoint: .top,
            endPoint: .bottom
        )
        static let topBarGradient = LinearGradient(
            colors: [Color.black.opacity(0.7), Color.black.opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )

        // Text
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.4)

        // Controls
        static let controlBackground = Color.white.opacity(0.1)
        static let controlHover = Color.white.opacity(0.2)
        static let controlActive = Color.white.opacity(0.3)

        // Timeline
        static let timelineBackground = Color.white.opacity(0.15)
        static let timelineBuffer = Color.white.opacity(0.3)
        static let timelineProgress = accentBlue
    }

    // MARK: - Typography

    enum Fonts {
        static let displayLarge = Font.system(size: 28, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let subheadline = Font.system(size: 14, weight: .medium, design: .default)
        static let body = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
        static let mono = Font.system(size: 13, weight: .medium, design: .monospaced)
        static let monoSmall = Font.system(size: 11, weight: .medium, design: .monospaced)
        static let controlLabel = Font.system(size: 12, weight: .medium, design: .default)
        static let osd = Font.system(size: 24, weight: .bold, design: .rounded)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: - Corner Radii

    enum Radius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 14
        static let xl: CGFloat = 20
    }

    // MARK: - Shadows

    enum Shadows {
        static let small = Shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        static let medium = Shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        static let large = Shadow(color: .black.opacity(0.5), radius: 16, x: 0, y: 8)
    }

    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    // MARK: - Animation

    enum Animations {
        static let quick = Animation.easeInOut(duration: 0.15)
        static let standard = Animation.easeInOut(duration: 0.25)
        static let smooth = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.4) // Elite Cubic-Bezier
        static let slow = Animation.easeInOut(duration: 0.6)
        
        // Elite Springs
        static let spring = Animation.interpolatingSpring(mass: 1.0, stiffness: 100, damping: 15, initialVelocity: 0)
        static let interactive = Animation.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0)
        static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0)
        static let elastic = Animation.spring(response: 0.5, dampingFraction: 0.4, blendDuration: 0)
    }
}

// MARK: - View Modifiers

struct GlassBackgroundModifier: ViewModifier {
    var cornerRadius: CGFloat = ProTheme.Radius.medium
    var opacity: Double = 0.3

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(opacity))
            .background(Color.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

struct HoverEffectModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .shadow(color: isHovered ? ProTheme.Colors.accentBlue.opacity(0.6) : .clear, radius: 12)
            .animation(ProTheme.Animations.quick, value: isHovered)
            .onHover { hovering in isHovered = hovering }
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = ProTheme.Radius.medium, opacity: Double = 0.3) -> some View {
        modifier(GlassBackgroundModifier(cornerRadius: cornerRadius, opacity: opacity))
    }

    func hoverEffect() -> some View {
        modifier(HoverEffectModifier())
    }
}
