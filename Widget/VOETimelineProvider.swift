import WidgetKit

struct VOETimelineProvider: AppIntentTimelineProvider {
    /// How far ahead entries are generated from one fetch.
    private static let horizon: TimeInterval = 24 * 3600
    /// When WidgetKit should ask again for fresh data.
    private static let reloadInterval: TimeInterval = 30 * 60

    private let fetcher = ScheduleFetcher()
    private let configManager = SharedConfigManager()

    func placeholder(in context: Context) -> VOETimelineEntry {
        .placeholder
    }

    func snapshot(for configuration: SelectQueueIntent, in context: Context) async -> VOETimelineEntry {
        if context.isPreview {
            return .placeholder
        }
        return await timeline(for: configuration, in: context).entries.first ?? .placeholder
    }

    /// One fetch, then an entry at every hour start and every status change in the next day,
    /// so the status and the current-hour highlight flip on time without spending reloads.
    func timeline(for configuration: SelectQueueIntent, in context: Context) async -> Timeline<VOETimelineEntry> {
        let now = Date()
        let config = configManager.load()
        let queueId = configuration.queue?.id ?? config.selectedQueue
        let use24h = config.use24HourTime

        guard !queueId.isEmpty else {
            let entry = VOETimelineEntry.error(String(localized: "widget.no_queue"), queueName: "", use24h: use24h)
            return Timeline(entries: [entry], policy: .never)
        }

        let queueName = Queue(id: queueId).displayName
        // The app's last download is in the shared cache, so a failed fetch still shows a schedule.
        let fetched = try? await fetcher.fetchResponse()
        guard let response = fetched ?? fetcher.cachedResponse() else {
            let entry = VOETimelineEntry.error(String(localized: "widget.fetch_error"), queueName: queueName, use24h: use24h)
            return Timeline(entries: [entry], policy: .after(now.addingTimeInterval(15 * 60)))
        }

        let timeline = fetcher.parse(response: response, queueId: queueId, now: now).timeline
        if fetched != nil, !config.selectedQueue.isEmpty {
            // iOS rarely wakes the app, but it runs this every ~30 minutes. Without this,
            // notifications planned from an old schedule would fire after VOE changed it.
            // The app's queue, not this widget's: a widget may be set to a different one.
            let appTimeline = fetcher.parse(response: response, queueId: config.selectedQueue, now: now).timeline
            await NotificationScheduler.reschedule(timeline: appTimeline, config: config, now: now)
        }

        let dates = timeline.refreshDates(from: now, until: now.addingTimeInterval(Self.horizon))
        let entries = dates.map { date in
            let result = fetcher.parse(response: response, queueId: queueId, now: date)
            let dayTimeline = result.timeline
            return VOETimelineEntry(
                date: date,
                status: dayTimeline.status(at: date),
                todaySchedule: result.todaySchedule,
                tomorrowSchedule: result.tomorrowSchedule,
                queueName: queueName,
                nextEventText: ScheduleText.nextEvent(timeline: dayTimeline, now: date, use24h: use24h, locale: .current),
                use24h: use24h,
                isPlaceholder: false,
                errorMessage: nil
            )
        }
        return Timeline(entries: entries, policy: .after(now.addingTimeInterval(Self.reloadInterval)))
    }
}
