import WidgetKit
import SwiftUI

struct CycleEntry: TimelineEntry {
    let date: Date
    let snapshot: CycleSnapshot
}

struct CycleProvider: TimelineProvider {
    func placeholder(in context: Context) -> CycleEntry {
        CycleEntry(date: Date(), snapshot: sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (CycleEntry) -> Void) {
        let snap = context.isPreview ? sample : SharedStore.load()
        completion(CycleEntry(date: Date(), snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CycleEntry>) -> Void) {
        let base = SharedStore.load()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var entries: [CycleEntry] = []

        // One entry per day for a week, recomputing the day count so the widget
        // stays correct even if the app isn't opened.
        for offset in 0..<8 {
            guard let day = cal.date(byAdding: .day, value: offset, to: today) else { continue }
            var s = base
            if base.hasData {
                let remaining = cal.dateComponents([.day], from: day, to: cal.startOfDay(for: base.eventDate)).day ?? base.days
                s.days = max(0, remaining)
            }
            entries.append(CycleEntry(date: day, snapshot: s))
        }

        let reload = cal.date(byAdding: .day, value: 1, to: today) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: entries, policy: .after(reload)))
    }

    private var sample: CycleSnapshot {
        CycleSnapshot(hasData: true, name: "Léa", colorHex: "#F2738F",
                      kind: "ovulation", days: 5, eventDate: Date().addingTimeInterval(5 * 86400),
                      phase: "fertile", isPeriodLate: false, lateDays: 0, dayOfCycle: 10,
                      lang: AppLanguage.current.rawValue)
    }
}

struct CyclesWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CycleEntry
    var body: some View {
        CyclesWidgetContent(family: family, snapshot: entry.snapshot)
    }
}

struct CyclesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CyclesWidget", provider: CycleProvider()) { entry in
            CyclesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Cycles")
        .description(L.t("widget_desc"))
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct CyclesWidgetBundle: WidgetBundle {
    var body: some Widget {
        CyclesWidget()
    }
}
