import Foundation
import WidgetKit

/// A small, widget-friendly summary of the selected profile's next event.
/// Written by the app, read by the widget (no SwiftData/CloudKit in the extension).
struct CycleSnapshot: Codable {
    var hasData: Bool
    var name: String
    var colorHex: String
    var kind: String          // NextEventKind raw value ("period" / "ovulation")
    var days: Int
    var eventDate: Date       // the date of the nearest event, so the widget recomputes daily
    var phase: String         // CyclePhase raw value
    var isPeriodLate: Bool
    var lateDays: Int
    var dayOfCycle: Int
    var lang: String          // AppLanguage raw value, so the widget localises correctly

    var eventKind: NextEventKind { NextEventKind(rawValue: kind) ?? .period }
    var phaseValue: CyclePhase { CyclePhase(rawValue: phase) ?? .follicular }
    var language: AppLanguage { AppLanguage(rawValue: lang) ?? .current }

    static let empty = CycleSnapshot(hasData: false, name: "", colorHex: "#F2738F",
                                     kind: "period", days: 0, eventDate: Date(), phase: "follicular",
                                     isPeriodLate: false, lateDays: 0, dayOfCycle: 1,
                                     lang: AppLanguage.current.rawValue)
}

/// Shared App Group storage bridging the app and the widget.
enum SharedStore {
    static let appGroup = "group.company.lno.cycles"
    private static let snapshotKey = "cycles.snapshot.v1"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static func save(_ snapshot: CycleSnapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: snapshotKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func load() -> CycleSnapshot {
        guard let data = defaults.data(forKey: snapshotKey),
              let snap = try? JSONDecoder().decode(CycleSnapshot.self, from: data) else {
            return .empty
        }
        return snap
    }

    static func clear() {
        defaults.removeObject(forKey: snapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
