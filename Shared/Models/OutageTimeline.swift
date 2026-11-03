import Foundation

/// The schedule flattened into consecutive periods of one power status, in absolute time.
///
/// Status, countdowns, notifications and widget entries all read from this,
/// so they agree on when power goes off and comes back, to the half hour.
public struct OutageTimeline: Sendable, Equatable {
    public struct Period: Sendable, Equatable {
        public let start: Date
        public let end: Date
        public let status: PowerStatus
    }

    /// Sorted by start; neighbouring periods with the same status are merged.
    public let periods: [Period]

    public init(days: [DaySchedule]) {
        let calendar = KyivTime.calendar
        var periods: [Period] = []
        for day in days.sorted(by: { $0.date < $1.date }) {
            for slot in day.slots {
                for (minute, status) in [(0, slot.firstHalf), (30, slot.secondHalf)] {
                    // shortcut: on the two DST days a Kyiv hour is missing or repeated, so periods may overlap or gap there.
                    guard let start = calendar.date(bySettingHour: slot.id - 1, minute: minute, second: 0, of: day.date) else {
                        continue
                    }
                    let end = start.addingTimeInterval(30 * 60)
                    if let last = periods.last, last.status == status, last.end == start {
                        periods[periods.count - 1] = Period(start: last.start, end: end, status: status)
                    } else {
                        periods.append(Period(start: start, end: end, status: status))
                    }
                }
            }
        }
        self.periods = periods
    }

    /// Power status at `date`, `.unknown` outside the schedule.
    public func status(at date: Date) -> PowerStatus {
        periods.first { $0.start <= date && date < $0.end }?.status ?? .unknown
    }

    /// The first period with `status` that starts after `date`.
    public func next(_ status: PowerStatus, after date: Date) -> Period? {
        periods.first { $0.start > date && $0.status == status }
    }

    /// `now`, then every Kyiv hour start and every status change before `end`, sorted and unique.
    /// These are the moments a widget must redraw: the status flips or the highlighted hour moves.
    public func refreshDates(from now: Date, until end: Date) -> [Date] {
        let calendar = KyivTime.calendar
        let firstHour = calendar.dateInterval(of: .hour, for: now)?.end ?? end
        let hourStarts = sequence(first: firstHour) { calendar.date(byAdding: .hour, value: 1, to: $0) }
            .prefix { $0 < end }
        let changes = periods.map(\.start).filter { $0 > now && $0 < end }
        return [now] + Set(hourStarts).union(changes).sorted()
    }
}
