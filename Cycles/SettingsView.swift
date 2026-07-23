import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \Profile.order) private var profiles: [Profile]
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.systemDefault.rawValue

    @AppStorage(NotificationManager.Keys.periodEnabled) private var periodNotif = true
    @AppStorage(NotificationManager.Keys.ovulationEnabled) private var ovulationNotif = true
    @AppStorage(NotificationManager.Keys.hour) private var notifHour = 9
    @AppStorage(NotificationManager.Keys.minute) private var notifMinute = 0
    @AppStorage("lock.enabled") private var lockEnabled = false
    @AppStorage("default.cycleLength") private var defaultCycle = CycleEngine.defaultCycle

    @EnvironmentObject private var account: AccountManager
    @State private var showAccountSheet = false
    @State private var showCommitment = false

    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

    private var iCloudOn: Bool { FileManager.default.ubiquityIdentityToken != nil }
    private var privacyURL: URL { URL(string: "https://www.crazybeelabs.com/privacy-policy/")! }
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// "Support & ideas" page. Change the URL here if needed.
    private var supportURL: URL {
        URL(string: "https://crazybeelabs.com/support/") ?? URL(string: "https://crazybeelabs.com")!
    }

    /// Crazy Bee Labs website (footer).
    private var siteURL: URL {
        URL(string: "https://crazybeelabs.com/") ?? URL(string: "https://crazybeelabs.com")!
    }

    private var timeBinding: Binding<Date> {
        Binding {
            Calendar.current.date(from: DateComponents(hour: notifHour, minute: notifMinute)) ?? Date()
        } set: { newVal in
            let c = Calendar.current.dateComponents([.hour, .minute], from: newVal)
            notifHour = c.hour ?? 9
            notifMinute = c.minute ?? 0
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Account & Premium
                Section(L.t("account_section", lang)) {
                    NavigationLink {
                        AccountView()
                    } label: {
                        Label(account.isSignedIn ? (account.displayName.isEmpty ? L.t("account_apple_user", lang) : account.displayName) : L.t("account_signin", lang),
                              systemImage: "person.crop.circle.fill")
                    }
                }

                // People
                Section(L.t("settings_people", lang)) {
                    NavigationLink {
                        ProfilesView()
                    } label: {
                        Label(L.t("profiles_title", lang), systemImage: "person.2.fill")
                    }
                }

                // Language
                Section(L.t("settings_language", lang)) {
                    Picker(L.t("settings_language", lang), selection: $languageRaw) {
                        ForEach(AppLanguage.allCases) { l in
                            Text(l.name).tag(l.rawValue)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                // Notifications
                Section(L.t("settings_notifications", lang)) {
                    Toggle(L.t("notif_period", lang), isOn: $periodNotif)
                    Toggle(L.t("notif_ovulation", lang), isOn: $ovulationNotif)
                    DatePicker(L.t("notif_time", lang), selection: timeBinding, displayedComponents: .hourAndMinute)
                }

                // Default cycle
                Section(L.t("settings_cycle", lang)) {
                    Stepper(value: $defaultCycle, in: CycleEngine.minCycle...CycleEngine.maxCycle) {
                        HStack {
                            Text(L.t("profile_cycle_len", lang))
                            Spacer()
                            Text(L.days(defaultCycle, lang)).foregroundStyle(Palette.sub)
                        }
                    }
                }

                // Privacy
                Section(L.t("settings_privacy", lang)) {
                    Toggle(L.t("settings_lock", lang), isOn: $lockEnabled)
                }

                // Sync
                Section(L.t("settings_sync", lang)) {
                    HStack {
                        Label(L.t("settings_sync_icloud", lang), systemImage: "icloud.fill")
                        Spacer()
                        Image(systemName: iCloudOn ? "checkmark.circle.fill" : "exclamationmark.circle")
                            .foregroundStyle(iCloudOn ? .green : Palette.sub)
                    }
                    Text(iCloudOn ? L.t("sync_status_on", lang) : L.t("sync_status_off", lang))
                        .font(.caption).foregroundStyle(Palette.sub)
                }

                // About
                Section(L.t("settings_about", lang)) {
                    Link(destination: supportURL) {
                        Label(L.t("settings_support", lang), systemImage: "lightbulb.fill")
                            .foregroundStyle(Palette.rose)
                    }
                    Link(destination: privacyURL) {
                        Label(L.t("privacy_policy", lang), systemImage: "hand.raised.fill")
                            .foregroundStyle(Palette.rose)
                    }
                    Button {
                        showCommitment = true
                    } label: {
                        Label(L.t("free_link", lang), systemImage: "gift.fill")
                            .foregroundStyle(Palette.rose)
                    }
                    HStack {
                        Text(L.t("settings_version", lang))
                        Spacer()
                        Text(appVersion).foregroundStyle(Palette.sub)
                    }
                    Text(L.t("disclaimer_body", lang))
                        .font(.caption).foregroundStyle(Palette.sub)
                }

                // Crazy Bee Labs footer
                Section {
                    Link(destination: siteURL) {
                        VStack(spacing: 6) {
                            Image("CrazyBeeLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 30)
                            Text(L.t("made_by", lang))
                                .font(.caption2)
                                .foregroundStyle(Palette.sub)
                            Text("Crazy Bee Labs")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(Palette.ink)
                            Text("crazybeelabs.com")
                                .font(.caption2)
                                .foregroundStyle(Palette.rose)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(L.t("tab_settings", lang))
            .scrollContentBackground(.hidden)
            .background(CyclesBackground())
            .sheet(isPresented: $showAccountSheet) {
                NavigationStack { AccountView() }.environmentObject(account)
            }
            .sheet(isPresented: $showCommitment) {
                CommitmentView()
            }
            .onAppear {
                if CommandLine.arguments.contains("-openAccount") { showAccountSheet = true }
            }
            .onChange(of: periodNotif) { _, on in if on { NotificationManager.shared.requestAuthorization() }; rescheduleNotifs() }
            .onChange(of: ovulationNotif) { _, on in if on { NotificationManager.shared.requestAuthorization() }; rescheduleNotifs() }
            .onChange(of: notifHour) { _, _ in rescheduleNotifs() }
            .onChange(of: notifMinute) { _, _ in rescheduleNotifs() }
        }
    }

    private func rescheduleNotifs() {
        NotificationManager.shared.reschedule(profiles: profiles, lang: lang)
    }
}
