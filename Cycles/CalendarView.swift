import SwiftUI
import SwiftData

/// Month calendar with colour-coded days. Tapping a day logs or edits a period start.
struct CalendarView: View {
    @Query(sort: \Profile.order) private var profiles: [Profile]
    @AppStorage("selectedProfileID") private var selectedID = ""
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.systemDefault.rawValue

    @State private var anchor = Date()
    @State private var selection: DaySelection?

    private struct DaySelection: Identifiable { let id = UUID(); let date: Date }

    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }
    private var profile: Profile? {
        profiles.first { $0.id.uuidString == selectedID } ?? profiles.first
    }
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = lang.locale
        return c
    }

    enum Marker { case none, periodActual, periodPredicted, fertile, ovulation, pms }

    var body: some View {
        ZStack {
            CyclesBackground()
            ScrollView {
                VStack(spacing: 18) {
                    header
                    weekdayRow
                    grid
                    legend
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .sheet(item: $selection) { sel in
            if let profile {
                LogPeriodSheet(profile: profile, date: sel.date, existing: existingEntry(on: sel.date))
            }
        }
    }

    // MARK: Header (month + paging)
    private var header: some View {
        HStack {
            Button { shift(-1) } label: { chevron("chevron.left") }
            Spacer()
            Text(cyclesDate(anchor, lang: lang, template: "MMMM yyyy").capitalized)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Palette.ink)
            Spacer()
            Button { shift(1) } label: { chevron("chevron.right") }
        }
        .padding(.top, 8)
    }

    private func chevron(_ name: String) -> some View {
        Image(systemName: name)
            .font(.headline.weight(.bold))
            .foregroundStyle(Palette.rose)
            .frame(width: 40, height: 40)
            .background(Circle().fill(Palette.card))
    }

    private var weekdayRow: some View {
        let symbols = orderedWeekdaySymbols()
        return HStack(spacing: 0) {
            ForEach(symbols, id: \.self) { s in
                Text(s.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.sub)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Day grid
    private var grid: some View {
        let days = monthDays()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let marker = self.marker(for: date)
        let isToday = cal.isDateInToday(date)
        let dayNum = cal.component(.day, from: date)
        return Button {
            selection = DaySelection(date: date)
        } label: {
            Text("\(dayNum)")
                .font(.system(.callout, design: .rounded).weight(isToday ? .bold : .regular))
                .foregroundStyle(textColor(marker))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(background(marker))
                .overlay(
                    Circle().stroke(Palette.rose, lineWidth: isToday ? 2 : 0)
                )
                .overlay(alignment: .top) {
                    if marker == .ovulation {
                        Image(systemName: "sparkles")
                            .font(.system(size: 8))
                            .foregroundStyle(Palette.ovulation)
                            .offset(y: 2)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func background(_ m: Marker) -> some View {
        switch m {
        case .periodActual:    Circle().fill(Palette.menstruation)
        case .periodPredicted: Circle().fill(Palette.menstruation.opacity(0.20)).overlay(Circle().strokeBorder(Palette.menstruation.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3])))
        case .fertile:         Circle().fill(Palette.fertile.opacity(0.22))
        case .ovulation:       Circle().fill(Palette.ovulation.opacity(0.30))
        case .pms:             Circle().fill(Palette.pms.opacity(0.20))
        case .none:            Circle().fill(Color.clear)
        }
    }

    private func textColor(_ m: Marker) -> Color {
        switch m {
        case .periodActual: return .white
        case .fertile, .ovulation: return Palette.ovulation
        case .periodPredicted: return Palette.menstruation
        case .pms: return Palette.pms
        case .none: return Palette.ink
        }
    }

    // MARK: Legend
    private var legend: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                legendRow(color: Palette.menstruation, text: L.t("legend_period", lang))
                legendRow(color: Palette.menstruation.opacity(0.30), text: L.t("legend_predicted", lang))
                legendRow(color: Palette.fertile.opacity(0.35), text: L.t("legend_fertile", lang))
                legendRow(color: Palette.ovulation.opacity(0.5), text: L.t("legend_ovulation", lang), symbol: "sparkles")
                legendRow(color: Palette.pms.opacity(0.35), text: L.t("legend_pms", lang))
            }
        }
    }

    private func legendRow(color: Color, text: String, symbol: String? = nil) -> some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 16, height: 16)
                .overlay {
                    if let symbol {
                        Image(systemName: symbol).font(.system(size: 8)).foregroundStyle(.white)
                    }
                }
            Text(text).font(.subheadline).foregroundStyle(Palette.ink)
            Spacer()
        }
    }

    // MARK: Logic
    private func marker(for date: Date) -> Marker {
        guard let profile else { return .none }
        let d = CycleEngine.startOfDay(date)
        let periodLen = max(1, profile.periodLength)

        // Actual logged periods.
        for e in profile.entries ?? [] {
            let start = CycleEngine.startOfDay(e.startDate)
            let end = e.endDate.map(CycleEngine.startOfDay) ?? CycleEngine.addingDays(periodLen - 1, to: start)
            if d >= start && d <= end { return .periodActual }
        }

        // Predicted markers anchored to lastStart + k * averageCycle.
        guard let p = profile.prediction() else { return .none }
        let avg = p.averageCycleLength
        guard avg > 0 else { return .none }
        let kEst = CycleEngine.days(from: p.lastPeriodStart, to: d) / max(1, avg)
        let lower = max(1, kEst - 1)
        let upper = kEst + 2
        guard upper >= lower else { return .none }
        for k in lower...upper {
            let start = CycleEngine.addingDays(k * avg, to: p.lastPeriodStart)
            // Predicted period block
            if d >= start && d <= CycleEngine.addingDays(periodLen - 1, to: start) { return .periodPredicted }
            // Ovulation / fertile window for this predicted cycle
            let ov = CycleEngine.addingDays(-p.lutealLength, to: start)
            if d == ov { return .ovulation }
            if d >= CycleEngine.addingDays(-5, to: ov) && d <= CycleEngine.addingDays(1, to: ov) { return .fertile }
            // Premenstrual window: the days right before this predicted period.
            if d >= CycleEngine.addingDays(-CycleEngine.pmsWindow, to: start) && d < start { return .pms }
        }
        return .none
    }

    private func existingEntry(on date: Date) -> PeriodEntry? {
        let d = CycleEngine.startOfDay(date)
        return (profile?.entries ?? []).first { CycleEngine.startOfDay($0.startDate) == d }
    }

    private func shift(_ months: Int) {
        if let d = cal.date(byAdding: .month, value: months, to: anchor) { anchor = d }
    }

    private func monthDays() -> [Date?] {
        let comps = cal.dateComponents([.year, .month], from: anchor)
        guard let monthStart = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: monthStart) else { return [] }
        let firstWeekday = cal.component(.weekday, from: monthStart)
        let leading = (firstWeekday - cal.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: monthStart) { cells.append(d) }
        }
        return cells
    }

    private func orderedWeekdaySymbols() -> [String] {
        let symbols = cal.veryShortStandaloneWeekdaySymbols
        let start = cal.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }
}
