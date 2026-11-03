import Foundation
import Network
import Observation

/// Central data service: fetches the schedule, derives status and text, and schedules notifications.
///
/// Refreshes every 10 minutes on success, with backoff on failure, and right away when the network comes back.
/// Keeps the whole response (all queues), so switching queue re-parses locally instead of refetching.
@MainActor
@Observable
final class ScheduleService {
    // MARK: - State for the UI

    private(set) var currentStatus: PowerStatus = .unknown
    private(set) var todaySchedule: DaySchedule?
    private(set) var tomorrowSchedule: DaySchedule?
    private(set) var nextOutageText = ""
    private(set) var queue = ""
    private(set) var lastUpdated: Date?
    private(set) var lastError: String?
    private(set) var isLoading = false
    private(set) var fetchCount = 0
    /// Version of the latest GitHub release when it is newer than the running app.
    private(set) var availableUpdate: String?
    /// When the next retry is due after a failed fetch. The UI shows a countdown.
    private(set) var nextRetryAt: Date?

    var config: AppConfig {
        didSet {
            ConfigManager.shared.save(config)
            apply()
            if response == nil, oldValue.selectedQueue != config.selectedQueue {
                Task { await fetch() }
            }
            Task { await rescheduleNotifications() }
        }
    }

    // MARK: - Private

    /// Minimum interval between fetches triggered by opening the panel.
    private static let staleness: TimeInterval = 120
    /// Refresh interval after a successful fetch.
    private static let normalInterval: TimeInterval = 600
    /// Delays after 1, 2, 3… consecutive failures.
    private static let backoffIntervals: [TimeInterval] = [30, 60, 120, 300, 600]

    // swiftlint:disable:next force_unwrapping
    private static let releasesURL = URL(string: "https://api.github.com/repos/yefimtsev/voe-monitor/releases/latest")!

    private let fetcher = ScheduleFetcher()
    private var response: ScheduleResponse?
    private var timeline = OutageTimeline(days: [])
    private var lastFetchedAt: Date?
    private var retryCount = 0
    private var refreshTask: Task<Void, Never>?

    /// Current app version from `CFBundleShortVersionString`.
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    // MARK: - Init

    init() {
        config = ConfigManager.shared.load()
        response = fetcher.cachedResponse()
        apply()
        startRefreshLoop()
        Task { await watchNetwork() }
        Task { await tickStatus() }
        Task { await checkForUpdatesDaily() }
    }

    // MARK: - Fetching

    /// Fetch only if the last fetch was more than ``staleness`` seconds ago.
    func fetchIfStale() async {
        if let lastFetchedAt, Date().timeIntervalSince(lastFetchedAt) < Self.staleness { return }
        await fetch()
    }

    /// Fetch the latest schedule from GitHub and apply it.
    func fetch() async {
        guard !isLoading else { return }
        guard !config.selectedQueue.isEmpty else {
            lastError = String(localized: "error.no_queue")
            return
        }

        isLoading = true
        defer { isLoading = false }
        lastError = nil
        nextRetryAt = nil
        fetchCount += 1
        lastFetchedAt = Date()

        do {
            response = try await fetcher.fetchResponse()
            retryCount = 0
            apply()
            await rescheduleNotifications()
        } catch {
            lastError = error.localizedDescription
            retryCount += 1
        }
    }

    /// Retry now and reset the backoff.
    func retryNow() {
        guard !isLoading else { return }
        retryCount = 0
        startRefreshLoop()
    }

    /// Fetch, then sleep for the normal interval or the backoff delay, forever.
    private func startRefreshLoop() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                await fetch()
                let delay = retryCount == 0
                    ? Self.normalInterval
                    : Self.backoffIntervals[min(retryCount, Self.backoffIntervals.count) - 1]
                nextRetryAt = retryCount == 0 ? nil : Date().addingTimeInterval(delay)
                try? await Task.sleep(for: .seconds(delay))
            }
        }
    }

    private func watchNetwork() async {
        var wasOnline = true
        for await path in NWPathMonitor() {
            let isOnline = path.status == .satisfied
            if isOnline, !wasOnline {
                retryNow()
            } else if !isOnline {
                lastError = String(localized: "error.no_network")
            }
            wasOnline = isOnline
        }
    }

    // MARK: - Derived State

    /// Recompute status and text for the current minute. Called by the panel on open.
    func refreshCurrentStatus() {
        apply()
    }

    /// Re-parse for the current queue and moment. Cheap, so it also runs every minute and handles midnight.
    private func apply(now: Date = .now) {
        guard let response else { return }
        let result = fetcher.parse(response: response, queueId: config.selectedQueue, now: now)
        let locale = config.language.resolvedLocale

        todaySchedule = result.todaySchedule
        tomorrowSchedule = result.tomorrowSchedule
        lastUpdated = result.lastUpdated
        timeline = result.timeline
        currentStatus = timeline.status(at: now)
        nextOutageText = ScheduleText.nextEvent(timeline: timeline, now: now, use24h: config.use24HourTime, locale: locale)
        queue = config.selectedQueue.isEmpty
            ? ""
            : String(localized: "settings.queue", locale: locale) + " \(config.selectedQueue)"
    }

    private func tickStatus() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(60))
            apply()
        }
    }

    private func rescheduleNotifications() async {
        await NotificationScheduler.reschedule(timeline: timeline, config: config)
    }

    // MARK: - Update Check

    /// A menubar app runs for weeks, so check once a day, not only at launch.
    private func checkForUpdatesDaily() async {
        while !Task.isCancelled {
            await checkForUpdate()
            try? await Task.sleep(for: .seconds(86_400))
        }
    }

    /// Query GitHub Releases and set ``availableUpdate`` if a newer version exists.
    private func checkForUpdate() async {
        do {
            var request = URLRequest(url: Self.releasesURL)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            let (data, _) = try await URLSession.shared.data(for: request)
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let remote = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            if remote.compare(Self.appVersion, options: .numeric) == .orderedDescending {
                availableUpdate = remote
            }
        } catch {
            // Silent: the update check is not critical.
        }
    }
}

// MARK: - GitHub Release DTO

private struct GitHubRelease: Codable {
    let tagName: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
    }
}
