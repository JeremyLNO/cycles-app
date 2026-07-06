import SwiftUI

/// Formats a date using the in-app language's locale (e.g. "12 juin").
func cyclesDate(_ date: Date, lang: AppLanguage = .current, template: String = "d MMM") -> String {
    let f = DateFormatter()
    f.locale = lang.locale
    f.setLocalizedDateFormatFromTemplate(template)
    return f.string(from: date)
}

/// Soft blush background used across the app.
struct CyclesBackground: View {
    var phase: CyclePhase? = nil
    var body: some View {
        ZStack {
            LinearGradient(colors: Palette.bg, startPoint: .top, endPoint: .bottom)
            // Soft decorative glows.
            Circle()
                .fill((phase.map { Palette.color(for: $0) } ?? Palette.roseSoft).opacity(0.20))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: -120, y: -220)
            Circle()
                .fill(Palette.roseSoft.opacity(0.30))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 140, y: 260)
        }
        .ignoresSafeArea()
    }
}

/// Circular cycle progress ring with a soft glow and a marker dot.
struct ProgressRing<Content: View>: View {
    var progress: Double            // 0...1
    var colors: [Color]
    var lineWidth: CGFloat = 22
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.track, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(
                    AngularGradient(gradient: Gradient(colors: colors),
                                    center: .center,
                                    startAngle: .degrees(-90),
                                    endAngle: .degrees(270)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: (colors.last ?? Palette.rose).opacity(0.45), radius: 8, y: 2)

            // Marker dot at the leading edge of the progress arc.
            GeometryReader { geo in
                let r = min(geo.size.width, geo.size.height) / 2
                let angle = Angle.degrees(360 * min(1, max(0, progress)) - 90)
                Circle()
                    .fill(.white)
                    .frame(width: lineWidth * 0.7, height: lineWidth * 0.7)
                    .overlay(Circle().stroke(colors.last ?? Palette.rose, lineWidth: 3))
                    .position(x: geo.size.width / 2 + r * cos(angle.radians),
                              y: geo.size.height / 2 + r * sin(angle.radians))
            }

            content()
                .padding(lineWidth + 12)
        }
    }
}

/// Coloured pill showing the current phase.
struct PhaseChip: View {
    let phase: CyclePhase
    var lang: AppLanguage = .current
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: phase.symbol)
            Text(L.t(phase.key, lang))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
        }
        .foregroundStyle(Palette.color(for: phase))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(Palette.tint(for: phase)))
    }
}

/// Round avatar with the profile's initial, tinted with its accent colour.
struct ProfileAvatar: View {
    let name: String
    let colorHex: String
    var size: CGFloat = 40
    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }
    var body: some View {
        let c = Palette.from(hex: colorHex)
        Circle()
            .fill(LinearGradient(colors: [c.opacity(0.85), c], startPoint: .top, endPoint: .bottom))
            .frame(width: size, height: size)
            .overlay {
                if trimmed.isEmpty {
                    Image(systemName: "drop.fill")
                        .font(.system(size: size * 0.42, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text(String(trimmed.prefix(1)).uppercased())
                        .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 2))
            .shadow(color: c.opacity(0.35), radius: 4, y: 2)
    }
}

/// Frosted card container.
struct GlassCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content
    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Palette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Palette.cardStroke, lineWidth: 1)
                    )
            )
            .shadow(color: Palette.rose.opacity(0.10), radius: 10, y: 4)
    }
}

/// Small labelled stat used in the info row (date + caption).
struct StatTile: View {
    let icon: String
    let title: String
    let value: String
    var tint: Color = Palette.rose
    var body: some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: icon).foregroundStyle(tint)
                    Text(title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Palette.sub)
                }
                Text(value)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Palette.ink)
            }
        }
    }
}
