import WidgetKit

struct VOETimelineEntry: TimelineEntry {
    let date: Date
    let status: PowerStatus
    let todaySchedule: DaySchedule?
    let tomorrowSchedule: DaySchedule?
    let queueName: String
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
            use24h: true,
            isPlaceholder: true,
            errorMessage: nil
        )
    }
}
