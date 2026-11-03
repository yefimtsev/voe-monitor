import Foundation
import Observation
import WidgetKit

/// Schedule service for iOS. Keeps the whole response (all queues) and shares its cache with the widget.
///
/// Status is not stored: views derive it from ``timeline`` at the time they render.
@MainActor
@Observable
final class IOSScheduleService {
    private(set) var todaySchedule: DaySchedule?
    private(set) var tomorrowSchedule: DaySchedule?
    private(set) var timeline = OutageTimeline(days: [])
    private(set) var lastError: String?
    private(set) var isLoading = false
    private(set) var lastUpdated: Date?

    var config: AppConfig {
        didSet {
            configManager.save(config)
            apply()
            WidgetCenter.shared.reloadAllTimelines()
            if response == nil, oldValue.selectedQueue != config.selectedQueue {
                Task { await fetch() }
            }
            Task { await NotificationScheduler.reschedule(timeline: timeline, config: config) }
        }
    }

    /// Minimum interval between fetches triggered by returning to the app.
    private static let staleness: TimeInterval = 120

    private let fetcher = ScheduleFetcher()
    private let configManager = SharedConfigManager()
    private var response: ScheduleResponse?
    private var lastFetchedAt: Date?

    init() {
        config = configManager.load()
        response = fetcher.cachedResponse()
        apply()
        Task { await fetch() }
    }

    func fetchIfStale() async {
        if let lastFetchedAt, Date().timeIntervalSince(lastFetchedAt) < Self.staleness { return }
        await fetch()
    }

    func fetch() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        lastError = nil
        lastFetchedAt = Date()

        do {
            response = try await fetcher.fetchResponse()
            apply()
            WidgetCenter.shared.reloadAllTimelines()
            await NotificationScheduler.reschedule(timeline: timeline, config: config)
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Re-parse for the current queue and day.
    func apply(now: Date = .now) {
        guard let response else { return }
        let result = fetcher.parse(response: response, queueId: config.selectedQueue, now: now)
        todaySchedule = result.todaySchedule
        tomorrowSchedule = result.tomorrowSchedule
        lastUpdated = result.lastUpdated
        timeline = result.timeline
    }
}
