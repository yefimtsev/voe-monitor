import Foundation

/// A single one-hour time slot in the 24-hour disconnection schedule.
///
/// Slot `id` ranges from 1 to 24, where slot N covers hour `(N-1):00` to `N:00`.
struct HourSlot: Identifiable {
    /// Slot number (1–24). Slot 1 = 00:00–01:00.
    let id: Int
    let status: PowerStatus

    /// Full hour range label, e.g. `"08:00–09:00"` (24h) or `"8:00–9:00 AM"` (12h).
    func hourRange(use24h: Bool) -> String {
        let start = id - 1
        let end = id % 24
        if use24h {
            return String(format: "%02d:00–%02d:00", start, end)
        }
        return "\(Self.format12h(start))–\(Self.format12h(end))"
    }

    /// Short label showing the start hour, e.g. `"08"` (24h) or `"8"` (12h).
    func shortHour(use24h: Bool) -> String {
        let hour = id - 1
        if use24h {
            return String(format: "%02d", hour)
        }
        let h12 = hour % 12
        return "\(h12 == 0 ? 12 : h12)"
    }

    /// Format an hour (0–23) as 12-hour string with AM/PM, e.g. `"2:00 PM"`.
    static func format12h(_ hour: Int) -> String {
        let h12 = hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return "\(h12 == 0 ? 12 : h12):00 \(period)"
    }

    /// Format a slot ID as a time string respecting the given format preference.
    static func formatTime(slotId: Int, use24h: Bool) -> String {
        let hour = slotId - 1
        if use24h {
            return String(format: "%02d:00", hour)
        }
        return format12h(hour)
    }
}
