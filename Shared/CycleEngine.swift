import Foundation

/// The phase of the menstrual cycle on a given day. Drives colours, labels and icons.
enum CyclePhase: String, Codable, CaseIterable {
    case menstruation   // bleeding days
    case follicular     // after bleeding, before the fertile window
    case fertile        // fertile window (around ovulation)
    case ovulation      // the predicted ovulation day itself
    case luteal         // after the fertile window, before the PMS window
    case pms            // premenstrual window: the last days before the period

    /// Localization key for the phase name.
    var key: String {
        switch self {
        case .menstruation: return "phase_menstruation"
        case .follicular:   return "phase_follicular"
        case .fertile:      return "phase_fertile"
        case .ovulation:    return "phase_ovulation"
        case .luteal:       return "phase_luteal"
        case .pms:          return "phase_pms"
        }
    }

    var emoji: String {
        switch self {
        case .menstruation: return "🌸"
        case .follicular:   return "🌱"
        case .fertile:      return "💧"
        case .ovulation:    return "✨"
        case .luteal:       return "🌙"
        case .pms:          return "⚡️"
        }
    }

    /// SF Symbol used in the UI (renders reliably everywhere, unlike emoji).
    var symbol: String {
        switch self {
        case .menstruation: return "drop.fill"
        case .follicular:   return "leaf.fill"
        case .fertile:      return "drop.circle.fill"
        case .ovulation:    return "sparkles"
        case .luteal:       return "moon.fill"
        case .pms:          return "bolt.heart.fill"
        }
    }
}

/// The next upcoming event the UI counts down to.
enum NextEventKind: String, Codable {
    case period
    case ovulation
}

/// A full prediction for one profile, computed from logged period start dates.
struct CyclePrediction {
    let lastPeriodStart: Date
    let averageCycleLength: Int
    let periodLength: Int
    let lutealLength: Int

    /// This cycle's predicted period date (lastPeriodStart + average cycle length).
    let predictedPeriod: Date
    let ovulationThisCycle: Date
    let fertileStart: Date
    let fertileEnd: Date

    /// First day of the premenstrual (PMS) window of this cycle.
    let pmsStart: Date

    let today: Date
    let dayOfCycle: Int
    let phase: CyclePhase

    /// True when today is past the predicted period date and no new period was logged.
    let isPeriodLate: Bool
    let lateDays: Int

    /// Always >= today: the period/ovulation/fertile window/PMS we are counting down to.
    let upcomingPeriod: Date
    let upcomingOvulation: Date
    let upcomingFertileStart: Date
    let upcomingPmsStart: Date
    let daysUntilPeriod: Int
    let daysUntilOvulation: Int
    let daysUntilFertile: Int
    let daysUntilPMS: Int

    /// Whichever upcoming event (period or ovulation) is the soonest — the hero number.
    var nearestEvent: (kind: NextEventKind, date: Date, days: Int) {
        if daysUntilOvulation < daysUntilPeriod {
            return (.ovulation, upcomingOvulation, daysUntilOvulation)
        }
        return (.period, upcomingPeriod, daysUntilPeriod)
    }

    /// True while the user is bleeding (within the period length of the last start).
    var isMenstruating: Bool { phase == .menstruation }

    /// True during the premenstrual window (PMS symptoms are likely).
    var isPMS: Bool { phase == .pms }

    /// True on the days the chance of conceiving is highest.
    var isFertile: Bool { phase == .fertile || phase == .ovulation }
}

/// Where a pregnancy stands, derived from the first day of the last menstrual period.
struct PregnancyProgress {
    let lastPeriod: Date        // LMP — the usual clinical reference
    let dueDate: Date           // LMP + 280 days
    let daysElapsed: Int
    let weeks: Int              // completed weeks (gestational age)
    let daysInWeek: Int
    let trimester: Int          // 1...3
    let daysRemaining: Int
    let progress: Double        // 0...1 around the ring
}

enum CycleEngine {
    static let minCycle = 21
    static let maxCycle = 40
    static let defaultCycle = 28
    static let defaultPeriod = 5
    static let defaultLuteal = 14
    /// Length of the premenstrual (PMS) window, in days before the expected period.
    static let pmsWindow = 5
    /// Standard pregnancy length from the last menstrual period.
    static let pregnancyDays = 280

    private static var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2 // Monday; display formatters use the user locale anyway
        return c
    }

    static func startOfDay(_ date: Date) -> Date { cal.startOfDay(for: date) }

    static func days(from: Date, to: Date) -> Int {
        cal.dateComponents([.day], from: startOfDay(from), to: startOfDay(to)).day ?? 0
    }

    static func addingDays(_ n: Int, to date: Date) -> Date {
        cal.date(byAdding: .day, value: n, to: date) ?? date
    }

    /// Average cycle length from the most recent (up to 6) gaps between logged starts,
    /// clamped to a sane range. Falls back to the profile's configured length.
    static func averageCycle(starts: [Date], fallback: Int) -> Int {
        let sorted = starts.map(startOfDay).sorted()
        guard sorted.count >= 2 else { return clampCycle(fallback) }
        var gaps: [Int] = []
        for i in 1..<sorted.count {
            gaps.append(days(from: sorted[i - 1], to: sorted[i]))
        }
        let recent = Array(gaps.suffix(6)).filter { $0 >= minCycle - 5 && $0 <= maxCycle + 10 }
        guard !recent.isEmpty else { return clampCycle(fallback) }
        let avg = Int((Double(recent.reduce(0, +)) / Double(recent.count)).rounded())
        return clampCycle(avg)
    }

    static func clampCycle(_ n: Int) -> Int { min(maxCycle, max(minCycle, n)) }

    /// Builds a prediction from logged starts. Returns nil when nothing has been logged yet.
    static func predict(starts: [Date],
                        cycleLength: Int = defaultCycle,
                        periodLength: Int = defaultPeriod,
                        lutealLength: Int = defaultLuteal,
                        now: Date = Date()) -> CyclePrediction? {
        let sorted = starts.map(startOfDay).sorted()
        guard let lastStart = sorted.last else { return nil }
        let today = startOfDay(now)
        let avg = averageCycle(starts: sorted, fallback: cycleLength)
        let period = max(1, periodLength)
        let luteal = max(7, min(20, lutealLength))

        let predictedPeriod = addingDays(avg, to: lastStart)
        let ovulationThisCycle = addingDays(-luteal, to: predictedPeriod)
        let fertileStart = addingDays(-5, to: ovulationThisCycle)
        let fertileEnd = addingDays(1, to: ovulationThisCycle)
        // PMS window: the last days of the luteal phase, never overlapping the fertile window.
        let pmsStart = max(addingDays(-pmsWindow, to: predictedPeriod), addingDays(1, to: fertileEnd))

        let dayOfCycle = max(1, days(from: lastStart, to: today) + 1)

        // Lateness: today is past the predicted period but nothing new logged.
        let isLate = today > predictedPeriod
        let lateDays = isLate ? days(from: predictedPeriod, to: today) : 0

        // Phase for today.
        let phase: CyclePhase
        let sinceStart = days(from: lastStart, to: today)
        if sinceStart >= 0 && sinceStart < period {
            phase = .menstruation
        } else if today < fertileStart {
            phase = .follicular
        } else if today >= fertileStart && today <= fertileEnd {
            phase = (today == ovulationThisCycle) ? .ovulation : .fertile
        } else if today >= pmsStart && today < predictedPeriod {
            phase = .pms
        } else {
            phase = .luteal
        }

        // Upcoming events, rolled forward so they are never in the past.
        func rollForward(_ date: Date) -> Date {
            var d = date
            while d < today { d = addingDays(avg, to: d) }
            return d
        }
        let upcomingPeriod = rollForward(predictedPeriod)
        let upcomingOvulation = rollForward(ovulationThisCycle)
        let upcomingFertileStart = rollForward(fertileStart)
        let upcomingPmsStart = rollForward(pmsStart)

        return CyclePrediction(
            lastPeriodStart: lastStart,
            averageCycleLength: avg,
            periodLength: period,
            lutealLength: luteal,
            predictedPeriod: predictedPeriod,
            ovulationThisCycle: ovulationThisCycle,
            fertileStart: fertileStart,
            fertileEnd: fertileEnd,
            pmsStart: pmsStart,
            today: today,
            dayOfCycle: dayOfCycle,
            phase: phase,
            isPeriodLate: isLate,
            lateDays: lateDays,
            upcomingPeriod: upcomingPeriod,
            upcomingOvulation: upcomingOvulation,
            upcomingFertileStart: upcomingFertileStart,
            upcomingPmsStart: upcomingPmsStart,
            daysUntilPeriod: days(from: today, to: upcomingPeriod),
            daysUntilOvulation: days(from: today, to: upcomingOvulation),
            daysUntilFertile: days(from: today, to: upcomingFertileStart),
            daysUntilPMS: days(from: today, to: upcomingPmsStart)
        )
    }

    /// Pregnancy progress from the first day of the last menstrual period (LMP).
    static func pregnancy(lastPeriod: Date, now: Date = Date()) -> PregnancyProgress {
        let lmp = startOfDay(lastPeriod)
        let today = startOfDay(now)
        let elapsed = max(0, days(from: lmp, to: today))
        let due = addingDays(pregnancyDays, to: lmp)
        let weeks = elapsed / 7
        let trimester = weeks < 13 ? 1 : (weeks < 27 ? 2 : 3)
        return PregnancyProgress(
            lastPeriod: lmp,
            dueDate: due,
            daysElapsed: elapsed,
            weeks: weeks,
            daysInWeek: elapsed % 7,
            trimester: trimester,
            daysRemaining: max(0, days(from: today, to: due)),
            progress: min(1, max(0, Double(elapsed) / Double(pregnancyDays)))
        )
    }

    /// Progress (0...1) around the cycle ring for `today`, based on day-of-cycle vs average length.
    static func cycleProgress(_ p: CyclePrediction) -> Double {
        guard p.averageCycleLength > 0 else { return 0 }
        let frac = Double(p.dayOfCycle - 1) / Double(p.averageCycleLength)
        return min(1, max(0, frac))
    }
}
