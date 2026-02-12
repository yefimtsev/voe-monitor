import Foundation

/// Persisted user preferences.
struct AppConfig: Codable {
    /// Selected disconnection queue, e.g. `"2.1"`. Empty when not yet chosen.
    var selectedQueue: String

    static let `default` = Self(selectedQueue: "")
}
