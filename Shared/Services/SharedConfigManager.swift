import Foundation

/// Reads and writes ``AppConfig`` to App Group UserDefaults.
/// Used by the iOS app and widget extension to share configuration.
public final class SharedConfigManager: Sendable {
    /// The App Group identifier shared between the iOS app and widget.
    public static let appGroupID = "group.com.github.yefimtsev.VOEMonitor"

    private static let configKey = "appConfig"

    private nonisolated(unsafe) let defaults: UserDefaults

    /// Initialize with the App Group UserDefaults suite.
    /// Falls back to `.standard` if the suite is unavailable (e.g. in previews).
    public init() {
        defaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
    }

    /// Load config from App Group UserDefaults, falling back to ``AppConfig/default``.
    public func load() -> AppConfig {
        guard let data = defaults.data(forKey: Self.configKey),
              let config = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            return .default
        }
        return config
    }

    /// Persist config to App Group UserDefaults.
    public func save(_ config: AppConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: Self.configKey)
    }
}
