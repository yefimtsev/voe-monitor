import Foundation

/// Top-level JSON response from the Вінницяобленерго schedule API.
struct ScheduleResponse: Codable {
    let regionId: String
    let lastUpdated: Int
    let fact: FactData
    let preset: Preset
}

/// Actual outage schedule data keyed by day timestamp, then GPV queue, then hour slot.
struct FactData: Codable {
    /// `[dayTimestamp: [gpvKey: [hourSlot: status]]]`
    let data: [String: [String: [String: String]]]
    let update: String
    let today: Int
}

/// Metadata about available queues and schedule update times.
struct Preset: Codable {
    let days: [String: String]?
    let sch_names: [String: String]
    let updateFact: String
}
