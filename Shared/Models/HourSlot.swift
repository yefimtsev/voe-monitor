import Foundation

/// A single one-hour time slot in the 24-hour disconnection schedule.
///
/// Slot `id` ranges from 1 to 24, where slot N covers hour `(N-1):00` to `N:00`.
/// The source data has half-hour resolution, so each slot keeps both halves.
public struct HourSlot: Identifiable, Sendable, Equatable {
    /// Slot number (1–24). Slot 1 = 00:00–01:00.
    public let id: Int
    /// Power during `:00–:30`.
    public let firstHalf: PowerStatus
    /// Power during `:30–:00`.
    public let secondHalf: PowerStatus

    public init(id: Int, firstHalf: PowerStatus, secondHalf: PowerStatus) {
        self.id = id
        self.firstHalf = firstHalf
        self.secondHalf = secondHalf
    }

    /// Builds a slot from the API status: `yes`, `no`, `first` (off first half), `second` (off second half).
    public init(id: Int, apiStatus: String) {
        let halves: (PowerStatus, PowerStatus) = switch apiStatus {
        case "yes": (.on, .on)
        case "no": (.off, .off)
        case "first": (.off, .on)
        case "second": (.on, .off)
        default: (.unknown, .unknown)
        }
        self.init(id: id, firstHalf: halves.0, secondHalf: halves.1)
    }

    /// Whole-hour summary: `.partial` when the halves differ.
    public var status: PowerStatus {
        firstHalf == secondHalf ? firstHalf : .partial
    }

    /// Full hour range label, e.g. `"08:00–09:00"` (24h) or `"8:00 AM–9:00 AM"` (12h).
    public func hourRange(use24h: Bool) -> String {
        let start = id - 1
        let end = id % 24
        if use24h {
            return String(format: "%02d:00–%02d:00", start, end)
        }
        return "\(Self.format12h(start))–\(Self.format12h(end))"
    }

    /// Short label showing the start hour, e.g. `"08"` (24h) or `"8"` (12h).
    public func shortHour(use24h: Bool) -> String {
        let hour = id - 1
        if use24h {
            return String(format: "%02d", hour)
        }
        let h12 = hour % 12
        return "\(h12 == 0 ? 12 : h12)"
    }

    /// Format an hour (0–23) as 12-hour string with AM/PM, e.g. `"2:00 PM"`.
    public static func format12h(_ hour: Int) -> String {
        let h12 = hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return "\(h12 == 0 ? 12 : h12):00 \(period)"
    }
}
