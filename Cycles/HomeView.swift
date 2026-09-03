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
    @State private var editingProfile: Profile?
    @State private var confirmEndPregnancy = false

    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }
    private var profile: Profile? {
        profiles.first { $0.id.uuidString == selectedID } ?? profiles.first
    }
    private var mode: TrackingMode { profile?.mode ?? .tracking }

    var body: some View {
        ZStack {
            CyclesBackground(phase: profile?.prediction()?.phase)
            ScrollView {
                VStack(spacing: 22) {
                    profileBar
                    if let profile, let preg = profile.pregnancy() {
                        pregnancyHero(preg)
                        pregnancyChip(preg)
                        pregnancyInfoRow(preg)
                        journalButton
                        endPregnancyButton
                    } else if let profile, let p = profile.prediction() {
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
        .sheet(item: $editingProfile) { ProfileEditorSheet(profile: $0) }
        .confirmationDialog(L.t("preg_end_q", lang),
                            isPresented: $confirmEndPregnancy, titleVisibility: .visible) {
            Button(L.t("preg_end", lang), role: .destructive) { endPregnancy() }
            Button(L.t("cancel", lang), role: .cancel) {}
        } message: {
            Text(L.t("preg_end_msg", lang))
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
                if let profile {
                    Button {
                        editingProfile = profile
                    } label: { Label(L.t("profile_edit", lang), systemImage: "pencil") }
                }
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

    /// The centre of the ring must never be ambiguous: every state says explicitly
    /// whether the period already started (X days ago), is late, or is still to come.
    @ViewBuilder
    private func heroCenter(_ p: CyclePrediction) -> some View {
        if p.isMenstruating {
            let since = max(0, p.dayOfCycle - 1)     // 0 = started today
            if since == 0 {
                heroSymbol(caption: L.t("hero_started_today", lang),
                           color: Palette.menstruation, symbol: "drop.fill")
            } else {
                heroText(big: "\(since)", unit: dayUnit(since),
                         caption: L.t("hero_since_started", lang), color: Palette.menstruation)
            }
        } else if p.isPeriodLate {
            heroText(big: "\(p.lateDays)", unit: lateUnit(p.lateDays),
                     caption: L.t(mode == .conceiving ? "conceive_late_hint" : "hero_late_caption", lang),
                     color: Palette.menstruation)
        } else if mode == .conceiving {
            conceivingCenter(p)
        } else {
            let ev = p.nearestEvent
            let color = Palette.color(for: ev.kind)
            if ev.days == 0 {
                heroSymbol(caption: L.t(ev.kind == .period ? "today_period" : "today_ovulation", lang),
                           color: color, symbol: ev.kind == .period ? "drop.fill" : "sparkles")
            } else {
                heroText(big: "\(ev.days)", unit: dayUnit(ev.days),
                         caption: L.t(ev.kind == .period ? "hero_until_period" : "hero_until_ovulation", lang),
                         color: color)
            }
        }
    }

    /// Trying to conceive: the fertile window is what matters most.
    @ViewBuilder
    private func conceivingCenter(_ p: CyclePrediction) -> some View {
        if p.isFertile {
            heroSymbol(caption: L.t("conceive_fertile_now", lang),
                       color: Palette.fertile, symbol: "sparkles")
        } else if p.daysUntilFertile <= p.daysUntilPeriod {
            heroText(big: "\(p.daysUntilFertile)", unit: dayUnit(p.daysUntilFertile),
                     caption: L.t("hero_until_fertile", lang), color: Palette.fertile)
        } else {
            heroText(big: "\(p.daysUntilPeriod)", unit: dayUnit(p.daysUntilPeriod),
                     caption: L.t("hero_until_period", lang), color: Palette.menstruation)
        }
    }

    private func dayUnit(_ n: Int) -> String { L.t(n == 1 ? "unit_day" : "unit_days", lang) }
    private func lateUnit(_ n: Int) -> String { L.t(n == 1 ? "hero_late_day" : "hero_late_days", lang) }

    private func heroText(big: String, unit: String, caption: String, color: Color) -> some View {
        VStack(spacing: 0) {
            Text(big)
                .font(.system(size: 74, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(unit)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Palette.sub)
            Text(caption)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(Palette.ink.opacity(0.72))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 3)
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
            if mode == .conceiving {
                StatTile(icon: "sparkles",
                         title: L.t(p.isFertile ? "fertile_until" : "fertile_window", lang),
                         value: cyclesDate(p.isFertile ? p.fertileEnd : p.upcomingFertileStart, lang: lang),
                         tint: Palette.fertile)
                StatTile(icon: "drop.fill",
                         title: L.t("next_period", lang),
                         value: cyclesDate(p.upcomingPeriod, lang: lang),
                         tint: Palette.menstruation)
            } else {
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
    }

    // MARK: Pregnancy mode
    private func pregnancyHero(_ preg: PregnancyProgress) -> some View {
        ProgressRing(progress: preg.progress,
                     colors: [Palette.follicular.opacity(0.7), Palette.rose, Palette.roseDeep]) {
            VStack(spacing: 0) {
                Text("\(preg.weeks)")
                    .font(.system(size: 74, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.rose)
                    .minimumScaleFactor(0.5).lineLimit(1)
                Text(L.t(preg.weeks == 1 ? "unit_week" : "unit_weeks", lang))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.sub)
                Text(preg.daysInWeek == 0
                     ? L.t("preg_caption", lang)
                     : String(format: L.t("preg_caption_days_fmt", lang), preg.daysInWeek))
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.ink.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 3)
            }
        }
        .frame(width: 260, height: 260)
        .padding(.vertical, 6)
    }

    private func pregnancyChip(_ preg: PregnancyProgress) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "figure.child.circle")
            Text(String(format: L.t("preg_trimester_fmt", lang), preg.trimester))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
        }
        .foregroundStyle(Palette.rose)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Capsule().fill(Palette.rose.opacity(0.16)))
    }

    /// One tap out of pregnancy mode — nothing is deleted, cycle tracking simply resumes.
    private var endPregnancyButton: some View {
        Button {
            confirmEndPregnancy = true
        } label: {
            Label(L.t("preg_end", lang), systemImage: "arrow.uturn.backward")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Palette.sub)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
    }

    private func endPregnancy() {
        guard let profile else { return }
        profile.mode = .tracking
        profile.pregnancyStart = nil
        try? ctx.save()
    }

    private func pregnancyInfoRow(_ preg: PregnancyProgress) -> some View {
        HStack(spacing: 12) {
            StatTile(icon: "calendar",
                     title: L.t("preg_due_date", lang),
                     value: cyclesDate(preg.dueDate, lang: lang),
                     tint: Palette.rose)
            StatTile(icon: "hourglass",
                     title: L.t("preg_days_left", lang),
                     value: "\(preg.daysRemaining)",
                     tint: Palette.follicular)
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
