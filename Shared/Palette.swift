import SwiftUI

/// Pastel palette with a dominant soft pink, shared between the app and the widget.
/// Each cycle phase has its own tint so the UI is colour-coded at a glance.
enum Palette {
    // Text
    static let ink = Color(red: 0.27, green: 0.16, blue: 0.24)   // deep plum
    static let sub = Color(red: 0.55, green: 0.45, blue: 0.52)

    // Backgrounds (blush gradient)
    static let bgTop = Color(red: 1.00, green: 0.95, blue: 0.97)
    static let bgBot = Color(red: 1.00, green: 0.89, blue: 0.93)

    // Card surface
    static let card = Color.white.opacity(0.72)
    static let cardStroke = Color.white.opacity(0.85)

    // Primary rose accent
    static let rose = Color(red: 0.95, green: 0.45, blue: 0.62)
    static let roseDeep = Color(red: 0.86, green: 0.30, blue: 0.50)
    static let roseSoft = Color(red: 1.00, green: 0.78, blue: 0.85)

    // Phase tints
    static let menstruation = Color(red: 0.93, green: 0.36, blue: 0.51) // raspberry rose
    static let follicular   = Color(red: 0.74, green: 0.62, blue: 0.93) // lilac
    static let fertile      = Color(red: 0.36, green: 0.74, blue: 0.69) // mint/teal
    static let ovulation    = Color(red: 0.20, green: 0.66, blue: 0.74) // bright teal
    static let luteal       = Color(red: 0.98, green: 0.66, blue: 0.51) // peach

    static func color(for phase: CyclePhase) -> Color {
        switch phase {
        case .menstruation: return menstruation
        case .follicular:   return follicular
        case .fertile:      return fertile
        case .ovulation:    return ovulation
        case .luteal:       return luteal
        }
    }

    /// Soft tint used as a card/pill background behind the phase colour.
    static func tint(for phase: CyclePhase) -> Color { color(for: phase).opacity(0.16) }

    /// Gradient for the hero ring, tinted toward the current phase.
    static func ring(for phase: CyclePhase) -> [Color] {
        let c = color(for: phase)
        return [c.opacity(0.55), c, roseDeep.opacity(0.85)]
    }

    static let bg: [Color] = [bgTop, bgBot]

    /// Track colour behind the progress ring.
    static let track = Color(red: 0.97, green: 0.86, blue: 0.90)

    // Event accent colours (period vs ovulation) for the hero/widget.
    static func color(for kind: NextEventKind) -> Color {
        kind == .period ? menstruation : ovulation
    }

    /// Decode a "#RRGGBB" string into a Color (falls back to rose).
    static func from(hex: String) -> Color {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return rose }
        let r = Double((v & 0xFF0000) >> 16) / 255.0
        let g = Double((v & 0x00FF00) >> 8) / 255.0
        let b = Double(v & 0x0000FF) / 255.0
        return Color(red: r, green: g, blue: b)
    }

    /// Curated accent choices offered when creating/editing a profile.
    static let profileSwatches: [String] = [
        "#F2738F", // rose
        "#C39BEE", // lilac
        "#5CBDB0", // teal
        "#FBA984", // peach
        "#F4A0C0", // pink
        "#7FB2F0", // sky
        "#E8728C", // raspberry
        "#9AD0A6", // sage
    ]
}
