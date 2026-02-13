import Foundation

/// Persisted user preferences.
///
/// Uses a custom `Decodable` initialiser so that new fields can be added
/// without breaking existing config files on disk.
struct AppConfig: Codable {
    /// Selected disconnection queue, e.g. `"2.1"`. Empty when not yet chosen.
    var selectedQueue: String
    /// Whether to display times in 24-hour format. Default `true` (standard in Ukraine).
    var use24HourTime: Bool
    /// Whether power status change notifications are enabled.
    var notificationsEnabled: Bool
    /// Whether to warn before an upcoming outage.
    var upcomingOutageWarning: Bool
    /// Minutes before outage to fire the warning notification.
    var warningMinutes: Int
    /// In-app language override.
    var language: AppLanguage

    static let `default` = Self(
        selectedQueue: "",
        use24HourTime: true,
        notificationsEnabled: false,
        upcomingOutageWarning: true,
        warningMinutes: 30,
        language: .system
    )

    init(
        selectedQueue: String,
        use24HourTime: Bool,
        notificationsEnabled: Bool = false,
        upcomingOutageWarning: Bool = true,
        warningMinutes: Int = 30,
        language: AppLanguage = .system
    ) {
        self.selectedQueue = selectedQueue
        self.use24HourTime = use24HourTime
        self.notificationsEnabled = notificationsEnabled
        self.upcomingOutageWarning = upcomingOutageWarning
        self.warningMinutes = warningMinutes
        self.language = language
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedQueue = try container.decodeIfPresent(String.self, forKey: .selectedQueue) ?? Self.default.selectedQueue
        use24HourTime = try container.decodeIfPresent(Bool.self, forKey: .use24HourTime) ?? Self.default.use24HourTime
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? Self.default.notificationsEnabled
        upcomingOutageWarning = try container.decodeIfPresent(Bool.self, forKey: .upcomingOutageWarning) ?? Self.default.upcomingOutageWarning
        warningMinutes = try container.decodeIfPresent(Int.self, forKey: .warningMinutes) ?? Self.default.warningMinutes
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? Self.default.language
    }
}
