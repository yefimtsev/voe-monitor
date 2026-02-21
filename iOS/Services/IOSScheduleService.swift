import Foundation
import SwiftUI

/// Simplified schedule service for iOS — uses ScheduleFetcher + SharedConfigManager.
@MainActor
@Observable
final class IOSScheduleService {
    var currentStatus: PowerStatus = .unknown
    var todaySchedule: DaySchedule?
    var tomorrowSchedule: DaySchedule?
    var lastError: String?
    var isLoading = false
    var lastUpdated: Date?

    var config: AppConfig {
        didSet {
            configManager.save(config)
            if oldValue.selectedQueue != config.selectedQueue {
                Task { await fetch() }
            }
        }
    }

    private let fetcher = ScheduleFetcher()
    private let configManager = SharedConfigManager()

    init() {
        config = SharedConfigManager().load()
        Task { await fetch() }
    }

    func fetch() async {
        guard !config.selectedQueue.isEmpty else {
            lastError = String(localized: "error.no_queue")
            return
        }

        isLoading = true
        lastError = nil

        do {
            let result = try await fetcher.fetchSchedule(for: config.selectedQueue)
            todaySchedule = result.todaySchedule
            tomorrowSchedule = result.tomorrowSchedule
            lastUpdated = result.lastUpdated
            currentStatus = result.currentStatus
        } catch {
            lastError = error.localizedDescription
        }

        isLoading = false
    }
}
