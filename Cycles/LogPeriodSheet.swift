import SwiftUI
import SwiftData

/// Add, change or delete a period start date for a profile.
struct LogPeriodSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.systemDefault.rawValue

    let profile: Profile
    var existing: PeriodEntry?
    @State private var date: Date

    init(profile: Profile, date: Date, existing: PeriodEntry? = nil) {
        self.profile = profile
        self.existing = existing
        _date = State(initialValue: existing?.startDate ?? date)
    }

    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }

    var body: some View {
        NavigationStack {
            ZStack {
                CyclesBackground()
                VStack(spacing: 18) {
                    Image(systemName: "drop.fill").font(.system(size: 40)).foregroundStyle(Palette.rose)
                    Text(L.t("log_subtitle", lang))
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)

                    GlassCard {
                        DatePicker(L.t("log_date", lang),
                                   selection: $date,
                                   in: ...Date(),
                                   displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(Palette.rose)
                    }

                    if existing != nil {
                        Button(role: .destructive) {
                            delete()
                        } label: {
                            Label(L.t("log_delete", lang), systemImage: "trash")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        }
                        .padding(.top, 4)
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle(L.t("log_title", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("cancel", lang)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.t("save", lang)) { save() }
                        .fontWeight(.bold)
                }
            }
        }
    }

    private func save() {
        let day = CycleEngine.startOfDay(date)
        if let existing {
            existing.startDate = day
        } else {
            // Avoid a duplicate entry on the same day.
            if !profile.startDates.contains(where: { CycleEngine.startOfDay($0) == day }) {
                let entry = PeriodEntry(startDate: day, profile: profile)
                ctx.insert(entry)
            }
        }
        try? ctx.save()
        dismiss()
    }

    private func delete() {
        if let existing {
            ctx.delete(existing)
            try? ctx.save()
        }
        dismiss()
    }
}
