import Foundation

/// Top-level JSON response from the Вінницяобленерго schedule API.
public struct ScheduleResponse: Codable, Sendable {
    public let regionId: String
    public let lastUpdated: Int
    public let fact: FactData
    public let preset: Preset

    public init(regionId: String, lastUpdated: Int, fact: FactData, preset: Preset) {
        self.regionId = regionId
        self.lastUpdated = lastUpdated
        self.fact = fact
        self.preset = preset
    }
}

/// Actual outage schedule data keyed by day timestamp, then GPV queue, then hour slot.
public struct FactData: Codable, Sendable {
    /// `[dayTimestamp: [gpvKey: [hourSlot: status]]]`
    public let data: [String: [String: [String: String]]]
    public let update: String
    public let today: Int

    public init(data: [String: [String: [String: String]]], update: String, today: Int) {
        self.data = data
        self.update = update
        self.today = today
    }
}

/// Metadata about available queues and schedule update times.
public struct Preset: Codable, Sendable {
    public let days: [String: String]?
    public let sch_names: [String: String]
    public let updateFact: String

    public init(days: [String: String]?, sch_names: [String: String], updateFact: String) {
        self.days = days
        self.sch_names = sch_names
        self.updateFact = updateFact
    }
}
