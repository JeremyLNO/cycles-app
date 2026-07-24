import SwiftUI
import SwiftData
import UIKit

/// The main screen: shows, front and centre, the number of days until the nearest
/// event (period or ovulation) for the selected profile.
struct HomeView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Profile.order) private var profiles: [Profile]
    @AppStorage("selectedProfileID") private var selectedID = ""
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.systemDefault.rawValue

    @State private var showAddProfile = false
    @State private var showLog = false
    @State private var showJournal = false

    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }
    private var profile: Profile? {
        profiles.first { $0.id.uuidString == selectedID } ?? profiles.first
    }

    var body: some View {
        ZStack {
            CyclesBackground(phase: profile?.prediction()?.phase)
            ScrollView {
                VStack(spacing: 22) {
                    profileBar
                    if let profile, let p = profile.prediction() {
                        hero(p)
                        PhaseChip(phase: p.phase, lang: lang)
                        infoRow(p)
                        tipCard(p)
                        logButton
                        journalButton
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showAddProfile) {
            ProfileEditorSheet(profile: nil)
        }
        .sheet(isPresented: $showLog) {
            if let profile { LogPeriodSheet(profile: profile, date: Date()) }
        }
        .sheet(isPresented: $showJournal) {
            if let profile { DayLogSheet(profile: profile, date: Date()) }
        }
    }

    // MARK: Profile switcher
    private var profileBar: some View {
        HStack {
            Menu {
                ForEach(profiles) { p in
                    Button {
                        selectedID = p.id.uuidString
                    } label: {
                        Label(p.name.isEmpty ? L.t("profile_new", lang) : p.name,
                              systemImage: p.id.uuidString == (profile?.id.uuidString ?? "") ? "checkmark" : "")
                    }
                }
                Divider()
                Button {
                    showAddProfile = true
                } label: { Label(L.t("profile_add", lang), systemImage: "plus") }
            } label: {
                HStack(spacing: 10) {
                    ProfileAvatar(name: profile?.name ?? "", colorHex: profile?.colorHex ?? "#F2738F")
                    Text(profile?.name.isEmpty == false ? profile!.name : "Period tracker made easy")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(Palette.ink)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Palette.sub)
                }
            }
            Spacer()
        }
    }

    // MARK: Hero ring
    private func hero(_ p: CyclePrediction) -> some View {
        ProgressRing(progress: CycleEngine.cycleProgress(p),
                     colors: Palette.ring(for: p.phase)) {
            heroCenter(p)
        }
        .frame(width: 260, height: 260)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func heroCenter(_ p: CyclePrediction) -> some View {
        if p.isMenstruating {
            heroText(big: "\(p.dayOfCycle)", showUnit: false,
                     caption: L.t("period_ongoing", lang), color: Palette.menstruation)
        } else if p.isPeriodLate {
            heroText(big: "\(p.lateDays)", showUnit: true,
                     caption: L.t("phase_menstruation", lang), color: Palette.menstruation)
        } else {
            let ev = p.nearestEvent
            let color = Palette.color(for: ev.kind)
            if ev.days == 0 {
                heroSymbol(caption: L.t(ev.kind == .period ? "today_period" : "today_ovulation", lang),
                           color: color, symbol: ev.kind == .period ? "drop.fill" : "sparkles")
            } else {
                heroText(big: "\(ev.days)", showUnit: true,
                         caption: L.t(ev.kind == .period ? "before_period" : "before_ovulation", lang),
                         color: color)
            }
        }
    }

    private func heroText(big: String, showUnit: Bool, caption: String, color: Color) -> some View {
        VStack(spacing: 0) {
            Text(big)
                .font(.system(size: 78, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            if showUnit {
                Text(L.t("unit_days", lang))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.sub)
            }
            Text(caption)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
    }

    private func heroSymbol(caption: String, color: Color, symbol: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(color)
            Text(caption)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
        }
    }

    // MARK: Info row
    private func infoRow(_ p: CyclePrediction) -> some View {
        HStack(spacing: 12) {
            StatTile(icon: "drop.fill",
                     title: L.t("next_period", lang),
                     value: cyclesDate(p.upcomingPeriod, lang: lang),
                     tint: Palette.menstruation)
            StatTile(icon: "sparkles",
                     title: L.t("phase_ovulation", lang),
                     value: cyclesDate(p.upcomingOvulation, lang: lang),
                     tint: Palette.ovulation)
        }
    }

    // MARK: Health tip (phase-aware, women-focused wellness)
    @ViewBuilder
    private func tipCard(_ p: CyclePrediction) -> some View {
        if let tip = HealthTips.tip(for: p.phase, day: p.dayOfCycle, lang) {
            GlassCard {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.title3)
                        .foregroundStyle(Palette.color(for: p.phase))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L.t("tips_label", lang))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.sub)
                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: Quick log
    private var logButton: some View {
        Button {
            quickLogToday()
        } label: {
            Label(L.t("log_period_today", lang), systemImage: "plus.circle.fill")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    Capsule().fill(LinearGradient(colors: [Palette.rose, Palette.roseDeep],
                                                  startPoint: .leading, endPoint: .trailing))
                )
                .shadow(color: Palette.rose.opacity(0.4), radius: 10, y: 5)
        }
        .padding(.top, 4)
    }

    // MARK: Journal shortcut
    private var journalButton: some View {
        Button {
            showJournal = true
        } label: {
            Label(L.t("journal_add", lang), systemImage: "square.and.pencil")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Palette.rose)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    Capsule().fill(Palette.card)
                        .overlay(Capsule().stroke(Palette.rose.opacity(0.4), lineWidth: 1))
                )
        }
    }

    // MARK: Empty state
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "drop.fill").font(.system(size: 56)).foregroundStyle(Palette.rose)
            Text(L.t("no_data_title", lang))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Palette.ink)
            Text(L.t("no_data_body", lang))
                .font(.body)
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                if profile == nil { showAddProfile = true } else { showLog = true }
            } label: {
                Label(L.t("log_period_today", lang), systemImage: "plus.circle.fill")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24).padding(.vertical, 13)
                    .background(Capsule().fill(Palette.rose))
            }
        }
        .padding(.top, 60)
    }

    private func quickLogToday() {
        guard let profile else { return }
        let today = CycleEngine.startOfDay(Date())
        // Avoid duplicate entry for the same day.
        if profile.startDates.contains(where: { CycleEngine.startOfDay($0) == today }) { return }
        let entry = PeriodEntry(startDate: today, profile: profile)
        ctx.insert(entry)
        try? ctx.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
