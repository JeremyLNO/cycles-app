import SwiftUI
import WidgetKit

/// Renders a `CycleSnapshot` for the various widget families. Shared by the widget
/// extension and the in-app widget gallery preview.
struct CyclesWidgetContent: View {
    let family: WidgetFamily
    let snapshot: CycleSnapshot

    private var lang: AppLanguage { snapshot.language }
    private var accent: Color {
        snapshot.isPeriodLate ? Palette.menstruation : Palette.color(for: snapshot.eventKind)
    }
    private var eventLabel: String {
        L.t(snapshot.eventKind == .period ? "before_period" : "before_ovulation", lang)
    }
    private var bigNumber: String { snapshot.isPeriodLate ? "\(snapshot.lateDays)" : "\(snapshot.days)" }

    /// Pregnancy mode shows weeks and never a period countdown.
    private var isPreg: Bool { snapshot.isPregnancy && snapshot.hasData }
    private var pregSymbol: String { "figure.child.circle" }

    var body: some View {
        switch family {
        case .accessoryCircular:    accessoryCircular
        case .accessoryRectangular: accessoryRectangular
        case .accessoryInline:      accessoryInline
        case .systemMedium:         medium
        default:                    small
        }
    }

    // MARK: Home-screen small
    private var small: some View {
        VStack(spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: isPreg ? pregSymbol : snapshot.phaseValue.symbol)
                    .font(.caption2)
                    .foregroundStyle(isPreg ? Palette.rose : Palette.color(for: snapshot.phaseValue))
                Text(snapshot.name.isEmpty
                     ? L.t(isPreg ? "mode_pregnancy" : snapshot.phaseValue.key, lang)
                     : snapshot.name)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.sub)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            content(alignment: .center)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            LinearGradient(colors: Palette.bg, startPoint: .top, endPoint: .bottom)
        }
    }

    // MARK: Home-screen medium
    private var medium: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle().stroke(Palette.track, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: isPreg ? pregSymbol : snapshot.phaseValue.symbol)
                    .font(.title3)
                    .foregroundStyle(isPreg ? Palette.rose : accent)
            }
            .frame(width: 78, height: 78)

            VStack(alignment: .leading, spacing: 4) {
                if !snapshot.name.isEmpty {
                    Text(snapshot.name)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(Palette.ink)
                }
                content(alignment: .leading)
                Text(L.t(isPreg ? "mode_pregnancy" : snapshot.phaseValue.key, lang))
                    .font(.caption).foregroundStyle(Palette.sub)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            LinearGradient(colors: Palette.bg, startPoint: .top, endPoint: .bottom)
        }
    }

    // MARK: Lock-screen
    private var accessoryCircular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: -2) {
                Image(systemName: isPreg ? pregSymbol : (snapshot.eventKind == .period ? "drop.fill" : "sparkles"))
                    .font(.caption2)
                Text(snapshot.hasData ? (isPreg ? "\(snapshot.weeks)" : bigNumber) : "–")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text(L.t(isPreg ? "unit_weeks" : "unit_days", lang)).font(.system(size: 8))
            }
        }
    }

    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(isPreg ? L.t("mode_pregnancy", lang)
                         : (snapshot.eventKind == .period ? L.t("next_period", lang) : L.t("phase_ovulation", lang)),
                  systemImage: isPreg ? pregSymbol : (snapshot.eventKind == .period ? "drop.fill" : "sparkles"))
                .font(.caption2.weight(.semibold))
            if snapshot.hasData {
                Text(isPreg
                     ? String(format: L.t("preg_week_fmt", lang), snapshot.weeks)
                     : (snapshot.isPeriodLate
                        ? String(format: L.t("late_fmt", lang), snapshot.lateDays)
                        : (snapshot.days == 0 ? L.t("today", lang) : L.days(snapshot.days, lang))))
                    .font(.system(.headline, design: .rounded))
            } else {
                Text(L.t("widget_no_data", lang)).font(.caption)
            }
        }
    }

    private var accessoryInline: some View {
        let sym = isPreg ? pregSymbol : (snapshot.eventKind == .period ? "drop.fill" : "sparkles")
        let label = isPreg
            ? String(format: L.t("preg_week_fmt", lang), snapshot.weeks)
            : (snapshot.days == 0 ? L.t("today", lang) : L.days(snapshot.days, lang))
        return Group {
            if snapshot.hasData {
                Text("\(Image(systemName: sym)) \(label)")
            } else {
                Text(L.t("widget_no_data", lang))
            }
        }
    }

    // MARK: Shared number block
    private func content(alignment: HorizontalAlignment = .center) -> some View {
        VStack(alignment: alignment, spacing: 0) {
            if !snapshot.hasData {
                Text(L.t("widget_no_data", lang))
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Palette.ink)
            } else if isPreg {
                Text("\(snapshot.weeks)")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.rose)
                Text(L.t(snapshot.weeks == 1 ? "unit_week" : "unit_weeks", lang))
                    .font(.caption.weight(.medium)).foregroundStyle(Palette.sub)
                Text(L.t("preg_caption", lang))
                    .font(.caption2).foregroundStyle(Palette.sub)
                    .multilineTextAlignment(alignment == .leading ? .leading : .center)
            } else if snapshot.isPeriodLate {
                Text("\(snapshot.lateDays)")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.menstruation)
                Text(L.t("late_fmt", lang).replacingOccurrences(of: "%d ", with: ""))
                    .font(.caption.weight(.medium)).foregroundStyle(Palette.sub)
            } else if snapshot.days == 0 {
                Text(L.t("today", lang))
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(accent)
                Text(eventLabel).font(.caption2).foregroundStyle(Palette.sub)
                    .multilineTextAlignment(alignment == .leading ? .leading : .center)
            } else {
                Text("\(snapshot.days)")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(accent)
                Text(eventLabel)
                    .font(.caption2.weight(.medium)).foregroundStyle(Palette.sub)
                    .multilineTextAlignment(alignment == .leading ? .leading : .center)
            }
        }
    }
}
