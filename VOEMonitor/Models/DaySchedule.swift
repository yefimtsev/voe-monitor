import Foundation

/// A full day's disconnection schedule containing 24 hourly slots.
struct DaySchedule: Identifiable {
    /// Unix timestamp representing the start of the day (used as the API key).
    let id: Int
    let date: Date
    let slots: [HourSlot]

    /// Formatted date string, e.g. `"11.02 (Wednesday)"`.
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM (EEEE)"
        return formatter.string(from: date)
    }
}
