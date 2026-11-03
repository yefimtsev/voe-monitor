import Foundation

/// The parts of the community schedule JSON that the app reads.
/// Everything else in the file is ignored, so new or dropped fields there can't break decoding.
public struct ScheduleResponse: Codable, Sendable {
    /// Unix time of the last successful scrape.
    public let lastUpdated: Int
    public let fact: FactData
}

/// Outage schedule keyed by day timestamp, then GPV queue, then hour slot.
public struct FactData: Codable, Sendable {
    /// `[dayTimestamp: [gpvKey: [hourSlot: status]]]`
    public let data: [String: [String: [String: String]]]
}
