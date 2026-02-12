import Foundation

/// A single one-hour time slot in the 24-hour disconnection schedule.
///
/// Slot `id` ranges from 1 to 24, where slot N covers hour `(N-1):00` to `N:00`.
struct HourSlot: Identifiable {
    /// Slot number (1–24). Slot 1 = 00:00–01:00.
    let id: Int
    let status: PowerStatus

    /// Full hour range label, e.g. `"08:00–09:00"`.
    var hourRange: String {
        let start = id - 1
        let end = id
        return String(format: "%02d:00–%02d:00", start, end)
    }

    /// Short label showing the start hour, e.g. `"08"`.
    var shortHour: String {
        String(format: "%02d", id - 1)
    }
}
