import XCTest
// Add Shared/*.swift and this file to a macOS/iOS unit-test target.
final class AuryaTimelineTests: XCTestCase {
    func config(_ times: [Int] = [420,510,750,1320]) -> AuryaWidgetConfig {
        let ids = ["wake","commute","midday","sleep"]
        return AuryaWidgetConfig(version: 2, locale: "pt-BR", demo: true,
            moments: ids.enumerated().map { i, id in
                AuryaWidgetMoment(id: id, label: id, minute: times[i], messages: [
                    AuryaWidgetMessage(id: id + "-1", text: "Eu tenho um propósito claro."),
                    AuryaWidgetMessage(id: id + "-2", text: "Eu confio em mim e ajo com decisão.")])
            })
    }
    var calendar: Calendar {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "America/Los_Angeles")!; return c
    }
    func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year:y,month:m,day:d,hour:h,minute:minute))!
    }
    func testMidnightCarriesPreviousOccurrence() throws {
        let now = date(2026,10,24,0)
        let rows = AuryaTimelineEngine.occurrences(config:config(),now:now,calendar:calendar)
        let active = try XCTUnwrap(rows.last(where:{$0.date <= now}))
        XCTAssertEqual(active.moment.id,"sleep"); XCTAssertEqual(active.date,date(2026,10,23,22))
    }
    func testFourBoundariesAndNightShift() throws {
        let now = date(2026,10,23,3)
        let rows = AuryaTimelineEngine.occurrences(config:config([1200,1320,120,480]),now:now,calendar:calendar)
        XCTAssertEqual(rows.last(where:{$0.date <= now})?.moment.id,"midday")
        XCTAssertEqual(rows.filter{calendar.isDate($0.date,inSameDayAs:now)}.count,4)
    }
    func testValidationRejectsDuplicates() {
        XCTAssertThrowsError(try config([420,420,750,1320]).validate())
        XCTAssertNoThrow(try config().validate())
    }
    func testPayloadRejectsRealAccountOrUnsupportedLocale() {
        let valid = config()
        let real = AuryaWidgetConfig(version: 2, locale: "pt-BR", demo: false, moments: valid.moments)
        XCTAssertThrowsError(try real.validate())
        let unsupported = AuryaWidgetConfig(version: 2, locale: "ja", demo: true, moments: valid.moments)
        XCTAssertThrowsError(try unsupported.validate())
    }
    func testDSTSpringAndRepeatedAutumnHour() throws {
        let spring = date(2026,3,8,0)
        let a = try XCTUnwrap(AuryaTimelineEngine.occurrences(config:config([150,510,750,1320]),now:spring,calendar:calendar).first{
            $0.moment.id == "wake" && calendar.isDate($0.date,inSameDayAs:spring)})
        XCTAssertEqual(calendar.component(.hour,from:a.date),3); XCTAssertEqual(calendar.component(.minute,from:a.date),30)
        let fall = date(2026,11,1,0)
        let b = try XCTUnwrap(AuryaTimelineEngine.occurrences(config:config([90,510,750,1320]),now:fall,calendar:calendar).first{
            $0.moment.id == "wake" && calendar.isDate($0.date,inSameDayAs:fall)})
        XCTAssertEqual(calendar.timeZone.secondsFromGMT(for:b.date),-7*3600)
    }
}
