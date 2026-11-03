import Foundation

/// User-facing text derived from the timeline.
public enum ScheduleText {
    /// "Outage at 14:00 (~2h 35m)", "Power at 16:00 (~35m)", "No outages", or empty when nothing is known.
    public static func nextEvent(timeline: OutageTimeline, now: Date, use24h: Bool, locale: Locale) -> String {
        let status = timeline.status(at: now)
        guard status == .on || status == .off else { return "" }

        guard let next = timeline.next(status == .on ? .off : .on, after: now) else {
            return status == .on ? String(localized: "next.no_outages", locale: locale) : ""
        }

        let time = KyivTime.format(next.start, use24h: use24h)
        let countdown = countdown(from: now, to: next.start, locale: locale)
        let isToday = KyivTime.calendar.isDate(next.start, inSameDayAs: now)

        return switch (status, isToday) {
        case (.off, true): String(localized: "next.power_at \(time) \(countdown)", locale: locale)
        case (.off, false): String(localized: "next.power_tomorrow_at \(time) \(countdown)", locale: locale)
        case (_, true): String(localized: "next.outage_at \(time) \(countdown)", locale: locale)
        case (_, false): String(localized: "next.outage_tomorrow_at \(time) \(countdown)", locale: locale)
        }
    }

    /// `"~2h 35m"`, `"~35m"` or `"< 1m"`.
    public static func countdown(from now: Date, to target: Date, locale: Locale) -> String {
        let totalMinutes = Int(target.timeIntervalSince(now) / 60)
        if totalMinutes < 1 {
            return String(localized: "countdown.less_than_minute", locale: locale)
        }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 {
            return String(localized: "countdown.minutes \(minutes)", locale: locale)
        }
        return String(localized: "countdown.hours_minutes \(hours) \(minutes)", locale: locale)
    }
}
