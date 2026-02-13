import Foundation
import SwiftUI

/// Central data service that fetches, parses and exposes the disconnection schedule.
///
/// Refreshes automatically every 10 minutes and checks for app updates on launch.
@MainActor
@Observable
final class ScheduleService {
    // MARK: - Published State

    var currentStatus: PowerStatus = .unknown
    var todaySchedule: DaySchedule?
    var tomorrowSchedule: DaySchedule?
    var lastError: String?
    var isLoading = false
    var nextOutageText = ""
    var queue = ""
    var lastUpdated: Date?
    var fetchCount = 0
    /// Semantic version string of the latest GitHub release when newer than the running app, otherwise `nil`.
    var availableUpdate: String?

    var config: AppConfig {
        didSet {
            ConfigManager.shared.save(config)
            if oldValue.selectedQueue != config.selectedQueue {
                Task { await fetch() }
            }
            if oldValue.use24HourTime != config.use24HourTime {
                updateNextOutageText()
            }
        }
    }

    // MARK: - Private

    /// Minimum interval between network fetches to avoid redundant requests.
    private static let staleness: TimeInterval = 120
    private var refreshTimer: Timer?
    private var lastFetchedAt: Date?

    // swiftlint:disable force_unwrapping
    private static let githubURL = URL(string: "https://raw.githubusercontent.com/vn-progr/gpv-voe-vinnytsia/main/data/Vinnytsiaoblenerho.json")!
    private static let releasesURL = URL(string: "https://api.github.com/repos/yefimtsev/voe-monitor/releases/latest")!
    private static let kyiv = TimeZone(identifier: "Europe/Kyiv")!
    // swiftlint:enable force_unwrapping

    /// Current app version from `CFBundleShortVersionString`.
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    // MARK: - Init

    init() {
        config = ConfigManager.shared.load()
        startAutoRefresh()
        Task {
            await fetch()
            await checkForUpdate()
        }
    }

    // MARK: - Fetching

    /// Fetch only if the last fetch was more than ``staleness`` seconds ago.
    func fetchIfStale() async {
        // swiftlint:disable:next force_unwrapping
        guard lastFetchedAt == nil || Date().timeIntervalSince(lastFetchedAt!) >= Self.staleness else { return }

        await fetch()
    }

    /// Fetch the latest schedule from GitHub and apply results.
    func fetch() async {
        guard !config.selectedQueue.isEmpty else {
            lastError = String(localized: "error.no_queue")
            return
        }

        isLoading = true
        lastError = nil
        fetchCount += 1
        lastFetchedAt = Date()

        do {
            let (data, _) = try await URLSession.shared.data(from: Self.githubURL)
            let decoded = try JSONDecoder().decode(ScheduleResponse.self, from: data)
            applyResult(decoded)
        } catch {
            lastError = error.localizedDescription
        }

        isLoading = false
    }

    /// Parse the API response and update today/tomorrow schedules.
    private func applyResult(_ response: ScheduleResponse) {
        let gpvKey = "GPV\(config.selectedQueue)"

        var days: [DaySchedule] = []

        for (timestampStr, queues) in response.fact.data {
            guard let timestamp = Int(timestampStr),
                  let hourData = queues[gpvKey] else { continue }

            let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
            let slots = (1 ... 24).map { hour -> HourSlot in
                let statusStr = hourData[String(hour)] ?? "yes"
                let status: PowerStatus = switch statusStr {
                case "yes": .on
                case "no": .off
                case "first", "second": .partial
                default: .unknown
                }
                return HourSlot(id: hour, status: status)
            }
            days.append(DaySchedule(id: timestamp, date: date, slots: slots))
        }

        days.sort { $0.id < $1.id }

        let todayTimestamp = response.fact.today
        todaySchedule = days.first { $0.id == todayTimestamp }
        tomorrowSchedule = days.first { $0.id > todayTimestamp }

        queue = String(localized: "settings.queue") + " \(config.selectedQueue)"
        lastUpdated = Date(timeIntervalSince1970: TimeInterval(response.lastUpdated))

        updateCurrentStatus()
        updateNextOutageText()
    }

    // MARK: - Status

    /// Recalculate ``currentStatus`` and ``nextOutageText`` from cached schedule data.
    func refreshCurrentStatus() {
        updateCurrentStatus()
        updateNextOutageText()
    }

    private func updateCurrentStatus() {
        guard let schedule = todaySchedule else {
            currentStatus = .unknown
            return
        }

        let kyiv = Self.kyiv
        var calendar = Calendar.current
        calendar.timeZone = kyiv
        let hour = calendar.component(.hour, from: Date())
        let slotIndex = hour + 1

        if let slot = schedule.slots.first(where: { $0.id == slotIndex }) {
            currentStatus = slot.status
        } else {
            currentStatus = .unknown
        }
    }

    private func updateNextOutageText() {
        guard let schedule = todaySchedule else {
            nextOutageText = ""
            return
        }

        let kyiv = Self.kyiv
        var calendar = Calendar.current
        calendar.timeZone = kyiv
        let currentHour = calendar.component(.hour, from: Date())
        let currentSlot = currentHour + 1
        let use24h = config.use24HourTime

        switch currentStatus {
        case .off:
            if let nextOn = schedule.slots.first(where: { $0.id > currentSlot && $0.status == .on }) {
                let time = HourSlot.formatTime(slotId: nextOn.id, use24h: use24h)
                let countdown = Self.countdownText(from: currentHour, toSlotId: nextOn.id, isTomorrow: false)
                nextOutageText = String(localized: "next.power_at \(time) \(countdown)")
            } else if let tomorrow = tomorrowSchedule,
                      let firstOn = tomorrow.slots.first(where: { $0.status == .on }) {
                let time = HourSlot.formatTime(slotId: firstOn.id, use24h: use24h)
                let countdown = Self.countdownText(from: currentHour, toSlotId: firstOn.id, isTomorrow: true)
                nextOutageText = String(localized: "next.power_tomorrow_at \(time) \(countdown)")
            } else {
                nextOutageText = ""
            }

        case .on, .partial:
            if let nextOff = schedule.slots.first(where: { $0.id > currentSlot && ($0.status == .off || $0.status == .partial) }) {
                let time = HourSlot.formatTime(slotId: nextOff.id, use24h: use24h)
                let countdown = Self.countdownText(from: currentHour, toSlotId: nextOff.id, isTomorrow: false)
                nextOutageText = String(localized: "next.outage_at \(time) \(countdown)")
            } else if let tomorrow = tomorrowSchedule,
                      let firstOff = tomorrow.slots.first(where: { $0.status == .off || $0.status == .partial }) {
                let time = HourSlot.formatTime(slotId: firstOff.id, use24h: use24h)
                let countdown = Self.countdownText(from: currentHour, toSlotId: firstOff.id, isTomorrow: true)
                nextOutageText = String(localized: "next.outage_tomorrow_at \(time) \(countdown)")
            } else {
                nextOutageText = String(localized: "next.no_outages")
            }

        case .unknown:
            nextOutageText = ""
        }
    }

    /// Build a countdown string like `"~3h"` or `"< 1h"`.
    private static func countdownText(from currentHour: Int, toSlotId: Int, isTomorrow: Bool) -> String {
        let targetHour = toSlotId - 1
        let hours: Int
        if isTomorrow {
            hours = (24 - currentHour) + targetHour
        } else {
            hours = targetHour - currentHour
        }
        if hours < 1 {
            return String(localized: "countdown.less_than_hour")
        }
        return String(localized: "countdown.hours \(hours)")
    }

    // MARK: - Update Check

    /// Query GitHub Releases API and set ``availableUpdate`` if a newer version exists.
    func checkForUpdate() async {
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
            // Silent fail — update check is non-critical
        }
    }

    // MARK: - Auto Refresh

    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.fetch()
            }
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
