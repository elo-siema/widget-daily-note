import SwiftUI
import WidgetKit

@main
struct DailyNoteApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        MenuBarExtra("Daily Note", systemImage: "note.text") {
            MenuBarView(appDelegate: appDelegate)
        }
    }
}

struct MenuBarView: View {
    @ObservedObject var appDelegate: AppDelegate
    private var vaults: [VaultInfo] { NoteReader.discoverVaults() }

    var body: some View {
        if vaults.count > 1 {
            Picker("Vault", selection: Binding(
                get: { appDelegate.selectedVault?.path ?? "" },
                set: { path in
                    if let vault = vaults.first(where: { $0.path == path }) {
                        appDelegate.switchVault(vault)
                    }
                }
            )) {
                ForEach(vaults, id: \.self) { vault in
                    Text(vault.name).tag(vault.path)
                }
            }
            Divider()
        }
        Button("Open Today's Note") {
            guard let vault = appDelegate.selectedVault else { return }
            let name = vault.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? vault.name
            if let url = URL(string: "obsidian://daily?vault=\(name)") {
                NSWorkspace.shared.open(url)
            }
        }
        .keyboardShortcut("o")
        Divider()
        Button("Quit") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var eventStream: FSEventStreamRef?
    @Published var selectedVault: VaultInfo?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(handleURL(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
        selectedVault = NoteReader.selectedVault()
        NoteReader.updateCache()
        WidgetCenter.shared.reloadAllTimelines()
        startWatching()
    }

    func switchVault(_ vault: VaultInfo) {
        selectedVault = vault
        NoteReader.selectVault(vault)
        stopWatching()
        NoteReader.updateCache()
        WidgetCenter.shared.reloadAllTimelines()
        startWatching()
    }

    @objc private func handleURL(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString), url.scheme == "dailynote",
              let vault = selectedVault
        else { return }
        let name = vault.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? vault.name
        if let obsidianURL = URL(string: "obsidian://daily?vault=\(name)") {
            NSWorkspace.shared.open(obsidianURL)
        }
    }

    private func startWatching() {
        guard let vault = selectedVault else { return }
        let path = vault.path as CFString
        var context = FSEventStreamContext()
        let stream = FSEventStreamCreate(
            nil,
            { _, _, _, _, _, _ in
                NoteReader.updateCache()
                WidgetCenter.shared.reloadAllTimelines()
            },
            &context,
            [path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )!
        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(stream)
        eventStream = stream
    }

    private func stopWatching() {
        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            eventStream = nil
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopWatching()
    }
}
