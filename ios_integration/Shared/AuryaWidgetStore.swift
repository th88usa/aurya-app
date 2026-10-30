import Foundation

enum AuryaWidgetError: Error { case unconfiguredGroup, invalidPayload }
struct AuryaWidgetMessage: Codable { let id: String; let text: String }
struct AuryaWidgetMoment: Codable {
    let id: String
    let label: String
    let minute: Int
    let messages: [AuryaWidgetMessage]
}
struct AuryaWidgetConfig: Codable {
    let version: Int
    let locale: String
    let demo: Bool
    let moments: [AuryaWidgetMoment]
    func validate() throws {
        let ids: Set<String> = ["wake", "commute", "midday", "sleep"]
        guard version == 2, ["pt-BR", "en", "es", "zh-Hans", "ja", "ru", "fr", "it"].contains(locale), demo,
              moments.count == 4, Set(moments.map(\.id)) == ids,
              Set(moments.map(\.minute)).count == 4,
              moments.allSatisfy({ (0..<1440).contains($0.minute)
                && !$0.label.isEmpty && $0.label.count <= 40
                && !$0.messages.isEmpty && $0.messages.count <= 200
                && Set($0.messages.map(\.id)).count == $0.messages.count
                && $0.messages.allSatisfy({ !$0.id.isEmpty && !$0.text.isEmpty && $0.text.count <= 120 }) })
        else { throw AuryaWidgetError.invalidPayload }
    }
}
enum AuryaWidgetStore {
    static let kind = "AuryaLockScreen"
    static func fileURL() throws -> URL {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "AuryaAppGroup") as? String,
              group.hasPrefix("group."), !group.contains("$("),
              let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
        else { throw AuryaWidgetError.unconfiguredGroup }
        return container.appendingPathComponent("aurya-widget-v2.json")
    }
    static func decode(_ data: Data) throws -> AuryaWidgetConfig {
        guard data.count <= 65536 else { throw AuryaWidgetError.invalidPayload }
        let config = try JSONDecoder().decode(AuryaWidgetConfig.self, from: data)
        try config.validate()
        return config
    }
    static func load() throws -> AuryaWidgetConfig { try decode(Data(contentsOf: fileURL())) }
    static func save(_ data: Data) throws {
        let config = try decode(data)
        // Re-encode only the allowlisted fields: never share names, email or credentials.
        let clean = try JSONEncoder().encode(config)
        try clean.write(to: fileURL(), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
    static func clear() throws {
        let url = try fileURL()
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }
}
