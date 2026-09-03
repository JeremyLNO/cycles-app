import Foundation
import HealthKit
import SwiftData

/// Two-way sync with Apple Health for menstrual flow.
/// Only the selected person is synced — Health is personal to the device owner.
@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    @Published var lastError: String?
    @Published var lastImportCount: Int?
    @Published var isBusy = false

    static let enabledKey = "health.sync.enabled"

    private let store = HKHealthStore()

    /// HealthKit menstrual-flow values. `HKCategoryValueVaginalBleeding` (iOS 18+) and the
    /// legacy `HKCategoryValueMenstrualFlow` share these raw values, so we use them directly
    /// and stay warning-free on our iOS 17 deployment target.
    private enum FlowValue {
        static let unspecified = 1, light = 2, medium = 3, heavy = 4, none = 5
    }

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.enabledKey) }
    }

    private var flowType: HKCategoryType? {
        HKObjectType.categoryType(forIdentifier: .menstrualFlow)
    }

    /// True once the user granted write access (read status is deliberately opaque on iOS).
    var canWrite: Bool {
        guard isAvailable, let flowType else { return false }
        return store.authorizationStatus(for: flowType) == .sharingAuthorized
    }

    // MARK: Authorization

    @discardableResult
    func requestAuthorization() async -> Bool {
        guard isAvailable, let flowType else {
            lastError = L.t("health_unavailable")
            return false
        }
        do {
            try await store.requestAuthorization(toShare: [flowType], read: [flowType])
            lastError = nil
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    // MARK: Export (app → Health)

    /// Writes the profile's period days to Health, replacing what this app wrote before.
    func export(profile: Profile) async {
        guard isEnabled, canWrite, let flowType else { return }
        let cal = Calendar.current
        let periodLen = max(1, profile.periodLength)

        var samples: [HKCategorySample] = []
        var earliest: Date?

        for entry in profile.entries ?? [] {
            let start = CycleEngine.startOfDay(entry.startDate)
            let last = entry.endDate.map(CycleEngine.startOfDay)
                ?? CycleEngine.addingDays(periodLen - 1, to: start)
            earliest = min(earliest ?? start, start)

            var day = start
            while day <= last {
                let value = flowValue(for: profile.dayLog(on: day)?.flow)
                let end = cal.date(byAdding: .minute, value: 1, to: day) ?? day
                let metadata: [String: Any] = [HKMetadataKeyMenstrualCycleStart: day == start]
                samples.append(HKCategorySample(type: flowType, value: value,
                                                start: day, end: end, metadata: metadata))
                day = CycleEngine.addingDays(1, to: day)
            }
        }
        guard !samples.isEmpty, let from = earliest else { return }

        // Replace our own previous samples in the range (HealthKit only lets an app
        // delete what it wrote itself), then save the fresh set.
        let predicate = HKQuery.predicateForSamples(withStart: from,
                                                    end: Date().addingTimeInterval(86_400),
                                                    options: [])
        await deleteOwnSamples(of: flowType, predicate: predicate)
        do { try await store.save(samples) } catch { lastError = error.localizedDescription }
    }

    private func flowValue(for flow: Flow?) -> Int {
        switch flow {
        case .some(.light):  return FlowValue.light
        case .some(.medium): return FlowValue.medium
        case .some(.heavy):  return FlowValue.heavy
        default:             return FlowValue.unspecified   // logged, intensity unknown
        }
    }

    private func deleteOwnSamples(of type: HKSampleType, predicate: NSPredicate) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            store.deleteObjects(of: type, predicate: predicate) { _, _, _ in cont.resume() }
        }
    }

    // MARK: Import (Health → app)

    /// Reads cycle starts recorded in Health (by any app) and adds the missing ones.
    @discardableResult
    func importCycleStarts(into profile: Profile, context: ModelContext) async -> Int {
        guard isAvailable, let flowType else {
            lastError = L.t("health_unavailable")
            return 0
        }
        let from = CycleEngine.addingDays(-730, to: CycleEngine.startOfDay(Date()))
        let predicate = HKQuery.predicateForSamples(withStart: from, end: Date(), options: [])

        let samples: [HKCategorySample] = await withCheckedContinuation { cont in
            let query = HKSampleQuery(sampleType: flowType, predicate: predicate,
                                      limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, result, _ in
                cont.resume(returning: (result as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }

        // Only the samples explicitly flagged as the first day of a cycle.
        let starts = samples
            .filter { ($0.metadata?[HKMetadataKeyMenstrualCycleStart] as? Bool) == true }
            .map { CycleEngine.startOfDay($0.startDate) }
        let known = Set(profile.startDates.map(CycleEngine.startOfDay))

        var added = 0
        for day in Set(starts).sorted() where !known.contains(day) {
            context.insert(PeriodEntry(startDate: day, profile: profile))
            added += 1
        }
        if added > 0 { try? context.save() }
        lastImportCount = added
        return added
    }
}
