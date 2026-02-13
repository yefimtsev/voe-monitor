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

    static let `default` = Self(selectedQueue: "", use24HourTime: true)

    init(selectedQueue: String, use24HourTime: Bool) {
        self.selectedQueue = selectedQueue
        self.use24HourTime = use24HourTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedQueue = try container.decodeIfPresent(String.self, forKey: .selectedQueue) ?? Self.default.selectedQueue
        use24HourTime = try container.decodeIfPresent(Bool.self, forKey: .use24HourTime) ?? Self.default.use24HourTime
    }
}
