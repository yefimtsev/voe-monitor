import WidgetKit

struct VOETimelineProvider: AppIntentTimelineProvider {
    private let fetcher = ScheduleFetcher()
    private let configManager = SharedConfigManager()

    func placeholder(in context: Context) -> VOETimelineEntry {
        .placeholder
    }

    func snapshot(for configuration: SelectQueueIntent, in context: Context) async -> VOETimelineEntry {
        if context.isPreview {
            return .placeholder
        }
        return await fetchEntry(for: configuration)
    }

    func timeline(for configuration: SelectQueueIntent, in context: Context) async -> Timeline<VOETimelineEntry> {
        let entry = await fetchEntry(for: configuration)

        // Reload at the next hour boundary
        let calendar = Calendar.current
        let nextHour = calendar.nextDate(
            after: Date(),
            matching: DateComponents(minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)

        return Timeline(entries: [entry], policy: .after(nextHour))
    }

    private func fetchEntry(for configuration: SelectQueueIntent) async -> VOETimelineEntry {
        let config = configManager.load()
        let queueId = configuration.queue?.id ?? config.selectedQueue
        let use24h = config.use24HourTime

        guard !queueId.isEmpty else {
            return VOETimelineEntry(
                date: Date(),
                status: .unknown,
                todaySchedule: nil,
                tomorrowSchedule: nil,
                queueName: "",
                use24h: use24h,
                isPlaceholder: false,
                errorMessage: String(localized: "widget.no_queue")
            )
        }

        let queueName = Queue.all.first { $0.id == queueId }?.displayName ?? queueId

        do {
            let result = try await fetcher.fetchSchedule(for: queueId)
            return VOETimelineEntry(
                date: Date(),
                status: result.currentStatus,
                todaySchedule: result.todaySchedule,
                tomorrowSchedule: result.tomorrowSchedule,
                queueName: queueName,
                use24h: use24h,
                isPlaceholder: false,
                errorMessage: nil
            )
        } catch {
            return VOETimelineEntry(
                date: Date(),
                status: .unknown,
                todaySchedule: nil,
                tomorrowSchedule: nil,
                queueName: queueName,
                use24h: use24h,
                isPlaceholder: false,
                errorMessage: String(localized: "widget.fetch_error")
            )
        }
    }
}
