import WidgetKit
import SwiftUI

struct NoteEntry: TimelineEntry {
    let date: Date
    let content: String
    let dateString: String
}

struct NoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> NoteEntry {
        NoteEntry(date: .now, content: "Your daily note will appear here...", dateString: NoteReader.readCachedFilename())
    }

    func getSnapshot(in context: Context, completion: @escaping (NoteEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NoteEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh at midnight for date rollover; file changes trigger reload from host app
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func makeEntry() -> NoteEntry {
        let content = NoteReader.readCached()
        let display = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return NoteEntry(
            date: .now,
            content: display.isEmpty ? "No note for today." : display,
            dateString: NoteReader.readCachedFilename()
        )
    }
}

struct DailyNoteWidgetView: View {
    var entry: NoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(.blue)
                Text(entry.dateString)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Divider()

            Text(entry.content)
                .font(.system(.body, design: .monospaced))
                .lineLimit(nil)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding()
        .widgetURL(URL(string: "dailynote://open?file=\(entry.dateString)")!)
    }
}

@main
struct DailyNoteWidgetBundle: Widget {
    let kind = "DailyNoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NoteProvider()) { entry in
            DailyNoteWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Note")
        .description("Today's Obsidian daily note.")
        .supportedFamilies([.systemLarge, .systemMedium, .systemSmall])
    }
}
