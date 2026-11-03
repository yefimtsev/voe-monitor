import Foundation
import UserNotifications

/// A notification planned from the timeline.
public struct PlannedNotification: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        /// Power goes off; `until` is when it comes back, if the schedule says.
        case powerOff(until: Date?)
        case powerOn
        /// Fires `AppConfig.warningMinutes` before an outage that starts at `outageStart`.
        case warning(outageStart: Date)
    }

    public let date: Date
    public let kind: Kind
}

/// Schedules local notifications ahead of time from the timeline,
/// so they fire on time even while the app is asleep or suspended.
public enum NotificationScheduler {
    /// iOS keeps at most 64 pending notifications per app.
    private static let maxPending = 60
    private static let presenter = ForegroundPresenter()

    /// Replace every pending notification with ones planned from `timeline`.
    /// Asks for permission the first time notifications are on; once answered, the request returns without a prompt.
    public static func reschedule(timeline: OutageTimeline, config: AppConfig, now: Date = .now) async {
        let center = UNUserNotificationCenter.current()
        center.delegate = presenter
        if config.notificationsEnabled {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }

        replacePending(in: center, with: plan(timeline: timeline, config: config, now: now), config: config)
    }

    /// Synchronous on purpose: with no `await` inside, two overlapping reschedules can't interleave
    /// their removes and adds. The app schedules nothing else, so removing everything is safe.
    private static func replacePending(in center: UNUserNotificationCenter, with plan: [PlannedNotification], config: AppConfig) {
        center.removeAllPendingNotificationRequests()
        for planned in plan {
            center.add(request(for: planned, config: config), withCompletionHandler: nil)
        }
    }

    /// What to notify about and when. Pure, so it can be tested without a notification center.
    public static func plan(timeline: OutageTimeline, config: AppConfig, now: Date) -> [PlannedNotification] {
        guard config.notificationsEnabled else { return [] }

        let periods = timeline.periods
        var result: [PlannedNotification] = []
        for (index, period) in periods.enumerated() where period.start > now {
            let previous = index > 0 ? periods[index - 1] : nil
            let following = index + 1 < periods.count ? periods[index + 1] : nil

            switch period.status {
            case .off:
                let until = following?.status == .on ? following?.start : nil
                result.append(PlannedNotification(date: period.start, kind: .powerOff(until: until)))
                let warningDate = period.start.addingTimeInterval(-Double(config.warningMinutes) * 60)
                if config.upcomingOutageWarning, warningDate > now {
                    result.append(PlannedNotification(date: warningDate, kind: .warning(outageStart: period.start)))
                }
            case .on where previous?.status == .off:
                result.append(PlannedNotification(date: period.start, kind: .powerOn))
            default:
                break
            }
        }
        return Array(result.sorted { $0.date < $1.date }.prefix(maxPending))
    }

    private static func request(for planned: PlannedNotification, config: AppConfig) -> UNNotificationRequest {
        let locale = config.language.resolvedLocale
        let use24h = config.use24HourTime
        let content = UNMutableNotificationContent()
        content.sound = .default

        let tag: String
        switch planned.kind {
        case .powerOff(let until):
            tag = "off"
            content.title = String(localized: "notification.power_off_title", locale: locale)
            content.body = if let until {
                String(localized: "notification.power_off_body \(KyivTime.format(until, use24h: use24h))", locale: locale)
            } else {
                String(localized: "notification.power_off_body_no_time", locale: locale)
            }
        case .powerOn:
            tag = "on"
            content.title = String(localized: "notification.power_on_title", locale: locale)
            content.body = String(localized: "notification.power_on_body", locale: locale)
        case .warning(let outageStart):
            tag = "warn"
            content.title = String(localized: "notification.warning_title", locale: locale)
            content.body = String(
                localized: "notification.warning_body \(KyivTime.format(outageStart, use24h: use24h)) \(config.warningMinutes)",
                locale: locale
            )
        }

        let calendar = KyivTime.calendar
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: planned.date)
        components.calendar = calendar
        components.timeZone = KyivTime.timeZone

        return UNNotificationRequest(
            identifier: "voe.\(tag).\(Int(planned.date.timeIntervalSince1970))",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
    }
}

/// Shows banners even while the app is frontmost (menubar popover open, iOS app in use).
private final class ForegroundPresenter: NSObject, UNUserNotificationCenterDelegate, Sendable {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
