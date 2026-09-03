import SwiftUI
import SwiftData

// MARK: - Profiles management

struct ProfilesView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Profile.order) private var profiles: [Profile]
    @AppStorage("selectedProfileID") private var selectedID = ""
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.systemDefault.rawValue

    @State private var editing: Profile?
    @State private var showAdd = false

    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

    var body: some View {
        List {
            ForEach(profiles) { p in
                Button {
                    selectedID = p.id.uuidString
                    editing = p
                } label: {
                    HStack(spacing: 12) {
                        ProfileAvatar(name: p.name, colorHex: p.colorHex)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.name.isEmpty ? L.t("profile_new", lang) : p.name)
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(Palette.ink)
                            Text(String(format: L.t("avg_cycle_fmt", lang),
                                        p.prediction()?.averageCycleLength ?? p.cycleLength))
                                .font(.caption).foregroundStyle(Palette.sub)
                        }
                        Spacer()
                        if p.id.uuidString == selectedID {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.rose)
                        }
                    }
                }
            }
            .onDelete(perform: delete)

            Button {
                showAdd = true
            } label: {
                Label(L.t("profile_add", lang), systemImage: "plus.circle.fill")
                    .foregroundStyle(Palette.rose)
            }
        }
        .navigationTitle(L.t("profiles_title", lang))
        .sheet(item: $editing) { ProfileEditorSheet(profile: $0) }
        .sheet(isPresented: $showAdd) { ProfileEditorSheet(profile: nil) }
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { ctx.delete(profiles[i]) }
        try? ctx.save()
    }
}

// MARK: - Add / edit a profile

struct ProfileEditorSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedProfileID") private var selectedID = ""
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.systemDefault.rawValue

    let profile: Profile?
    @State private var name: String
    @State private var colorHex: String
    @State private var cycleLength: Int
    @State private var periodLength: Int
    @State private var hasBirthDate: Bool
    @State private var birthDate: Date
    @State private var childrenCount: Int
    @State private var mode: TrackingMode
    @State private var pregnancyStart: Date

    @Query(sort: \Profile.order) private var allProfiles: [Profile]

    init(profile: Profile?) {
        self.profile = profile
        _name = State(initialValue: profile?.name ?? "")
        _colorHex = State(initialValue: profile?.colorHex ?? Palette.profileSwatches[0])
        let fallbackCycle = UserDefaults.standard.object(forKey: "default.cycleLength") as? Int ?? CycleEngine.defaultCycle
        _cycleLength = State(initialValue: profile?.cycleLength ?? fallbackCycle)
        _periodLength = State(initialValue: profile?.periodLength ?? CycleEngine.defaultPeriod)
        _hasBirthDate = State(initialValue: profile?.birthDate != nil)
        let defaultBirth = Calendar.current.date(byAdding: .year, value: -28, to: Date()) ?? Date()
        _birthDate = State(initialValue: profile?.birthDate ?? defaultBirth)
        _childrenCount = State(initialValue: profile?.childrenCount ?? 0)
        _mode = State(initialValue: profile?.mode ?? .tracking)
        let lastPeriod = profile?.startDates.last ?? Date()
        _pregnancyStart = State(initialValue: profile?.pregnancyStart ?? lastPeriod)
    }

    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }
    private var ageString: String {
        let years = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        return String(format: L.t("years_old_fmt", lang), max(0, years))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        ProfileAvatar(name: name, colorHex: colorHex, size: 52)
                        TextField(L.t("profile_name", lang), text: $name)
                            .font(.system(.title3, design: .rounded))
                            .textInputAutocapitalization(.words)
                    }
                }
                Section(L.t("profile_color", lang)) {
                    swatches
                }
                Section {
                    Picker(L.t("profile_mode", lang), selection: $mode.animation()) {
                        ForEach(TrackingMode.allCases) { m in
                            Label(L.t(m.key, lang), systemImage: m.symbol).tag(m)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    if mode == .pregnancy {
                        DatePicker(L.t("preg_start", lang), selection: $pregnancyStart,
                                   in: ...Date(), displayedComponents: .date)
                        labelRow(L.t("preg_due_date", lang),
                                 cyclesDate(CycleEngine.pregnancy(lastPeriod: pregnancyStart).dueDate,
                                            lang: lang, template: "d MMM yyyy"))
                    }
                } footer: {
                    Text(L.t(mode.key + "_help", lang))
                }
                Section {
                    Stepper(value: $cycleLength, in: CycleEngine.minCycle...CycleEngine.maxCycle) {
                        labelRow(L.t("profile_cycle_len", lang), L.days(cycleLength, lang))
                    }
                    Stepper(value: $periodLength, in: 2...10) {
                        labelRow(L.t("profile_period_len", lang), L.days(periodLength, lang))
                    }
                }
                Section(L.t("profile_about_you", lang)) {
                    Toggle(L.t("profile_birthdate", lang), isOn: $hasBirthDate.animation())
                    if hasBirthDate {
                        DatePicker(L.t("log_date", lang), selection: $birthDate,
                                   in: ...Date(), displayedComponents: .date)
                        labelRow(L.t("profile_age", lang), ageString)
                    }
                    Stepper(value: $childrenCount, in: 0...20) {
                        labelRow(L.t("profile_children", lang), "\(childrenCount)")
                    }
                }
                if let profile {
                    Section {
                        Button(role: .destructive) {
                            ctx.delete(profile)
                            try? ctx.save()
                            dismiss()
                        } label: {
                            Label(L.t("profile_delete", lang), systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(profile == nil ? L.t("profile_new", lang) : L.t("profile_edit", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L.t("cancel", lang)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button(L.t("save", lang)) { save() }.fontWeight(.bold) }
            }
        }
    }

    private var swatches: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Palette.profileSwatches, id: \.self) { hex in
                    Circle()
                        .fill(Palette.from(hex: hex))
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(Palette.ink, lineWidth: hex == colorHex ? 3 : 0))
                        .onTapGesture { colorHex = hex }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func labelRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(Palette.ink)
            Spacer()
            Text(value).foregroundStyle(Palette.sub)
        }
    }

    private func save() {
        if let profile {
            profile.name = name
            profile.colorHex = colorHex
            profile.cycleLength = cycleLength
            profile.periodLength = periodLength
            profile.birthDate = hasBirthDate ? birthDate : nil
            profile.childrenCount = childrenCount
            profile.mode = mode
            profile.pregnancyStart = mode == .pregnancy ? pregnancyStart : nil
        } else {
            let p = Profile(name: name, colorHex: colorHex, cycleLength: cycleLength,
                            periodLength: periodLength, order: allProfiles.count)
            p.birthDate = hasBirthDate ? birthDate : nil
            p.childrenCount = childrenCount
            p.mode = mode
            p.pregnancyStart = mode == .pregnancy ? pregnancyStart : nil
            ctx.insert(p)
            selectedID = p.id.uuidString
        }
        try? ctx.save()
        dismiss()
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @Environment(\.modelContext) private var ctx
    @AppStorage("selectedProfileID") private var selectedID = ""
    @AppStorage("onboarded") private var onboarded = false
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.systemDefault.rawValue

    @State private var step = 0
    @State private var name = ""
    @State private var lastPeriod = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var cycleLength = UserDefaults.standard.object(forKey: "default.cycleLength") as? Int ?? CycleEngine.defaultCycle
    @State private var mode: TrackingMode = .tracking

    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }
    /// Pregnancy mode doesn't need the cycle-length step.
    private var lastStep: Int { mode == .pregnancy ? 4 : 5 }

    var body: some View {
        ZStack {
            CyclesBackground()
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "drop.fill").font(.system(size: 60)).foregroundStyle(Palette.rose)
                content
                Spacer()
                button
            }
            .padding(28)
            .animation(.easeInOut, value: step)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            languageStep
        case 1:
            titleBlock(L.t("onb_welcome_title", lang), L.t("onb_welcome_body", lang))
        case 2:
            VStack(spacing: 16) {
                titleBlock(L.t("onb_name_title", lang), L.t("onb_name_body", lang))
                GlassCard {
                    TextField(L.t("profile_name", lang), text: $name)
                        .font(.system(.title2, design: .rounded))
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.words)
                }
            }
        case 3:
            modeStep
        case 4:
            VStack(spacing: 16) {
                titleBlock(L.t(mode == .pregnancy ? "onb_preg_title" : "onb_last_title", lang),
                           L.t(mode == .pregnancy ? "preg_start" : "onb_last_body", lang))
                GlassCard {
                    DatePicker("", selection: $lastPeriod, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .tint(Palette.rose)
                }
                if mode == .pregnancy {
                    Text(L.t("preg_due_date", lang) + " · "
                         + cyclesDate(CycleEngine.pregnancy(lastPeriod: lastPeriod).dueDate,
                                      lang: lang, template: "d MMM yyyy"))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Palette.rose)
                }
            }
        default:
            VStack(spacing: 16) {
                titleBlock(L.t("onb_cycle_title", lang), L.t("onb_cycle_body", lang))
                GlassCard {
                    Stepper(value: $cycleLength, in: CycleEngine.minCycle...CycleEngine.maxCycle) {
                        HStack {
                            Text(L.t("profile_cycle_len", lang)).foregroundStyle(Palette.ink)
                            Spacer()
                            Text(L.days(cycleLength, lang)).foregroundStyle(Palette.rose).fontWeight(.bold)
                        }
                    }
                }
            }
        }
    }

    private var modeStep: some View {
        VStack(spacing: 18) {
            titleBlock(L.t("onb_mode_title", lang), L.t("onb_mode_body", lang))
            VStack(spacing: 10) {
                ForEach(TrackingMode.allCases) { m in
                    Button {
                        mode = m
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: m.symbol)
                                .foregroundStyle(mode == m ? Palette.rose : Palette.sub)
                                .frame(width: 26)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L.t(m.key, lang))
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(Palette.ink)
                                Text(L.t(m.key + "_help", lang))
                                    .font(.caption2).foregroundStyle(Palette.sub)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: mode == m ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(mode == m ? Palette.rose : Palette.sub)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.card))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(mode == m ? Palette.rose : .clear, lineWidth: 2))
                    }
                }
            }
        }
    }

    private var languageStep: some View {
        VStack(spacing: 18) {
            Text(L.t("onb_language_title", lang))
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            VStack(spacing: 10) {
                ForEach(AppLanguage.allCases) { l in
                    Button {
                        languageRaw = l.rawValue
                    } label: {
                        HStack {
                            Text(l.name)
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(Palette.ink)
                            Spacer()
                            Image(systemName: l.rawValue == languageRaw ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(l.rawValue == languageRaw ? Palette.rose : Palette.sub)
                        }
                        .padding(.horizontal, 18).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.card))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(l.rawValue == languageRaw ? Palette.rose : .clear, lineWidth: 2))
                    }
                }
            }
        }
    }

    private func titleBlock(_ title: String, _ body: String) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text(body)
                .font(.body)
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
        }
    }

    private var button: some View {
        Button {
            if step >= lastStep { finish() } else { step += 1 }
        } label: {
            Text(step >= lastStep ? L.t("onb_start", lang) : continueLabel)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(LinearGradient(colors: [Palette.rose, Palette.roseDeep],
                                                          startPoint: .leading, endPoint: .trailing)))
        }
        .disabled(step == 2 && name.trimmingCharacters(in: .whitespaces).isEmpty)
        .opacity(step == 2 && name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
    }

    private var continueLabel: String {
        // "Continue" via onboarding key set; fall back to a sensible default.
        let map: [AppLanguage: String] = [.en: "Continue", .fr: "Continuer", .es: "Continuar", .de: "Weiter", .pt: "Continuar"]
        return map[lang] ?? "Continue"
    }

    private func finish() {
        let p = Profile(name: name.trimmingCharacters(in: .whitespaces),
                        colorHex: Palette.profileSwatches[0],
                        cycleLength: cycleLength, periodLength: CycleEngine.defaultPeriod, order: 0)
        p.mode = mode
        // In pregnancy mode the picked date is the LMP: it dates the pregnancy and
        // still belongs in the period history.
        p.pregnancyStart = mode == .pregnancy ? lastPeriod : nil
        ctx.insert(p)
        let entry = PeriodEntry(startDate: lastPeriod, profile: p)
        ctx.insert(entry)
        try? ctx.save()
        selectedID = p.id.uuidString
        onboarded = true
        NotificationManager.shared.requestAuthorization()
    }
}
