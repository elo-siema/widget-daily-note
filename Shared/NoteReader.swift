import Foundation

struct VaultInfo: Codable, Hashable {
    let path: String
    var name: String { URL(fileURLWithPath: path).lastPathComponent }
}

struct DailyNotesConfig: Codable {
    var folder: String?
    var format: String?
}

struct NoteReader {
    private static let home = NSHomeDirectory()
    private static let isWidget = Bundle.main.bundleIdentifier == "com.user.DailyNote.DailyNoteWidget"
    private static var containerDir: String {
        isWidget ? home : "\(home)/Library/Containers/com.user.DailyNote.DailyNoteWidget/Data"
    }
    static let obsidianConfigURL = URL(fileURLWithPath: "\(home)/Library/Application Support/obsidian/obsidian.json")
    static var cacheFile: URL { URL(fileURLWithPath: "\(containerDir)/note.txt") }
    static var selectedVaultFile: URL { URL(fileURLWithPath: "\(containerDir)/vault.txt") }

    static func discoverVaults() -> [VaultInfo] {
        guard let data = try? Data(contentsOf: obsidianConfigURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let vaults = json["vaults"] as? [String: [String: Any]]
        else { return [] }
        return vaults.compactMap { (_, info) in
            (info["path"] as? String).map { VaultInfo(path: $0) }
        }.sorted { $0.name < $1.name }
    }

    static func selectedVault() -> VaultInfo? {
        if let saved = try? String(contentsOf: selectedVaultFile, encoding: .utf8),
           discoverVaults().contains(where: { $0.path == saved }) {
            return VaultInfo(path: saved)
        }
        return discoverVaults().first
    }

    static func selectVault(_ vault: VaultInfo) {
        try? vault.path.write(to: selectedVaultFile, atomically: true, encoding: .utf8)
    }

    static func dailyNotesConfig(for vault: VaultInfo) -> DailyNotesConfig {
        let configURL = URL(fileURLWithPath: vault.path)
            .appendingPathComponent(".obsidian/daily-notes.json")
        guard let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(DailyNotesConfig.self, from: data)
        else { return DailyNotesConfig() }
        return config
    }

    static func todayFilename(for vault: VaultInfo) -> String {
        let config = dailyNotesConfig(for: vault)
        let fmt = DateFormatter()
        fmt.dateFormat = config.format ?? "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    static func todayFilename() -> String {
        guard let vault = selectedVault() else { return DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none) }
        return todayFilename(for: vault)
    }

    static func readVault() -> String {
        guard let vault = selectedVault() else { return "" }
        let config = dailyNotesConfig(for: vault)
        let folder = config.folder ?? ""
        let filename = todayFilename(for: vault)
        var fileURL = URL(fileURLWithPath: vault.path)
        if !folder.isEmpty { fileURL.appendPathComponent(folder) }
        fileURL.appendPathComponent("\(filename).md")
        return (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
    }

    static func updateCache() {
        try? readVault().write(to: cacheFile, atomically: true, encoding: .utf8)
    }

    static func readCached() -> String {
        (try? String(contentsOf: cacheFile, encoding: .utf8)) ?? ""
    }
}
