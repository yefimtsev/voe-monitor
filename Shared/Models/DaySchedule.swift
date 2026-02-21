import Foundation

/// A full day's disconnection schedule containing 24 hourly slots.
public struct DaySchedule: Identifiable, Sendable {
    /// Unix timestamp representing the start of the day (used as the API key).
    public let id: Int
    public let date: Date
    public let slots: [HourSlot]

    public init(id: Int, date: Date, slots: [HourSlot]) {
        self.id = id
        self.date = date
        self.slots = slots
    }

    /// Formatted date string, e.g. `"11.02 (Wednesday)"`.
    public var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM (EEEE)"
        return formatter.string(from: date)
    }
}
