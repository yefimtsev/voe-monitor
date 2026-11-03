import Foundation

/// Fetches, caches and parses the community schedule JSON.
/// Stateless and Sendable — safe to use from widgets, iOS app, and macOS app.
public struct ScheduleFetcher: Sendable {

    /// The community-maintained data source URL.
    // swiftlint:disable:next force_unwrapping
    public static let dataURL = URL(string: "https://raw.githubusercontent.com/vn-progr/gpv-voe-vinnytsia/main/data/Vinnytsiaoblenerho.json")!

    /// Schedule for one queue, as of a given moment.
    public struct FetchResult: Sendable {
        public let todaySchedule: DaySchedule?
        public let tomorrowSchedule: DaySchedule?
        public let lastUpdated: Date

        public var timeline: OutageTimeline {
            OutageTimeline(days: [todaySchedule, tomorrowSchedule].compactMap { $0 })
        }
    }

    private let cacheURL: URL

    public init(cacheURL: URL = Self.defaultCacheURL) {
        self.cacheURL = cacheURL
    }

    /// iOS: the App Group container, so the widget reads what the app fetched.
    /// macOS: Caches. The app has no App Group, and touching a group container there triggers a privacy prompt.
    public static var defaultCacheURL: URL {
        #if os(iOS)
        if let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedConfigManager.appGroupID) {
            return group.appending(path: "schedule.json")
        }
        #endif
        return URL.cachesDirectory.appending(path: "VOEMonitor/schedule.json")
    }

    /// Download the schedule for all queues and cache it.
    public func fetchResponse() async throws -> ScheduleResponse {
        let (data, response) = try await URLSession.shared.data(from: Self.dataURL)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(ScheduleResponse.self, from: data)
        // Written only after decoding, so a broken response never replaces a good cache.
        try? FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: cacheURL, options: .atomic)
        return decoded
    }

    /// The last schedule that ``fetchResponse()`` downloaded, if any.
    public func cachedResponse() -> ScheduleResponse? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder().decode(ScheduleResponse.self, from: data)
    }

    /// Pick the given queue's today and tomorrow, where "today" is the Kyiv date of `now`.
    ///
    /// Uses `now` rather than the file's own idea of today, so a cached file from
    /// before midnight still shows the right day.
    public func parse(response: ScheduleResponse, queueId: String, now: Date = .now) -> FetchResult {
        let gpvKey = Queue(id: queueId).gpvKey
        let calendar = KyivTime.calendar

        let days: [DaySchedule] = response.fact.data.compactMap { timestampStr, queues in
            guard let timestamp = Int(timestampStr), let hourData = queues[gpvKey] else { return nil }
            let slots = (1...24).map { HourSlot(id: $0, apiStatus: hourData[String($0)] ?? "yes") }
            return DaySchedule(id: timestamp, date: Date(timeIntervalSince1970: TimeInterval(timestamp)), slots: slots)
        }

        let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        return FetchResult(
            todaySchedule: days.first { calendar.isDate($0.date, inSameDayAs: now) },
            tomorrowSchedule: days.first { calendar.isDate($0.date, inSameDayAs: tomorrowDate) },
            lastUpdated: Date(timeIntervalSince1970: TimeInterval(response.lastUpdated))
        )
    }
}
