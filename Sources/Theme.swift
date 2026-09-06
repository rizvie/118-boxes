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

/// Bright chrome, dark boxes.
///
/// The app used to be navy throughout, on the reasoning that the samples glow
/// off a dark ground. That is true, and it is also why the whole thing read as
/// a reference tool rather than something built for a six-year-old.
///
/// So the frame is bright and warm, and every element sample keeps its own deep
/// box. The name stops being a label and becomes the design: 118 dark specimen
/// boxes sitting on a bright shelf.
enum Theme {
    // Surfaces
    static let bg      = Color(hex: 0xFFF4E6)   // warm shelf
    static let panel   = Color(hex: 0xFFFFFF)   // cards sit on the shelf
    static let panelHi = Color(hex: 0xFFE9CC)   // recessed / track
    static let line    = Color(hex: 0x171B28, alpha: 0.14)

    /// The inside of a specimen box. Everything ElementArt draws sits on this,
    /// which is what keeps the glowing gases and discharge tubes working.
    static let box     = Color(hex: 0x0B0E16)
    static let boxLine = Color(hex: 0x171B28)

    // Feedback. Saturated on purpose: these are the moments a child looks at.
    static let right = Color(hex: 0x1FBF63)
    static let wrong = Color(hex: 0xFF4757)
    static let star  = Color(hex: 0xFFB800)
    static let accent = Color(hex: 0x2F6BFF)

    // Text
    static let textHi = Color(hex: 0x171B28)
    static let textLo = Color(hex: 0x6B6355)

    /// Rounded type that honours Dynamic Type.
    ///
    /// `.system(size:)` is a fixed point size and does not scale, so the app
    /// used to ignore the user's text size setting completely. Mapping the
    /// numeric size to the nearest text style gets real scaling from one place
    /// rather than reworking every call site.
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(textStyle(for: size), design: .rounded).weight(weight)
    }

    private static func textStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<11:  return .caption2
        case ..<13:  return .caption
        case ..<15:  return .footnote
        case ..<16:  return .subheadline
        case ..<18:  return .body
        case ..<21:  return .title3
        case ..<27:  return .title2
        case ..<34:  return .title
        default:     return .largeTitle
        }
    }
}

/// A chunky sticker card: solid ink outline and a hard bottom edge rather than
/// a soft shadow, so it reads as a physical thing a child could press.
///
/// Still called Card because QuizView already uses it under that name; the
/// styling changed, the call sites did not.
struct Card<Content: View>: View {
    var tint: Color = Theme.panel
    var radius: CGFloat = 24
    var depth: CGFloat = 5
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(Theme.boxLine)
                        .offset(y: depth)
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(tint)
                        .overlay(
                            RoundedRectangle(cornerRadius: radius, style: .continuous)
                                .strokeBorder(Theme.boxLine, lineWidth: 3)
                        )
                }
            )
            .padding(.bottom, depth)
    }
}


/// Keeps content to a comfortable column instead of stretching edge to edge on
/// iPad. Without this the iPhone layout runs the full width of a 13" screen and
/// leaves two thirds of it empty, which is what shipping "universal" as a one
/// line Info.plist change actually looks like.
struct ReadableColumn: ViewModifier {
    var maxWidth: CGFloat = 640

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)   // centre the column in the screen
    }
}

extension View {
    func readableColumn(_ maxWidth: CGFloat = 640) -> some View {
        modifier(ReadableColumn(maxWidth: maxWidth))
    }
}
