# Hyd - Jekyll Companion App

Hyd is a simple, accessible note-taking and Markdown export app for macOS and iOS, designed for fast capture, easy export, and archiving of notes. All logic and UI are now in a single file: `AppMain.swift`.

## Features

- **Quick Note Capture:** Enter a title, body (Markdown), and optional metadata (link, citation, author, tags).
- **Save & Clear:** Save notes to the archive or clear the form. Save/Clear buttons are always accessible in the header.
- **Export:** Export notes as Markdown files. Exported files are saved to the archive and can be shared.
- **Archive:** View, re-import, export, or delete previous notes from the archive. Empty state messaging is shown if no notes are archived.
- **Settings:**
  - Choose light, dark, or system theme.
  - Adjust font size for all UI elements (fully accessible, including Settings).
  - Set default author and tags for new notes.
  - Configure swipe actions for archive items.
  - Toggle global accessibility labels: show/hide text labels next to icons throughout the app for improved accessibility.
- **Footer Menu:** Always visible at the bottom of the view, with Archive, Export, and Settings buttons. Button labels and spacing adapt to accessibility settings.
- **Full Accessibility:** All controls have accessibility labels (when enabled), and the UI respects user font size preferences everywhere.

## Usage

1. **Create a Note:**
   - Enter a title and body (Markdown supported).
   - Optionally add a link, citation, author, or tags.
   - Tap **Save** (or use the Save icon) to archive the note, or **Clear** to reset the form.
2. **Export:**
   - Tap the Export button in the footer to export the current note as a Markdown file. The file is saved to the archive and can be shared.
3. **Archive:**
   - Tap the Archive button in the footer to view all saved notes. Swipe or use context menus to export, re-import, or delete notes.
   - Tap a note to preview its content.
4. **Settings:**
   - Tap the Settings button in the footer to adjust theme, font size, swipe actions, and accessibility label preferences.
   - All settings are applied instantly and persist between launches.
5. **Accessibility:**
   - Enable "Accessibility Labels" in Settings to show text labels next to all icons for easier navigation with assistive technologies.
   - All UI elements scale with your chosen font size.

## Codebase

- All app logic and UI are in `Hyd/AppMain.swift`.
- No redundant files or settings remain. The codebase is streamlined for maintainability and accessibility.

## Requirements

- Xcode 14+
- Swift 5.7+
- macOS 12+ or iOS 15+

## Building & Running

1. Open `Hyd.xcodeproj` in Xcode.
2. Build and run on your Mac or iOS device/simulator.

