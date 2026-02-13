import Foundation

/// Persisted user preferences.
struct AppConfig: Codable {
    /// Selected disconnection queue, e.g. `"2.1"`. Empty when not yet chosen.
    var selectedQueue: String
    /// Whether to display times in 24-hour format. Default `true` (standard in Ukraine).
    var use24HourTime: Bool

    static let `default` = Self(selectedQueue: "", use24HourTime: true)
}
