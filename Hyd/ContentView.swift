import SwiftUI

// Add these at the top so all types are visible in this file
// Types: ExportHistoryStore, ExportedFile, PreviewMarkdown, .reimportFile
// Extensions: .if, AppColors
// All are defined in Models.swift and Utilities.swift, which are in the same target, so no import needed.

struct ContentView: View {
    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var link: String = ""
    @State private var citation: String = ""
    @State private var optionalAuthor: String = ""
    @State private var optionalTags: String = ""
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"
    @AppStorage("defaultAuthor") private var defaultAuthor: String = ""
    @AppStorage("defaultTags") private var defaultTags: String = ""
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("showAccessibilityLabels") private var showAccessibilityLabels: Bool = false
    @StateObject private var exportHistory = ExportHistoryStore()
    @State private var showArchive = false
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Header with title and Save/Clear buttons
                    HStack {
                        Text("New Post")
                            .font(.system(size: fontSize, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: showAccessibilityLabels ? 8 : 20) {
                            Button(action: saveEntry) {
                                HStack(spacing: 4) {
                                    Image(systemName: "tray.and.arrow.down.fill")
                                        .font(.system(size: fontSize, weight: .semibold))
                                        .foregroundColor(.accentColor)
                                    if showAccessibilityLabels {
                                        Text("Save")
                                            .font(.system(size: fontSize, weight: .semibold))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(title.isEmpty || bodyText.isEmpty)
                            .if(showAccessibilityLabels) { $0.accessibilityLabel("Save") }

                            Button(action: clearForm) {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                        .font(.system(size: fontSize, weight: .semibold))
                                        .foregroundColor(.accentColor)
                                    if showAccessibilityLabels {
                                        Text("Clear")
                                            .font(.system(size: fontSize, weight: .semibold))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .if(showAccessibilityLabels) { $0.accessibilityLabel("Clear") }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                    Form {
                        Section(
                            header: Text("Title").font(.system(size: fontSize, weight: .semibold))
                        ) {
                            TextField("Enter title", text: $title)
                                .font(.system(size: fontSize))
                        }
                        Section(
                            header: Text("Body (Markdown)").font(
                                .system(size: fontSize, weight: .semibold))
                        ) {
                            TextEditor(text: $bodyText)
                                .frame(minHeight: 200)
                                .font(.system(size: fontSize))
                        }
                        Section(
                            header: Text("Optional").font(
                                .system(size: fontSize, weight: .semibold))
                        ) {
                            TextField("Link", text: $link)
                                .font(.system(size: fontSize))
                            TextField("Citation", text: $citation)
                                .font(.system(size: fontSize))
                            TextField("Author (override default)", text: $optionalAuthor)
                                .font(.system(size: fontSize))
                            TextField(
                                "Tags (override default, comma separated)", text: $optionalTags
                            )
                            .font(.system(size: fontSize))
                        }
                    }
                }
                .navigationTitle("")
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
                // Footer pinned to bottom
                VStack {
                    Spacer()
                    FooterMenuBar(
                        showArchive: $showArchive,
                        showSettings: $showSettings,
                        exportAction: exportMarkdown,
                        exportDisabled: title.isEmpty || bodyText.isEmpty
                    )
                }
            }
            .background(AppColors.background)
            .sheet(isPresented: $showShareSheet, onDismiss: cleanupExportFile) {
                if let exportURL = exportURL {
                    #if os(iOS)
                        ShareSheet(activityItems: [exportURL])
                            .transition(.opacity)
                            .animation(.easeInOut, value: showShareSheet)
                    #else
                        Text("Sharing is only available on iOS.")
                            .transition(.opacity)
                            .animation(.easeInOut, value: showShareSheet)
                    #endif
                }
            }
            .sheet(isPresented: $showArchive) {
                NavigationView {
                    ArchiveView(store: exportHistory, onSelect: loadExportedFile)
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationView {
                    SettingsView()
                }
            }
            .preferredColorScheme(
                preferredColorScheme == "light"
                    ? .light : preferredColorScheme == "dark" ? .dark : nil
            )
            .animation(.easeInOut, value: showShareSheet)
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: .reimportFile, object: nil, queue: .main
                ) { notification in
                    if let file = notification.object as? ExportedFile {
                        title = file.filename.replacingOccurrences(of: ".md", with: "").components(
                            separatedBy: "-"
                        )
                        .dropFirst().joined(separator: " ")
                        bodyText =
                            file.content.components(separatedBy: "---").last?.trimmingCharacters(
                                in: CharacterSet.whitespacesAndNewlines) ?? ""
                    }
                }
            }
        }
    }

    func exportMarkdown() {
        let date = ISO8601DateFormatter().string(from: Date()).prefix(10)
        let safeTitle = title.lowercased().replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
        let filename = "\(date)-\(safeTitle).md"
        let authorToUse = optionalAuthor.isEmpty ? defaultAuthor : optionalAuthor
        let tagsToUse = optionalTags.isEmpty ? defaultTags : optionalTags
        let markdown = """
            ---
            title: \(title)
            \(link.isEmpty ? "" : "link: \(link)\n")\(citation.isEmpty ? "" : "cited: \(citation)\n")author: \(authorToUse)\n\(tagsToUse.isEmpty ? "" : "tags: [\(tagsToUse.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: ", "))]\n")date: \(date)\n\n---\n\n
            """ + bodyText + "\n"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        do {
            try markdown.write(to: fileURL, atomically: true, encoding: .utf8)
            exportURL = fileURL
            showShareSheet = true
            // Save to export history
            let exportedFile = ExportedFile(
                id: UUID(), filename: filename, date: Date(), content: markdown)
            exportHistory.add(file: exportedFile)
        } catch {
            print("Failed to export markdown: \(error.localizedDescription)")
        }
    }

    func saveEntry() {
        let date = Date()
        let dateFormatter = ISO8601DateFormatter()
        let todayPrefix = String(dateFormatter.string(from: date).prefix(10))
        // Check if title already has a date prefix (yyyy-mm-dd-...)
        let filenameBase: String
        let datePrefix: String
        let titleNoExt = title.replacingOccurrences(of: ".md", with: "")
        let parts = titleNoExt.components(separatedBy: "-")
        let isDatePrefix =
            parts.count > 2 && parts[0].count == 4 && parts[1].count == 2 && parts[2].count == 2
            && Int(parts[0]) != nil && Int(parts[1]) != nil && Int(parts[2]) != nil
        if isDatePrefix {
            datePrefix = parts[0...2].joined(separator: "-")
            filenameBase = parts.dropFirst(3).joined(separator: "-")
        } else {
            datePrefix = todayPrefix
            filenameBase = titleNoExt.lowercased().replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
        }
        let filename = "\(datePrefix)-\(filenameBase).md"
        let authorToUse = optionalAuthor.isEmpty ? defaultAuthor : optionalAuthor
        let tagsToUse = optionalTags.isEmpty ? defaultTags : optionalTags
        let markdown = """
            ---
            title: \(title)
            \(link.isEmpty ? "" : "link: \(link)\n")\(citation.isEmpty ? "" : "cited: \(citation)\n")author: \(authorToUse)\n\(tagsToUse.isEmpty ? "" : "tags: [\(tagsToUse.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: ", "))]\n")date: \(datePrefix)\n\n---\n\n
            """ + bodyText + "\n"
        // Remove any previous file with the same filename (replace in-place if exists)
        if let idx = exportHistory.files.firstIndex(where: { $0.filename == filename }) {
            exportHistory.files[idx] = ExportedFile(
                id: exportHistory.files[idx].id,  // preserve id
                filename: filename,
                date: date,
                content: markdown
            )
        } else {
            let exportedFile = ExportedFile(
                id: UUID(), filename: filename, date: date, content: markdown)
            exportHistory.add(file: exportedFile)
        }
        clearForm()
    }

    func loadExportedFile(_ file: ExportedFile) {
        let contentParts = file.content.components(separatedBy: "---")
        if contentParts.count > 2 {
            bodyText = contentParts[2].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } else {
            bodyText = file.content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        // Improved: Only remove the date prefix (yyyy-mm-dd-) if present, and join the rest with dashes replaced by spaces
        let base = file.filename.replacingOccurrences(of: ".md", with: "")
        let regex = try? NSRegularExpression(pattern: "^\\d{4}-\\d{2}-\\d{2}-", options: [])
        let titlePart: String
        if let regex = regex,
            let match = regex.firstMatch(
                in: base, options: [], range: NSRange(location: 0, length: base.utf16.count)),
            match.range.location == 0
        {
            let startIdx = base.index(base.startIndex, offsetBy: match.range.length)
            titlePart = String(base[startIdx...])
        } else {
            titlePart = base
        }
        title = titlePart.replacingOccurrences(of: "-", with: " ")
    }

    func clearForm() {
        title = ""
        bodyText = ""
        link = ""
        citation = ""
        optionalAuthor = ""
        optionalTags = ""
    }

    func cleanupExportFile() {
        if let url = exportURL {
            try? FileManager.default.removeItem(at: url)
            exportURL = nil
        }
    }
}
