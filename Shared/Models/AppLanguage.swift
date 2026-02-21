import Foundation

/// User-selectable language override.
public enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case system
    case en
    case uk

    /// The `Locale` corresponding to this selection, or `nil` for system default.
    public var locale: Locale? {
        switch self {
        case .system: nil
        case .en: Locale(identifier: "en")
        case .uk: Locale(identifier: "uk")
        }
    }

    /// Resolved locale, falling back to `.current` for system default.
    public var resolvedLocale: Locale {
        locale ?? .current
    }
}
