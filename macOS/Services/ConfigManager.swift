import Foundation

/// Reads and writes ``AppConfig`` to the Application Support directory.
final class ConfigManager: Sendable {
    static let shared = ConfigManager()

    private let configURL: URL

    private init() {
        // swiftlint:disable:next force_unwrapping
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("VOEMonitor", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        configURL = dir.appendingPathComponent("config.json")
    }

    /// Load config from disk, falling back to ``AppConfig/default`` on failure.
    func load() -> AppConfig {
        guard let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            return .default
        }
        return config
    }

    /// Persist config to disk. Fails silently.
    func save(_ config: AppConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        try? data.write(to: configURL, options: .atomic)
    }
}
