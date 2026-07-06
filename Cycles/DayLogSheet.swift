import SwiftUI
import SwiftData

/// Daily journal editor: flow, mood, symptoms and a note for one day.
struct DayLogSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.systemDefault.rawValue

    let profile: Profile
    let date: Date
    private let existing: DayLog?

    @State private var flow: Flow
    @State private var mood: Mood?
    @State private var symptoms: Set<Symptom>
    @State private var note: String

    init(profile: Profile, date: Date) {
        self.profile = profile
        let day = CycleEngine.startOfDay(date)
        self.date = day
        let log = profile.dayLog(on: day)
        self.existing = log
        _flow = State(initialValue: log?.flow ?? .none)
        _mood = State(initialValue: log?.mood)
        _symptoms = State(initialValue: Set(log?.symptoms ?? []))
        _note = State(initialValue: log?.note ?? "")
    }

    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

    var body: some View {
        NavigationStack {
            ZStack {
                CyclesBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(cyclesDate(date, lang: lang, template: "EEEE d MMMM").capitalized)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Palette.sub)

                        flowSection
                        moodSection
                        symptomsSection
                        noteSection

                        if existing != nil {
                            Button(role: .destructive) { delete() } label: {
                                Label(L.t("log_delete", lang), systemImage: "trash")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(L.t("journal_title", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L.t("cancel", lang)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button(L.t("save", lang)) { save() }.fontWeight(.bold) }
            }
        }
    }

    // MARK: Flow
    private var flowSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(L.t("journal_flow", lang), "drop.fill")
            HStack(spacing: 10) {
                ForEach(Flow.allCases) { f in
                    let selected = flow == f
                    Button {
                        flow = f
                    } label: {
                        VStack(spacing: 6) {
                            HStack(spacing: 1) {
                                if f == .none {
                                    Image(systemName: "minus")
                                } else {
                                    ForEach(0..<f.drops, id: \.self) { _ in Image(systemName: "drop.fill") }
                                }
                            }
                            .font(.footnote)
                            .foregroundStyle(selected ? Palette.menstruation : Palette.sub)
                            Text(L.t(f.key, lang))
                                .font(.caption2)
                                .foregroundStyle(selected ? Palette.ink : Palette.sub)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(chipBackground(selected, tint: Palette.menstruation))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Mood
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(L.t("journal_mood", lang), "face.smiling")
            HStack(spacing: 8) {
                ForEach(Mood.allCases) { m in
                    let selected = mood == m
                    Button {
                        mood = (mood == m) ? nil : m
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: m.symbol)
                                .font(.title3)
                                .foregroundStyle(selected ? Palette.rose : Palette.sub)
                            Text(L.t(m.key, lang))
                                .font(.caption2)
                                .foregroundStyle(selected ? Palette.ink : Palette.sub)
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(chipBackground(selected, tint: Palette.rose))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Symptoms
    private var symptomsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(L.t("journal_symptoms", lang), "list.bullet.clipboard")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
                ForEach(Symptom.allCases) { s in
                    let selected = symptoms.contains(s)
                    Button {
                        if selected { symptoms.remove(s) } else { symptoms.insert(s) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: s.symbol).font(.caption)
                            Text(L.t(s.key, lang)).font(.caption).lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .foregroundStyle(selected ? .white : Palette.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10).padding(.horizontal, 8)
                        .background(
                            Capsule().fill(selected ? Palette.rose : Palette.card)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Note
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(L.t("journal_note", lang), "square.and.pencil")
            GlassCard {
                TextField(L.t("journal_note_ph", lang), text: $note, axis: .vertical)
                    .lineLimit(2...5)
            }
        }
    }

    private func sectionTitle(_ text: String, _ icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(Palette.ink)
    }

    private func chipBackground(_ selected: Bool, tint: Color) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(selected ? tint.opacity(0.16) : Palette.card)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? tint : .clear, lineWidth: 1.5)
            )
    }

    // MARK: Persistence
    private func save() {
        let log = existing ?? DayLog(date: date, profile: profile)
        log.flow = flow
        log.mood = mood
        log.symptoms = Array(symptoms).sorted { $0.rawValue < $1.rawValue }
        log.note = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note

        if log.isEmpty {
            if existing != nil { ctx.delete(log) }   // cleared out an existing entry
        } else if existing == nil {
            ctx.insert(log)
        }
        try? ctx.save()
        dismiss()
    }

    private func delete() {
        if let existing { ctx.delete(existing); try? ctx.save() }
        dismiss()
    }
}
