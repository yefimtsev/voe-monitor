import Foundation

/// A disconnection queue (group) identifier, e.g. GPV2.1.
///
/// Vinnytsia region has 12 queues: GPV1.1 through GPV6.2.
struct Queue: Identifiable, Hashable {
    /// Queue number, e.g. `"2.1"`.
    let id: String

    /// API key used in the schedule data, e.g. `"GPV2.1"`.
    var gpvKey: String {
        "GPV\(id)"
    }

    /// Localized display name for the UI.
    var displayName: String {
        String(localized: "settings.queue") + " \(id)"
    }

    /// All 12 available queues.
    static let all: [Self] = [
        Self(id: "1.1"), Self(id: "1.2"),
        Self(id: "2.1"), Self(id: "2.2"),
        Self(id: "3.1"), Self(id: "3.2"),
        Self(id: "4.1"), Self(id: "4.2"),
        Self(id: "5.1"), Self(id: "5.2"),
        Self(id: "6.1"), Self(id: "6.2")
    ]
}
