import SwiftUI
import SwiftData

@main
struct CyclesApp: App {
    let container: ModelContainer

    init() {
        // 1. Language: honour -demoLang, otherwise seed the system default once.
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "-demoLang"), i + 1 < args.count {
            UserDefaults.standard.set(args[i + 1], forKey: AppLanguage.storageKey)
        } else if UserDefaults.standard.string(forKey: AppLanguage.storageKey) == nil {
            UserDefaults.standard.set(AppLanguage.systemDefault.rawValue, forKey: AppLanguage.storageKey)
        }

        // 2. Persistence: try CloudKit, fall back to local, then in-memory.
        container = PersistenceController.make()

        // 3. Optional deterministic demo data for screenshots.
        if args.contains("-demoSeed") {
            PersistenceController.seedDemo(in: container)
        }

        // 4. Ask for notification permission (unless suppressed for clean screenshots).
        if !args.contains("-skipNotifPrompt") {
            NotificationManager.shared.requestAuthorization()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Palette.rose)
        }
        .modelContainer(container)
    }
}

/// Builds the SwiftData container, degrading gracefully when CloudKit isn't available.
enum PersistenceController {
    static let schema = Schema([Profile.self, PeriodEntry.self, DayLog.self])

    static func make() -> ModelContainer {
        // Preferred: CloudKit-backed automatic sync.
        let cloud = ModelConfiguration("Cycles", schema: schema, cloudKitDatabase: .automatic)
        if let c = try? ModelContainer(for: schema, configurations: [cloud]) { return c }

        // Fallback: local-only on disk (no entitlement / no iCloud account).
        let local = ModelConfiguration("CyclesLocal", schema: schema, cloudKitDatabase: .none)
        if let c = try? ModelContainer(for: schema, configurations: [local]) { return c }

        // Last resort: in-memory so the app still launches.
        let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [mem])
    }

    @MainActor
    static func seedDemo(in container: ModelContainer) {
        let ctx = container.mainContext
        let existing = (try? ctx.fetch(FetchDescriptor<Profile>())) ?? []
        guard existing.isEmpty else { return }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        func make(_ name: String, hex: String, order: Int, lastStartOffset: Int, cycle: Int) -> Profile {
            let p = Profile(name: name, colorHex: hex, cycleLength: cycle, periodLength: 5, order: order)
            ctx.insert(p)
            // 8 cycles back, with realistic month-to-month variation (jitter[0]=0 keeps the
            // most recent cycle exact so the home prediction stays stable).
            let jitter = [0, 2, -1, 3, -2, 1, -1, 2]
            var offset = lastStartOffset
            for i in 0..<8 {
                let start = cal.date(byAdding: .day, value: -offset, to: today)!
                ctx.insert(PeriodEntry(startDate: start, profile: p))
                offset += cycle + jitter[i % jitter.count]
            }
            return p
        }

        let lea = make("Léa", hex: "#F2738F", order: 0, lastStartOffset: 9, cycle: 28)
        lea.birthDate = cal.date(from: DateComponents(year: 1994, month: 3, day: 12))
        lea.childrenCount = 2
        let sofia = make("Sofia", hex: "#5CBDB0", order: 1, lastStartOffset: 2, cycle: 30)
        sofia.birthDate = cal.date(from: DateComponents(year: 1990, month: 9, day: 5))
        sofia.childrenCount = 1

        // Demo journal entries for Léa over the last ~6 weeks so the charts show data.
        let starts = lea.startDates
        let moodPattern = [4, 4, 3, 3, 2, 3, 4, 5, 5, 4, 3, 3, 2, 2, 3, 4, 4, 5, 4, 3, 3, 2, 3, 4, 5, 5, 4, 3]
        func flow(_ day: Date) -> Int {
            for s in starts {
                let off = cal.dateComponents([.day], from: cal.startOfDay(for: s), to: day).day ?? -99
                if off == 0 || off == 1 { return 3 }
                if off == 2 { return 2 }
                if off == 3 || off == 4 { return 1 }
            }
            return 0
        }
        for i in 0..<42 {
            guard let d = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            let log = DayLog(date: d, profile: lea)
            log.flowRaw = flow(d)
            log.moodRaw = moodPattern[i % moodPattern.count]
            var symps: [String] = []
            if log.flowRaw >= 2 { symps.append(Symptom.cramps.rawValue); symps.append(Symptom.fatigue.rawValue) }
            if i % 7 == 0 { symps.append(Symptom.headache.rawValue) }
            if i % 5 == 0 { symps.append(Symptom.bloating.rawValue) }
            if log.moodRaw <= 2 { symps.append(Symptom.moodSwings.rawValue) }
            log.symptomsRaw = Array(Set(symps))
            if !log.isEmpty { ctx.insert(log) }
        }
        try? ctx.save()

        UserDefaults.standard.set(lea.id.uuidString, forKey: "selectedProfileID")
        UserDefaults.standard.set(true, forKey: "onboarded")
    }
}

/// Decides between onboarding and the main tabs, and keeps the widget snapshot
/// and notifications in sync with the data.
struct RootView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Profile.order) private var profiles: [Profile]
    @AppStorage("selectedProfileID") private var selectedID = ""
    @AppStorage("onboarded") private var onboarded = false
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.systemDefault.rawValue
    @Environment(\.scenePhase) private var scenePhase

    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

    private var selectedProfile: Profile? {
        profiles.first { $0.id.uuidString == selectedID } ?? profiles.first
    }

    /// Signature that changes whenever data relevant to predictions changes.
    private var digest: String {
        profiles.map { p in
            "\(p.id.uuidString)|\(p.startDates.count)|\(p.startDates.last?.timeIntervalSince1970 ?? 0)|\(p.cycleLength)|\(p.periodLength)"
        }.joined(separator: ";") + "#\(selectedID)#\(languageRaw)"
    }

    var body: some View {
        Group {
            if CommandLine.arguments.contains("-widgetGallery") {
                WidgetGalleryView()
            } else if profiles.isEmpty && !onboarded {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .appLock()
        .onAppear(perform: updateSideEffects)
        .onChange(of: digest) { _, _ in updateSideEffects() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { updateSideEffects() }
        }
    }

    /// Refresh the widget snapshot and (re)schedule notifications.
    private func updateSideEffects() {
        // Make sure there's always a valid selection.
        if selectedProfile == nil, let first = profiles.first {
            selectedID = first.id.uuidString
        }
        if let prof = selectedProfile {
            SharedStore.save(prof.snapshot(lang: lang))
        } else {
            SharedStore.clear()
        }
        NotificationManager.shared.reschedule(profiles: profiles, lang: lang)
    }
}

struct MainTabView: View {
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.systemDefault.rawValue
    @State private var tab: Int
    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

    init() {
        // Debug: -startTab home|calendar|insights|settings selects the initial tab for screenshots.
        let map = ["home": 0, "calendar": 1, "insights": 2, "settings": 3]
        let initial = launchArgValue("-startTab").flatMap { map[$0] } ?? 0
        _tab = State(initialValue: initial)
    }

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tabItem { Label(L.t("tab_home", lang), systemImage: "heart.circle.fill") }
                .tag(0)
            CalendarView()
                .tabItem { Label(L.t("tab_calendar", lang), systemImage: "calendar") }
                .tag(1)
            InsightsView()
                .tabItem { Label(L.t("tab_insights", lang), systemImage: "chart.line.uptrend.xyaxis") }
                .tag(2)
            SettingsView()
                .tabItem { Label(L.t("tab_settings", lang), systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(Palette.rose)
    }
}

/// Reads the value following a launch flag (e.g. -startTab calendar).
func launchArgValue(_ name: String) -> String? {
    let a = CommandLine.arguments
    guard let i = a.firstIndex(of: name), i + 1 < a.count else { return nil }
    return a[i + 1]
}

/// In-app preview of the home/lock-screen widgets (debug: -widgetGallery).
struct WidgetGalleryView: View {
    @Query(sort: \Profile.order) private var profiles: [Profile]
    @AppStorage("selectedProfileID") private var selectedID = ""
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.systemDefault.rawValue
    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }
    private var snap: CycleSnapshot {
        let p = profiles.first { $0.id.uuidString == selectedID } ?? profiles.first
        return p?.snapshot(lang: lang) ?? .empty
    }

    var body: some View {
        ZStack {
            CyclesBackground()
            ScrollView {
                VStack(spacing: 24) {
                    Text("Widgets").font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(Palette.ink).padding(.top, 30)
                    tile(width: 170, height: 170) { CyclesWidgetContent(family: .systemSmall, snapshot: snap) }
                    tile(width: 360, height: 170) { CyclesWidgetContent(family: .systemMedium, snapshot: snap) }
                }
                .padding()
            }
        }
    }

    private func tile<V: View>(width: CGFloat, height: CGFloat, @ViewBuilder _ content: () -> V) -> some View {
        content()
            .frame(width: width, height: height)
            .background(RoundedRectangle(cornerRadius: 22).fill(.white.opacity(0.5)))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: Palette.rose.opacity(0.2), radius: 8, y: 3)
    }
}
