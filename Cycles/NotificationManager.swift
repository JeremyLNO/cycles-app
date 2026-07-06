import Foundation
import UserNotifications

/// Schedules local "1 day before" reminders for period and ovulation, per profile.
/// We own every notification we schedule, so a full clear-then-reschedule is simplest.
final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    /// Settings keys (mirrored by @AppStorage in SettingsView).
    enum Keys {
        static let periodEnabled = "notif.period.enabled"
        static let ovulationEnabled = "notif.ovulation.enabled"
        static let hour = "notif.hour"
        static let minute = "notif.minute"
    }

    func requestAuthorization(_ completion: ((Bool) -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion?(granted) }
        }
    }

    /// Reads the saved preferences and reschedules everything for the given profiles.
    func reschedule(profiles: [Profile], lang: AppLanguage = .current) {
        let d = UserDefaults.standard
        let periodOn = d.object(forKey: Keys.periodEnabled) as? Bool ?? true
        let ovulationOn = d.object(forKey: Keys.ovulationEnabled) as? Bool ?? true
        let hour = d.object(forKey: Keys.hour) as? Int ?? 9
        let minute = d.object(forKey: Keys.minute) as? Int ?? 0
        reschedule(profiles: profiles, periodEnabled: periodOn, ovulationEnabled: ovulationOn,
                   hour: hour, minute: minute, lang: lang)
    }

    func reschedule(profiles: [Profile], periodEnabled: Bool, ovulationEnabled: Bool,
                    hour: Int, minute: Int, lang: AppLanguage) {
        center.removeAllPendingNotificationRequests()
        guard periodEnabled || ovulationEnabled else { return }

        let cal = Calendar.current
        let now = Date()

        for profile in profiles {
            guard let p = profile.prediction(now: now) else { continue }
            let name = profile.name.trimmingCharacters(in: .whitespaces)
            let avg = p.averageCycleLength

            if periodEnabled {
                for i in 0..<3 {
                    let date = cal.date(byAdding: .day, value: i * avg, to: p.upcomingPeriod) ?? p.upcomingPeriod
                    schedule(id: "period.\(profile.id.uuidString).\(i)",
                             eventDate: date, hour: hour, minute: minute,
                             title: L.t("notif_period_title", lang),
                             body: body("notif_period_body", named: "notif_period_body_named", name: name, lang: lang))
                }
            }
            if ovulationEnabled {
                for i in 0..<3 {
                    let date = cal.date(byAdding: .day, value: i * avg, to: p.upcomingOvulation) ?? p.upcomingOvulation
                    schedule(id: "ovulation.\(profile.id.uuidString).\(i)",
                             eventDate: date, hour: hour, minute: minute,
                             title: L.t("notif_ovulation_title", lang),
                             body: body("notif_ovulation_body", named: "notif_ovulation_body_named", name: name, lang: lang))
                }
            }
        }
    }

    private func body(_ plain: String, named: String, name: String, lang: AppLanguage) -> String {
        name.isEmpty ? L.t(plain, lang) : String(format: L.t(named, lang), name)
    }

    /// Schedules one notification fired the day BEFORE `eventDate` at hour:minute.
    private func schedule(id: String, eventDate: Date, hour: Int, minute: Int, title: String, body: String) {
        let cal = Calendar.current
        guard let dayBefore = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: eventDate)),
              var comps = Optional(cal.dateComponents([.year, .month, .day], from: dayBefore)) else { return }
        comps.hour = hour
        comps.minute = minute
        guard let fireDate = cal.date(from: comps), fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
            repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
