import Foundation

struct AuryaOccurrence {
    let date: Date
    let moment: AuryaWidgetMoment
}
enum AuryaTimelineEngine {
    // Gregorian civil day index, independent of 23h/25h local days.
    static func dayIndex(_ date: Date, calendar: Calendar) -> Int {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let civil = utc.date(from: parts)!
        let base = utc.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        return utc.dateComponents([.day], from: base, to: civil).day!
    }
    static func occurrences(config: AuryaWidgetConfig, now: Date, calendar: Calendar, days: Int = 8) -> [AuryaOccurrence] {
        let start = calendar.startOfDay(for: now)
        var result: [AuryaOccurrence] = []
        for offset in -1...days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            for moment in config.moments {
                let match = DateComponents(hour: moment.minute / 60, minute: moment.minute % 60, second: 0)
                // Nonexistent DST time moves forward preserving minutes. Repeated time uses first occurrence.
                if let date = calendar.nextDate(after: day.addingTimeInterval(-1), matching: match,
                    matchingPolicy: .nextTimePreservingSmallerComponents, repeatedTimePolicy: .first, direction: .forward),
                    calendar.isDate(date, inSameDayAs: day) {
                    result.append(AuryaOccurrence(date: date, moment: moment))
                }
            }
        }
        return result.sorted { a, b in a.date == b.date ? a.moment.minute < b.moment.minute : a.date < b.date }
    }
    static func message(for occurrence: AuryaOccurrence, calendar: Calendar) -> AuryaWidgetMessage {
        let items = occurrence.moment.messages
        let day = dayIndex(occurrence.date, calendar: calendar)
        return items[(day % items.count + items.count) % items.count]
    }
}
