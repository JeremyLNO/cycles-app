import Foundation
import SwiftData

/// How a person uses the app. The home screen adapts to the selected mode.
enum TrackingMode: String, CaseIterable, Identifiable {
    case tracking      // follow the cycle (default)
    case conceiving    // trying to conceive: fertile window front and centre
    case pregnancy     // pregnancy: weeks and due date instead of predictions

    var id: String { rawValue }
    var key: String { "mode_\(rawValue)" }
    var symbol: String {
        switch self {
        case .tracking:   return "drop.fill"
        case .conceiving: return "heart.circle.fill"
        case .pregnancy:  return "figure.child.circle"
        }
    }
}

/// A tracked person. The app supports several profiles (e.g. for the whole family).
/// CloudKit-compatible: every stored property has a default and relationships are optional.
@Model
final class Profile {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "#F2738F"
    var cycleLength: Int = CycleEngine.defaultCycle
    var periodLength: Int = CycleEngine.defaultPeriod
    var lutealLength: Int = CycleEngine.defaultLuteal
    var order: Int = 0
    var createdAt: Date = Date()

    // Optional personal info the user can add about herself.
    var birthDate: Date? = nil
    var childrenCount: Int = 0

    // Tracking / conceiving / pregnancy mode.
    var modeRaw: String = TrackingMode.tracking.rawValue
    /// First day of the last menstrual period, used to date the pregnancy.
    var pregnancyStart: Date? = nil

    @Relationship(deleteRule: .cascade, inverse: \PeriodEntry.profile)
    var entries: [PeriodEntry]? = []

    @Relationship(deleteRule: .cascade, inverse: \DayLog.profile)
    var dayLogs: [DayLog]? = []

    init(name: String = "",
         colorHex: String = "#F2738F",
         cycleLength: Int = CycleEngine.defaultCycle,
         periodLength: Int = CycleEngine.defaultPeriod,
         order: Int = 0) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.cycleLength = cycleLength
        self.periodLength = periodLength
        self.lutealLength = CycleEngine.defaultLuteal
        self.order = order
        self.createdAt = Date()
        self.entries = []
        self.dayLogs = []
    }

    var mode: TrackingMode {
        get { TrackingMode(rawValue: modeRaw) ?? .tracking }
        set { modeRaw = newValue.rawValue }
    }

    /// Pregnancy progress, when the profile is in pregnancy mode and a start date is set.
    func pregnancy(now: Date = Date()) -> PregnancyProgress? {
        guard mode == .pregnancy else { return nil }
        // Fall back to the last logged period if no explicit start date was given.
        guard let lmp = pregnancyStart ?? startDates.last else { return nil }
        return CycleEngine.pregnancy(lastPeriod: lmp, now: now)
    }

    /// Age in years, derived from the birth date (nil if not set).
    var age: Int? {
        guard let birthDate else { return nil }
        return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
    }

    /// Sorted (ascending) logged period start dates.
    var startDates: [Date] {
        (entries ?? []).map { $0.startDate }.sorted()
    }

    /// The journal entry logged on the given day, if any.
    func dayLog(on date: Date) -> DayLog? {
        let day = Calendar.current.startOfDay(for: date)
        return (dayLogs ?? []).first { Calendar.current.startOfDay(for: $0.date) == day }
    }

    /// Prediction for this profile, or nil if nothing has been logged yet.
    func prediction(now: Date = Date()) -> CyclePrediction? {
        CycleEngine.predict(starts: startDates,
                            cycleLength: cycleLength,
                            periodLength: periodLength,
                            lutealLength: lutealLength,
                            now: now)
    }

    /// Builds the App Group snapshot the widget reads.
    func snapshot(now: Date = Date(), lang: AppLanguage = .current) -> CycleSnapshot {
        // Pregnancy: the widget shows weeks and the due date, never a period countdown.
        if let preg = pregnancy(now: now) {
            return CycleSnapshot(
                hasData: true, name: name, colorHex: colorHex,
                kind: NextEventKind.period.rawValue,
                days: preg.daysRemaining, eventDate: preg.dueDate,
                phase: CyclePhase.luteal.rawValue,
                isPeriodLate: false, lateDays: 0, dayOfCycle: preg.daysElapsed,
                lang: lang.rawValue, mode: TrackingMode.pregnancy.rawValue, weeks: preg.weeks
            )
        }
        guard let p = prediction(now: now) else {
            var empty = CycleSnapshot.empty
            empty.name = name
            empty.colorHex = colorHex
            empty.lang = lang.rawValue
            empty.mode = mode.rawValue
            return empty
        }
        let nearest = p.nearestEvent
        return CycleSnapshot(
            hasData: true,
            name: name,
            colorHex: colorHex,
            kind: nearest.kind.rawValue,
            days: nearest.days,
            eventDate: nearest.date,
            phase: p.phase.rawValue,
            isPeriodLate: p.isPeriodLate,
            lateDays: p.lateDays,
            dayOfCycle: p.dayOfCycle,
            lang: lang.rawValue,
            mode: mode.rawValue,
            weeks: 0
        )
    }
}

/// One logged period (its first day, and optionally when it ended).
@Model
final class PeriodEntry {
    var id: UUID = UUID()
    var startDate: Date = Date()
    var endDate: Date? = nil
    var note: String? = nil
    var profile: Profile? = nil

    init(startDate: Date, endDate: Date? = nil, note: String? = nil, profile: Profile? = nil) {
        self.id = UUID()
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.endDate = endDate
        self.note = note
        self.profile = profile
    }
}

// MARK: - Journal (symptoms, mood, flow)

/// Menstrual flow intensity logged for a day.
enum Flow: Int, CaseIterable, Identifiable {
    case none = 0, light = 1, medium = 2, heavy = 3
    var id: Int { rawValue }
    var key: String {
        switch self {
        case .none: return "flow_none"
        case .light: return "flow_light"
        case .medium: return "flow_medium"
        case .heavy: return "flow_heavy"
        }
    }
    /// Number of filled drops shown in the picker (0…3).
    var drops: Int { rawValue }
}

/// A simple 5-point mood scale (chart-friendly).
enum Mood: Int, CaseIterable, Identifiable {
    case awful = 1, bad = 2, okay = 3, good = 4, great = 5
    var id: Int { rawValue }
    var key: String {
        switch self {
        case .awful: return "mood_awful"
        case .bad: return "mood_bad"
        case .okay: return "mood_okay"
        case .good: return "mood_good"
        case .great: return "mood_great"
        }
    }
    var symbol: String {
        switch self {
        case .awful: return "cloud.rain.fill"
        case .bad: return "cloud.fill"
        case .okay: return "cloud.sun.fill"
        case .good: return "sun.max.fill"
        case .great: return "sparkles"
        }
    }
}

/// Multi-select symptoms tracked per day.
enum Symptom: String, CaseIterable, Identifiable {
    case cramps, headache, bloating, tenderBreasts, acne, fatigue
    case backache, nausea, cravings, insomnia, moodSwings, discharge
    var id: String { rawValue }
    var key: String { "symptom_\(rawValue.lowercased())" }
    var symbol: String {
        switch self {
        case .cramps: return "bolt.fill"
        case .headache: return "brain.head.profile"
        case .bloating: return "circle.circle.fill"
        case .tenderBreasts: return "heart.circle.fill"
        case .acne: return "face.smiling"
        case .fatigue: return "zzz"
        case .backache: return "figure.walk"
        case .nausea: return "wind"
        case .cravings: return "fork.knife"
        case .insomnia: return "moon.zzz.fill"
        case .moodSwings: return "arrow.up.arrow.down"
        case .discharge: return "drop.triangle.fill"
        }
    }
}

/// A daily journal entry: flow, mood, symptoms and a free note.
/// CloudKit-compatible: every stored property has a default; the relationship is optional.
@Model
final class DayLog {
    var id: UUID = UUID()
    var date: Date = Date()
    var flowRaw: Int = 0
    var moodRaw: Int = 0            // 0 = not set
    var symptomsRaw: [String] = []
    var note: String? = nil
    var profile: Profile? = nil

    init(date: Date, profile: Profile? = nil) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.profile = profile
    }

    var flow: Flow {
        get { Flow(rawValue: flowRaw) ?? .none }
        set { flowRaw = newValue.rawValue }
    }
    var mood: Mood? {
        get { Mood(rawValue: moodRaw) }
        set { moodRaw = newValue?.rawValue ?? 0 }
    }
    var symptoms: [Symptom] {
        get { symptomsRaw.compactMap { Symptom(rawValue: $0) } }
        set { symptomsRaw = newValue.map { $0.rawValue } }
    }

    /// True when nothing meaningful has been logged (used to prune empty entries).
    var isEmpty: Bool {
        flowRaw == 0 && moodRaw == 0 && symptomsRaw.isEmpty && (note ?? "").isEmpty
    }
}
