# Hyd

Hyd is a SwiftUI-based Markdown note-taking and export app for iOS and macOS. It allows you to write, preview, export, and manage Markdown notes with YAML front matter, supporting features like an archive of all entries, export history, and customizable swipe actions.

## Features

- Write and edit Markdown notes
- Save notes to the Archive with a Save button
- Export notes with YAML front matter as `.md` files
- Preview Markdown content
- Archive view for all saved and exported notes
- Customizable swipe actions for archive entries
- Settings for appearance, default author, and tags

## Requirements

- Xcode 15 or later
- Swift 5.9+
- iOS 15.0+ or macOS 12.0+

## Dependencies

- [apple/swift-markdown](https://github.com/apple/swift-markdown)
- [swiftlang/swift-cmark](https://github.com/swiftlang/swift-cmark)

Dependencies are managed via Swift Package Manager and are already included in the project.

## Getting Started

1. **Clone the repository:**

   ```bash
   git clone <your-repo-url>
   cd Hyd
   ```

2. **Open the project in Xcode:**
   - Open `Hyd.xcodeproj` in Xcode.
3. **Build and run:**
   - Select the desired simulator or your device.
   - Press `Cmd+R` to build and run the app.

## Usage

- **Write notes:** Use the main editor to write Markdown notes. Title, body, link, and citation fields are available.
- **Save:** Tap the Save button (tray icon) to add your note to the Archive.
- **Export:** Tap the export button to save your note as a Markdown file with YAML front matter.
- **Archive:** All saved and exported notes appear in the Archive. Exported items are marked with a tick.
- **Settings:** Customize appearance, default author/tags, and swipe actions.

## Project Structure

- `Hyd/` — Main SwiftUI source files
- `Hyd.xcodeproj/` — Xcode project files
- `Assets.xcassets/` — App icons and color assets

## License

This project is for personal use. See LICENSE file if present.
