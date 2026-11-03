import Foundation

/// A full day's disconnection schedule containing 24 hourly slots.
public struct DaySchedule: Identifiable, Sendable {
    /// Unix timestamp of the day's Kyiv midnight (the API key).
    public let id: Int
    public let date: Date
    public let slots: [HourSlot]

    public init(id: Int, date: Date, slots: [HourSlot]) {
        self.id = id
        self.date = date
        self.slots = slots
    }

    /// Kyiv date with weekday in `locale`, e.g. `"03.11 (вівторок)"`.
    public func dateString(locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = KyivTime.timeZone
        formatter.dateFormat = "dd.MM (EEEE)"
        return formatter.string(from: date)
    }
}
