import Foundation

/// Schedule times are Kyiv wall-clock times, whatever the device time zone is.
public enum KyivTime {
    // swiftlint:disable:next force_unwrapping
    public static let timeZone = TimeZone(identifier: "Europe/Kyiv")!

    public static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }()

    /// Hour slot id (1–24) that contains `date`.
    public static func slotID(at date: Date) -> Int {
        calendar.component(.hour, from: date) + 1
    }

    /// `"14:30"` (24h) or `"2:30 PM"` (12h).
    public static func format(_ date: Date, use24h: Bool) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let hour = parts.hour ?? 0
        let minute = parts.minute ?? 0
        if use24h {
            return String(format: "%02d:%02d", hour, minute)
        }
        let h12 = hour % 12
        return String(format: "%d:%02d %@", h12 == 0 ? 12 : h12, minute, hour < 12 ? "AM" : "PM")
    }
}
