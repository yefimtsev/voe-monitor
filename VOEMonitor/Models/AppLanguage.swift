import Foundation

/// User-selectable language override.
enum AppLanguage: String, Codable, CaseIterable {
    case system
    case en
    case uk

    /// The `Locale` corresponding to this selection, or `nil` for system default.
    var locale: Locale? {
        switch self {
        case .system: nil
        case .en: Locale(identifier: "en")
        case .uk: Locale(identifier: "uk")
        }
    }

    /// Resolved locale, falling back to `.current` for system default.
    var resolvedLocale: Locale {
        locale ?? .current
    }
}
