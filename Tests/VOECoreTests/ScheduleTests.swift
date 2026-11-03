import Foundation
import Testing
@testable import VOECore

/// Fixture: the real schedule for 2026-11-03 (Kyiv), fetched at 18:58.
/// Queue 2.1: off 07:00–10:00 and 14:00–16:00. Queue 2.2 also: off 18:00–18:30 (`first`) and 20:00–22:00.
/// Tomorrow (2026-11-04) is all `yes` for both.
private let response: ScheduleResponse = {
    let url = Bundle.module.url(forResource: "Fixtures/schedule-2026-11-03", withExtension: "json")!
    return try! JSONDecoder().decode(ScheduleResponse.self, from: Data(contentsOf: url))
}()

/// Kyiv midnight of 2026-11-03 (UTC+2).
private let todayMidnight = Date(timeIntervalSince1970: 1_793_656_800)

private func kyiv(_ hour: Int, _ minute: Int = 0, dayOffset: Int = 0) -> Date {
    todayMidnight.addingTimeInterval(TimeInterval(dayOffset * 86_400 + hour * 3_600 + minute * 60))
}

private func timeline(_ queue: String, at now: Date) -> OutageTimeline {
    ScheduleFetcher().parse(response: response, queueId: queue, now: now).timeline
}

private let enLocale = Locale(identifier: "en")

@Suite struct ParsingTests {
    @Test func picksTodayAndTomorrowByKyivDate() {
        let result = ScheduleFetcher().parse(response: response, queueId: "2.1", now: kyiv(12))
        #expect(result.todaySchedule?.id == 1_793_656_800)
        #expect(result.tomorrowSchedule?.id == 1_793_743_200)
        #expect(result.todaySchedule?.slots.count == 24)
    }

    @Test func cachedFileAfterMidnightShiftsToday() {
        let result = ScheduleFetcher().parse(response: response, queueId: "2.1", now: kyiv(0, 30, dayOffset: 1))
        #expect(result.todaySchedule?.id == 1_793_743_200)
        #expect(result.tomorrowSchedule == nil)
    }

    @Test func unknownQueueHasNoDays() {
        let result = ScheduleFetcher().parse(response: response, queueId: "", now: kyiv(12))
        #expect(result.todaySchedule == nil)
        #expect(result.timeline.periods.isEmpty)
    }

    @Test(arguments: [
        ("yes", PowerStatus.on, PowerStatus.on),
        ("no", .off, .off),
        ("first", .off, .on),
        ("second", .on, .off),
        ("garbage", .unknown, .unknown),
    ])
    func apiStatusMapsToHalves(api: String, first: PowerStatus, second: PowerStatus) {
        let slot = HourSlot(id: 1, apiStatus: api)
        #expect(slot.firstHalf == first)
        #expect(slot.secondHalf == second)
    }

    @Test func halfHourSlotSummarisesAsPartial() {
        let slot = ScheduleFetcher().parse(response: response, queueId: "2.2", now: kyiv(12)).todaySchedule?.slots[18]
        #expect(slot?.status == .partial)
    }

    @Test func cacheRoundTripsTheDownloadedFile() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "voe-\(UUID().uuidString)/schedule.json")
        let fetcher = ScheduleFetcher(cacheURL: url)
        #expect(fetcher.cachedResponse() == nil)

        let fixture = Bundle.module.url(forResource: "Fixtures/schedule-2026-11-03", withExtension: "json")!
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: fixture, to: url)
        #expect(fetcher.cachedResponse()?.lastUpdated == response.lastUpdated)
    }
}

@Suite struct TimelineTests {
    @Test func mergesNeighbouringHalves() {
        let off = timeline("2.1", at: kyiv(12)).periods.filter { $0.status == .off }
        #expect(off.map(\.start) == [kyiv(7), kyiv(14)])
        #expect(off.map(\.end) == [kyiv(10), kyiv(16)])
    }

    @Test func todayAndTomorrowJoinIntoOnePeriodAcrossMidnight() {
        let last = timeline("2.1", at: kyiv(12)).periods.last
        #expect(last?.start == kyiv(16))
        #expect(last?.end == kyiv(0, dayOffset: 2))
    }

    @Test func statusFollowsTheHalfHour() {
        let timeline = timeline("2.2", at: kyiv(12))
        #expect(timeline.status(at: kyiv(17, 59)) == .on)
        #expect(timeline.status(at: kyiv(18, 15)) == .off)
        #expect(timeline.status(at: kyiv(18, 30)) == .on)
    }

    @Test func outsideTheScheduleIsUnknown() {
        #expect(timeline("2.1", at: kyiv(12)).status(at: kyiv(1, dayOffset: 3)) == .unknown)
    }

    @Test func refreshDatesHitEveryHourAndHalfHourChangeOnce() {
        let dates = timeline("2.2", at: kyiv(6, 10)).refreshDates(from: kyiv(6, 10), until: kyiv(6, 10, dayOffset: 1))
        #expect(dates.first == kyiv(6, 10))
        #expect(dates == dates.sorted())
        #expect(Set(dates).count == dates.count)
        #expect(dates.filter { $0 == kyiv(7) }.count == 1)
        #expect(dates.contains(kyiv(18, 30)))
        #expect(dates.contains(kyiv(6, dayOffset: 1)))
        #expect(dates.last! < kyiv(6, 10, dayOffset: 1))
    }

    @Test func nextFindsTheNextPeriodWithStatus() {
        let timeline = timeline("2.1", at: kyiv(8))
        #expect(timeline.next(.on, after: kyiv(8))?.start == kyiv(10))
        #expect(timeline.next(.off, after: kyiv(8))?.start == kyiv(14))
        #expect(timeline.next(.off, after: kyiv(16)) == nil)
    }
}

@Suite struct TextTests {
    @Test func formatsKyivTime() {
        #expect(KyivTime.format(kyiv(14, 5), use24h: true) == "14:05")
        #expect(KyivTime.format(kyiv(14, 5), use24h: false) == "2:05 PM")
        #expect(KyivTime.format(kyiv(0, 30), use24h: false) == "12:30 AM")
    }

    @Test func countdownRoundsDownToMinutes() {
        #expect(ScheduleText.countdown(from: kyiv(6, 10), to: kyiv(7), locale: enLocale).contains("50"))
        let thirtySecondsBefore = kyiv(7).addingTimeInterval(-30)
        #expect(ScheduleText.countdown(from: thirtySecondsBefore, to: kyiv(7), locale: enLocale)
            == String(localized: "countdown.less_than_minute", locale: enLocale))
    }

    @Test func nextEventWhileOnPointsAtTheOutage() {
        let text = ScheduleText.nextEvent(timeline: timeline("2.1", at: kyiv(6)), now: kyiv(6, 10), use24h: true, locale: enLocale)
        #expect(text.contains("07:00"))
    }

    @Test func nextEventWhileOffPointsAtRestoration() {
        let text = ScheduleText.nextEvent(timeline: timeline("2.2", at: kyiv(18)), now: kyiv(18, 10), use24h: true, locale: enLocale)
        #expect(text.contains("18:30"))
    }

    @Test func noOutagesLeftIsNotEmpty() {
        let text = ScheduleText.nextEvent(timeline: timeline("2.1", at: kyiv(17)), now: kyiv(17), use24h: true, locale: enLocale)
        #expect(!text.isEmpty)
        #expect(!text.contains(":"))
    }
}

@Suite struct NotificationPlanTests {
    private func config(warning: Bool = true, minutes: Int = 30) -> AppConfig {
        AppConfig(selectedQueue: "2.1", use24HourTime: true, notificationsEnabled: true, upcomingOutageWarning: warning, warningMinutes: minutes)
    }

    @Test func plansOffOnAndWarnings() {
        let plan = NotificationScheduler.plan(timeline: timeline("2.1", at: kyiv(6)), config: config(), now: kyiv(6))
        #expect(plan == [
            PlannedNotification(date: kyiv(6, 30), kind: .warning(outageStart: kyiv(7))),
            PlannedNotification(date: kyiv(7), kind: .powerOff(until: kyiv(10))),
            PlannedNotification(date: kyiv(10), kind: .powerOn),
            PlannedNotification(date: kyiv(13, 30), kind: .warning(outageStart: kyiv(14))),
            PlannedNotification(date: kyiv(14), kind: .powerOff(until: kyiv(16))),
            PlannedNotification(date: kyiv(16), kind: .powerOn),
        ])
    }

    @Test func skipsWarningsAlreadyInThePast() {
        let plan = NotificationScheduler.plan(timeline: timeline("2.1", at: kyiv(6, 45)), config: config(), now: kyiv(6, 45))
        #expect(plan.first == PlannedNotification(date: kyiv(7), kind: .powerOff(until: kyiv(10))))
    }

    @Test func noWarningsWhenTurnedOff() {
        let plan = NotificationScheduler.plan(timeline: timeline("2.1", at: kyiv(6)), config: config(warning: false), now: kyiv(6))
        #expect(!plan.contains { if case .warning = $0.kind { true } else { false } })
    }

    @Test func nothingWhenNotificationsDisabled() {
        var disabled = config()
        disabled.notificationsEnabled = false
        #expect(NotificationScheduler.plan(timeline: timeline("2.1", at: kyiv(6)), config: disabled, now: kyiv(6)).isEmpty)
    }

    @Test func halfHourOutageGetsItsOwnPair() {
        let plan = NotificationScheduler.plan(timeline: timeline("2.2", at: kyiv(17)), config: config(warning: false), now: kyiv(17))
        #expect(plan.prefix(2) == [
            PlannedNotification(date: kyiv(18), kind: .powerOff(until: kyiv(18, 30))),
            PlannedNotification(date: kyiv(18, 30), kind: .powerOn),
        ])
    }
}
