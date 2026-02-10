# Obsidian Daily Note Widget for macOS

<img width="378" height="370" alt="image" src="https://github.com/user-attachments/assets/9a326b6d-871d-438a-8209-d26d4c343774" />

---

A macOS menu bar app and widget that displays today's Obsidian daily note on your desktop.

## Features

- Auto-discovers Obsidian vaults and daily notes configuration
- Widget updates in real-time as you edit your note
- Click the widget to open the note in Obsidian
- Multiple vault support with picker in the menu bar

## Install

1. Download `DailyNote.dmg` from [Releases](https://github.com/elo-siema/widget-daily-note/releases)
2. Drag `DailyNote.app` to `/Applications`
3. Launch the app (right-click → Open the first time since it's unsigned)
4. Add the "Daily Note" widget from the macOS widget gallery

## Build from source

```
brew install xcodegen
xcodegen generate
xcodebuild -scheme DailyNote -configuration Release build
```
