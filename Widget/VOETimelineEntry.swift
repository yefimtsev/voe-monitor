import WidgetKit

struct VOETimelineEntry: TimelineEntry {
    let date: Date
    let status: PowerStatus
    let todaySchedule: DaySchedule?
    let tomorrowSchedule: DaySchedule?
    let queueName: String
    /// "Outage at 14:00 (~2h)" etc., for the lock screen.
    let nextEventText: String
    let use24h: Bool
    let isPlaceholder: Bool
    let errorMessage: String?

    static var placeholder: VOETimelineEntry {
        VOETimelineEntry(
            date: Date(),
            status: .unknown,
            todaySchedule: nil,
            tomorrowSchedule: nil,
            queueName: "---",
            nextEventText: "",
            use24h: true,
            isPlaceholder: true,
            errorMessage: nil
        )
    }

    static func error(_ message: String, queueName: String, use24h: Bool) -> VOETimelineEntry {
        VOETimelineEntry(
            date: Date(),
            status: .unknown,
            todaySchedule: nil,
            tomorrowSchedule: nil,
            queueName: queueName,
            nextEventText: "",
            use24h: use24h,
            isPlaceholder: false,
            errorMessage: message
        )
    }
}
