import Foundation
import UserNotifications

/// Manages local notification delivery for power status changes and upcoming outage warnings.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private static let categoryID = "powerStatusChange"

    private init() {}

    // MARK: - Permission

    /// Request notification permission. Call when user enables notifications in settings.
    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    /// Whether the user has granted notification permission at the system level.
    func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Status Change Notifications

    /// Send a notification about a power status transition.
    func sendStatusChange(from previous: PowerStatus, to current: PowerStatus, nextEventTime: String?) {
        guard let (title, body) = statusChangeContent(from: previous, to: current, nextEventTime: nextEventTime) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = Self.categoryID

        let request = UNNotificationRequest(
            identifier: "status-\(UUID().uuidString)",
            content: content,
            trigger: nil // Deliver immediately
        )
        center.add(request)
    }

    /// Send a warning notification about an upcoming outage.
    func sendUpcomingWarning(outageTime: String, minutesUntil: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.warning_title")
        content.body = String(localized: "notification.warning_body \(outageTime) \(minutesUntil)")
        content.sound = .default
        content.categoryIdentifier = Self.categoryID

        let request = UNNotificationRequest(
            identifier: "warning-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    // MARK: - Content Builder

    private func statusChangeContent(from previous: PowerStatus, to current: PowerStatus, nextEventTime: String?) -> (title: String, body: String)? {
        switch (previous, current) {
        case (.on, .off), (.partial, .off):
            let title = String(localized: "notification.power_off_title")
            let body: String
            if let time = nextEventTime {
                body = String(localized: "notification.power_off_body \(time)")
            } else {
                body = String(localized: "notification.power_off_body_no_time")
            }
            return (title, body)

        case (.on, .partial):
            return (
                String(localized: "notification.partial_started_title"),
                String(localized: "notification.partial_started_body")
            )

        case (.off, .on), (.partial, .on):
            return (
                String(localized: "notification.power_on_title"),
                String(localized: "notification.power_on_body")
            )

        case (.off, .partial):
            return (
                String(localized: "notification.partial_restored_title"),
                String(localized: "notification.partial_restored_body")
            )

        default:
            return nil
        }
    }
}
