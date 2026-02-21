import Foundation

/// Pure data-fetching and parsing logic for the VOE schedule.
/// Stateless and Sendable — safe to use from widgets, iOS app, and macOS app.
public struct ScheduleFetcher: Sendable {

    /// The community-maintained data source URL.
    public static let dataURL = URL(string: "https://raw.githubusercontent.com/vn-progr/gpv-voe-vinnytsia/main/data/Vinnytsiaoblenerho.json")!

    /// Kyiv timezone used for all schedule calculations.
    public static let kyivTimeZone = TimeZone(identifier: "Europe/Kyiv")!

    /// Result of a schedule fetch for a specific queue.
    public struct FetchResult: Sendable {
        public let todaySchedule: DaySchedule?
        public let tomorrowSchedule: DaySchedule?
        public let lastUpdated: Date
        public let currentStatus: PowerStatus

        public init(todaySchedule: DaySchedule?, tomorrowSchedule: DaySchedule?, lastUpdated: Date, currentStatus: PowerStatus) {
            self.todaySchedule = todaySchedule
            self.tomorrowSchedule = tomorrowSchedule
            self.lastUpdated = lastUpdated
            self.currentStatus = currentStatus
        }
    }

    public init() {}

    /// Fetch the schedule for the given queue ID (e.g. "2.1").
    public func fetchSchedule(for queueId: String) async throws -> FetchResult {
        let (data, _) = try await URLSession.shared.data(from: Self.dataURL)
        let decoded = try JSONDecoder().decode(ScheduleResponse.self, from: data)
        return parse(response: decoded, queueId: queueId)
    }

    /// Parse a ScheduleResponse into a FetchResult for the given queue.
    public func parse(response: ScheduleResponse, queueId: String) -> FetchResult {
        let gpvKey = "GPV\(queueId)"

        var days: [DaySchedule] = []

        for (timestampStr, queues) in response.fact.data {
            guard let timestamp = Int(timestampStr),
                  let hourData = queues[gpvKey] else { continue }

            let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
            let slots = (1...24).map { hour -> HourSlot in
                let statusStr = hourData[String(hour)] ?? "yes"
                let status: PowerStatus = switch statusStr {
                case "yes": .on
                case "no": .off
                case "first", "second": .partial
                default: .unknown
                }
                return HourSlot(id: hour, status: status)
            }
            days.append(DaySchedule(id: timestamp, date: date, slots: slots))
        }

        days.sort { $0.id < $1.id }

        let todayTimestamp = response.fact.today
        let today = days.first { $0.id == todayTimestamp }
        let tomorrow = days.first { $0.id > todayTimestamp }
        let lastUpdated = Date(timeIntervalSince1970: TimeInterval(response.lastUpdated))
        let currentStatus = Self.currentStatus(from: today, at: Date())

        return FetchResult(
            todaySchedule: today,
            tomorrowSchedule: tomorrow,
            lastUpdated: lastUpdated,
            currentStatus: currentStatus
        )
    }

    /// Determine the current power status from a day schedule at the given date.
    public static func currentStatus(from schedule: DaySchedule?, at date: Date) -> PowerStatus {
        guard let schedule else { return .unknown }

        var calendar = Calendar.current
        calendar.timeZone = kyivTimeZone
        let hour = calendar.component(.hour, from: date)
        let slotIndex = hour + 1

        if let slot = schedule.slots.first(where: { $0.id == slotIndex }) {
            return slot.status
        }
        return .unknown
    }
}
