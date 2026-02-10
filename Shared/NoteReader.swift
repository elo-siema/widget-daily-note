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

    /// Convert Moment.js format tokens (used by Obsidian) to Swift DateFormatter tokens
    static func momentToSwift(_ moment: String) -> String {
        // Order matters: replace longer tokens first to avoid partial matches
        // Moment.js escapes literal text in []
        var result = ""
        var i = moment.startIndex
        while i < moment.endIndex {
            if moment[i] == "[" {
                // Literal text in brackets → wrap in single quotes for DateFormatter
                if let close = moment[moment.index(after: i)...].firstIndex(of: "]") {
                    result += "'"
                    result += String(moment[moment.index(after: i)..<close])
                    result += "'"
                    i = moment.index(after: close)
                    continue
                }
            }
            // Greedy match longest known token
            var matched = false
            for (token, replacement) in momentTokenMap {
                let end = moment.index(i, offsetBy: token.count, limitedBy: moment.endIndex) ?? moment.endIndex
                if moment[i..<end] == token {
                    result += replacement
                    i = end
                    matched = true
                    break
                }
            }
            if !matched {
                result += String(moment[i])
                i = moment.index(after: i)
            }
        }
        return result
    }

    // Sorted longest-first to match greedily
    private static let momentTokenMap: [(String, String)] = [
        ("YYYY", "yyyy"), ("YY", "yy"),
        ("MMMM", "MMMM"), ("MMM", "MMM"), ("MM", "MM"), ("M", "M"),
        ("DDDD", "DDD"), ("DDD", "DDD"), ("DD", "dd"), ("D", "d"),
        ("dddd", "EEEE"), ("ddd", "EEE"), ("dd", "EEEEEE"), ("d", "c"),
        ("HH", "HH"), ("H", "H"), ("hh", "hh"), ("h", "h"),
        ("mm", "mm"), ("m", "m"),
        ("ss", "ss"), ("s", "s"),
        ("A", "a"), ("a", "a"),
    ]

    static func todayFilename(for vault: VaultInfo) -> String {
        let config = dailyNotesConfig(for: vault)
        let momentFormat = config.format ?? "YYYY-MM-DD"
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = momentToSwift(momentFormat)
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
