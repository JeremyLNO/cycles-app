import SwiftUI
import SwiftData
import Charts

/// "Insights" tab: journal shortcut, cycle stats and history charts (Swift Charts).
struct InsightsView: View {
    @Query(sort: \Profile.order) private var profiles: [Profile]
    @AppStorage("selectedProfileID") private var selectedID = ""
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.systemDefault.rawValue

    @State private var showJournal = false

    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }
    private var profile: Profile? {
        profiles.first { $0.id.uuidString == selectedID } ?? profiles.first
    }

    var body: some View {
        ZStack {
            CyclesBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(L.t("insights_title", lang))
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(Palette.ink)
                        .padding(.top, 6)

                    if let profile {
                        journalCard(profile)
                        statsCard(profile)
                        cycleChart(profile)
                        moodChart(profile)
                        symptomChart(profile)
                    } else {
                        Text(L.t("no_data_body", lang))
                            .foregroundStyle(Palette.sub)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showJournal) {
            if let profile { DayLogSheet(profile: profile, date: Date()) }
        }
        .onAppear {
            if CommandLine.arguments.contains("-openJournal") { showJournal = true }
        }
    }

    // MARK: Today's journal shortcut
    private func journalCard(_ profile: Profile) -> some View {
        Button { showJournal = true } label: {
            GlassCard {
                HStack(spacing: 14) {
                    Image(systemName: "square.and.pencil")
                        .font(.title2).foregroundStyle(Palette.rose)
                        .frame(width: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L.t("journal_today", lang))
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Palette.ink)
                        Text(todaySummary(profile))
                            .font(.caption).foregroundStyle(Palette.sub)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Palette.sub)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func todaySummary(_ profile: Profile) -> String {
        guard let log = profile.dayLog(on: Date()), !log.isEmpty else {
            return L.t("journal_empty_today", lang)
        }
        var parts: [String] = []
        if let m = log.mood { parts.append(L.t(m.key, lang)) }
        if log.flow != .none { parts.append(L.t(log.flow.key, lang)) }
        if !log.symptoms.isEmpty { parts.append(L.days(log.symptoms.count, lang)) }
        return parts.isEmpty ? L.t("journal_empty_today", lang) : parts.joined(separator: " · ")
    }

    // MARK: Stats
    private func statsCard(_ profile: Profile) -> some View {
        let pts = cyclePoints(profile)
        let lengths = pts.map(\.length)
        let avg = lengths.isEmpty ? profile.cycleLength : Int((Double(lengths.reduce(0, +)) / Double(lengths.count)).rounded())
        return GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label(L.t("insights_summary", lang), systemImage: "chart.bar.fill")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Palette.ink)
                HStack(spacing: 12) {
                    stat(value: "\(avg)", label: L.t("stats_avg_cycle", lang), tint: Palette.rose)
                    stat(value: lengths.isEmpty ? "–" : "\(lengths.min()!)–\(lengths.max()!)",
                         label: L.t("stats_range", lang), tint: Palette.follicular)
                    stat(value: "\(avgPeriodLength(profile))", label: L.t("stats_avg_period", lang), tint: Palette.menstruation)
                }
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill").font(.caption)
                    Text(regularityLabel(lengths))
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(Palette.ovulation)
            }
        }
    }

    private func stat(value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label)
                .font(.caption2).foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Cycle length chart
    @ViewBuilder
    private func cycleChart(_ profile: Profile) -> some View {
        let pts = cyclePoints(profile)
        chartCard(title: L.t("chart_cycle_length", lang), icon: "calendar") {
            if pts.count < 2 {
                emptyChart
            } else {
                let lengths = pts.map(\.length)
                let avg = Double(lengths.reduce(0, +)) / Double(lengths.count)
                Chart {
                    ForEach(pts) { pt in
                        LineMark(x: .value("Date", pt.date),
                                 y: .value("Days", pt.length))
                            .foregroundStyle(Palette.rose)
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("Date", pt.date),
                                  y: .value("Days", pt.length))
                            .foregroundStyle(Palette.rose)
                    }
                    RuleMark(y: .value("Average", avg))
                        .foregroundStyle(Palette.sub.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .annotation(position: .top, alignment: .leading) {
                            Text(L.t("chart_average", lang) + " \(Int(avg.rounded()))")
                                .font(.caption2).foregroundStyle(Palette.sub)
                        }
                }
                .chartYScale(domain: max(0, (lengths.min() ?? 20) - 3)...((lengths.max() ?? 30) + 3))
                .chartXAxis { AxisMarks(values: .stride(by: .month)) { _ in
                    AxisGridLine(); AxisValueLabel(format: .dateTime.month(.abbreviated))
                } }
                .frame(height: 170)
            }
        }
    }

    // MARK: Mood chart
    @ViewBuilder
    private func moodChart(_ profile: Profile) -> some View {
        let pts = moodPoints(profile)
        if pts.count >= 2 {
            chartCard(title: L.t("chart_mood", lang), icon: "face.smiling") {
                Chart(pts) { pt in
                    LineMark(x: .value("Date", pt.date), y: .value("Mood", pt.value))
                        .foregroundStyle(Palette.follicular)
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Date", pt.date), y: .value("Mood", pt.value))
                        .foregroundStyle(Palette.follicular)
                }
                .chartYScale(domain: 1...5)
                .chartYAxis { AxisMarks(values: [1, 3, 5]) }
                .frame(height: 150)
            }
        }
    }

    // MARK: Symptom frequency chart
    @ViewBuilder
    private func symptomChart(_ profile: Profile) -> some View {
        let counts = symptomCounts(profile)
        if !counts.isEmpty {
            chartCard(title: L.t("chart_symptoms", lang), icon: "list.bullet.clipboard") {
                Chart(counts) { c in
                    BarMark(x: .value("Count", c.count),
                            y: .value("Symptom", L.t(c.symptom.key, lang)))
                        .foregroundStyle(Palette.rose.gradient)
                        .cornerRadius(5)
                }
                .frame(height: CGFloat(counts.count) * 34 + 20)
            }
        }
    }

    // MARK: Chart card wrapper
    private func chartCard<V: View>(title: String, icon: String, @ViewBuilder _ content: @escaping () -> V) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label(title, systemImage: icon)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Palette.ink)
                content()
            }
        }
    }

    private var emptyChart: some View {
        HStack {
            Spacer()
            Text(L.t("insights_need_data", lang))
                .font(.caption).foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(height: 80)
    }

    // MARK: Data

    private struct CyclePoint: Identifiable { let id = UUID(); let date: Date; let length: Int }
    private struct MoodPoint: Identifiable { let id = UUID(); let date: Date; let value: Int }
    private struct SymptomCount: Identifiable { let id = UUID(); let symptom: Symptom; let count: Int }

    private func cyclePoints(_ profile: Profile) -> [CyclePoint] {
        let s = profile.startDates
        guard s.count >= 2 else { return [] }
        var pts: [CyclePoint] = []
        for i in 1..<s.count {
            let len = CycleEngine.days(from: s[i - 1], to: s[i])
            if len >= 15 && len <= 60 { pts.append(CyclePoint(date: s[i], length: len)) }
        }
        return Array(pts.suffix(10))
    }

    private func moodPoints(_ profile: Profile) -> [MoodPoint] {
        let cutoff = CycleEngine.addingDays(-45, to: CycleEngine.startOfDay(Date()))
        return (profile.dayLogs ?? [])
            .filter { $0.moodRaw > 0 && $0.date >= cutoff }
            .sorted { $0.date < $1.date }
            .map { MoodPoint(date: CycleEngine.startOfDay($0.date), value: $0.moodRaw) }
    }

    private func symptomCounts(_ profile: Profile) -> [SymptomCount] {
        let cutoff = CycleEngine.addingDays(-60, to: CycleEngine.startOfDay(Date()))
        var tally: [Symptom: Int] = [:]
        for log in profile.dayLogs ?? [] where log.date >= cutoff {
            for s in log.symptoms { tally[s, default: 0] += 1 }
        }
        return tally.map { SymptomCount(symptom: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(6)
            .map { $0 }
    }

    /// Average bleeding-run length from flow logs; falls back to the configured period length.
    private func avgPeriodLength(_ profile: Profile) -> Int {
        let flowDays = (profile.dayLogs ?? [])
            .filter { $0.flowRaw > 0 }
            .map { CycleEngine.startOfDay($0.date) }
            .sorted()
        guard !flowDays.isEmpty else { return profile.periodLength }
        var runs: [Int] = []
        var run = 1
        for i in 1..<max(1, flowDays.count) {
            if CycleEngine.days(from: flowDays[i - 1], to: flowDays[i]) == 1 {
                run += 1
            } else {
                runs.append(run); run = 1
            }
        }
        runs.append(run)
        let avg = Double(runs.reduce(0, +)) / Double(runs.count)
        return max(1, Int(avg.rounded()))
    }

    private func regularityLabel(_ lengths: [Int]) -> String {
        guard lengths.count >= 2, let mn = lengths.min(), let mx = lengths.max() else {
            return L.t("stats_reg_unknown", lang)
        }
        let spread = mx - mn
        if spread <= 3 { return L.t("stats_reg_high", lang) }
        if spread <= 7 { return L.t("stats_reg_med", lang) }
        return L.t("stats_reg_low", lang)
    }
}
