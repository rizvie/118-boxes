import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

enum Theme {
    // Surfaces: deep lab-bench navy, so the samples glow off it.
    static let bg      = Color(hex: 0x0B0E16)
    static let panel   = Color(hex: 0x161B27)
    static let panelHi = Color(hex: 0x1F2634)
    static let line    = Color.white.opacity(0.09)

    // Feedback
    static let right = Color(hex: 0x2ED573)
    static let wrong = Color(hex: 0xFF4757)
    static let star  = Color(hex: 0xFFC93C)
    static let accent = Color(hex: 0x4D8DFF)

    // Text
    static let textHi = Color(hex: 0xF3F6FB)
    static let textLo = Color(hex: 0x8A93A6)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// A big soft card used all over the app.
struct Card<Content: View>: View {
    var tint: Color = Theme.panel
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(tint)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Theme.line, lineWidth: 1)
                    )
            )
    }
}
