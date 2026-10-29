import SwiftUI
import WidgetKit

struct AuryaEntry: TimelineEntry {
    let date: Date
    let label: String
    let text: String
    var messageId: String? = nil
    static func placeholder(_ now: Date = Date()) -> AuryaEntry {
        AuryaEntry(date: now, label: "AURYA · DEMO", text: "Configure seus quatro momentos no app.")
    }
}
struct AuryaProvider: TimelineProvider {
    func placeholder(in context: Context) -> AuryaEntry { .placeholder() }
    func getSnapshot(in context: Context, completion: @escaping (AuryaEntry) -> Void) {
        // Gallery never exposes saved content.
        completion(context.isPreview ? AuryaEntry(date: Date(), label: "AURYA · DEMO", text: "Eu tenho um propósito claro.") : entries(now: Date()).first ?? .placeholder())
    }
    func entries(now: Date) -> [AuryaEntry] {
        guard let config = try? AuryaWidgetStore.load() else { return [.placeholder(now)] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        let all = AuryaTimelineEngine.occurrences(config: config, now: now, calendar: calendar)
        guard let current = all.last(where: { $0.date <= now }) else { return [.placeholder(now)] }
        func entry(_ occurrence: AuryaOccurrence, at date: Date? = nil) -> AuryaEntry {
            AuryaEntry(date: date ?? occurrence.date, label: "DEMO · \(occurrence.moment.label)",
                text: AuryaTimelineEngine.message(for: occurrence, calendar: calendar).text,
                messageId: AuryaTimelineEngine.message(for: occurrence, calendar: calendar).id)
        }
        // Carry previous moment across midnight. No midnight-only entry or continuous updates.
        var result = [entry(current, at: now)]
        for occurrence in all where occurrence.date > now {
            let next = entry(occurrence)
            // Spring-forward may resolve two wall times to one instant; keep the later planned moment.
            if result.last?.date == next.date { result.removeLast() }
            result.append(next)
        }
        return result
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<AuryaEntry>) -> Void) {
        let rows = entries(now: Date())
        // Eight days planned ahead; no backend, notifications, Live Activity or animation.
        completion(Timeline(entries: rows, policy: rows.count > 1 ? .atEnd : .never))
    }
}
struct AuryaAccessoryView: View {
    let entry: AuryaEntry
    var content: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.label).font(.system(.caption2, design: .default).weight(.semibold)).lineLimit(1)
            Text(entry.text).font(.caption).lineLimit(3)
                .fixedSize(horizontal: false, vertical: false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .privacySensitive()
        .widgetURL(entry.messageId.flatMap { URL(string: "aurya://reflection/\($0)") })
        .transaction { $0.animation = nil }
        .accessibilityElement(children: .combine)
    }
    var body: some View {
        if #available(iOS 17.0, *) { content.containerBackground(for: .widget) { Color.clear } }
        else { content }
    }
}
@main
struct AuryaLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AuryaWidgetStore.kind, provider: AuryaProvider()) { entry in
            AuryaAccessoryView(entry: entry)
        }
        .configurationDisplayName("AURYA · quatro momentos")
        .description("Afirmações curtas no bloqueio. Demonstração; horários sujeitos ao iOS.")
        .supportedFamilies([.accessoryRectangular])
    }
}
