//
//  ContentView.swift
//  Hyde
//
//  Created by Mat Benfield on 09/05/2025.
//

import Foundation
import SwiftUI

#if os(iOS)
    import UIKit
    typealias PlatformColor = UIColor
    let backgroundColor = Color(UIColor.systemBackground)
#else
    import AppKit
    typealias PlatformColor = NSColor
    let backgroundColor = Color(NSColor.windowBackgroundColor)
#endif
#if canImport(UniformTypeIdentifiers)
    import UniformTypeIdentifiers
#endif

struct ExportedFile: Identifiable, Codable, Equatable {
    let id: UUID
    let filename: String
    let date: Date
    let content: String
}

class ExportHistoryStore: ObservableObject {
    @Published var files: [ExportedFile] = []
    private let storageKey = "exportedFiles"

    init() {
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
                files = [
                    ExportedFile(
                        id: UUID(),
                        filename: "2025-05-10-test-export.md",
                        date: Date(),
                        content: "# Exported File\nThis is a test export for UI testing."
                    )
                ]
                return
            }
        #endif
        load()
    }

    func add(file: ExportedFile) {
        files.insert(file, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        files.remove(atOffsets: offsets)
        save()
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([ExportedFile].self, from: data)
        {
            files = decoded
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(files) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

extension Notification.Name {
    static let reimportFile = Notification.Name("reimportFile")
}

struct ContentView: View {
    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var link: String = ""
    @State private var citation: String = ""
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"
    @AppStorage("defaultAuthor") private var defaultAuthor: String = ""
    @AppStorage("defaultTags") private var defaultTags: String = ""
    @StateObject private var exportHistory = ExportHistoryStore()
    @State private var showArchive = false
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section(header: Text("Title")) {
                        TextField("Enter title", text: $title)
                    }
                    Section(header: Text("Body (Markdown)")) {
                        TextEditor(text: $bodyText)
                            .frame(minHeight: 200)
                    }
                    Section(header: Text("Optional")) {
                        TextField("Link", text: $link)
                        TextField("Citation", text: $citation)
                    }
                }
                .navigationTitle("New Post")
                VStack {
                    Spacer()
                    FooterMenuBar(
                        showArchive: $showArchive,
                        showSettings: $showSettings,
                        exportAction: exportMarkdown,
                        saveAction: saveEntry,
                        clearAction: clearForm,
                        exportDisabled: title.isEmpty || bodyText.isEmpty
                    )
                }
            }
            .background(backgroundColor)
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
        let markdown = """
            ---
            title: \(title)
            \(link.isEmpty ? "" : "link: \(link)\n")\(citation.isEmpty ? "" : "cited: \(citation)\n")author: \(defaultAuthor)\n\(defaultTags.isEmpty ? "" : "tags: [\(defaultTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: ", "))]\n")date: \(date)\n\n---\n\n
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
            // Handle error (show alert, etc.)
        }
    }

    func saveEntry() {
        let date = Date()
        let safeTitle = title.lowercased().replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
        let filename = "\(ISO8601DateFormatter().string(from: date).prefix(10))-\(safeTitle).md"
        let markdown = """
            ---
            title: \(title)
            \(link.isEmpty ? "" : "link: \(link)\n")\(citation.isEmpty ? "" : "cited: \(citation)\n")author: \(defaultAuthor)\n\(defaultTags.isEmpty ? "" : "tags: [\(defaultTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: ", "))]\n")date: \(ISO8601DateFormatter().string(from: date).prefix(10))\n\n---\n\n
            """ + bodyText + "\n"
        let exportedFile = ExportedFile(
            id: UUID(), filename: filename, date: date, content: markdown)
        exportHistory.add(file: exportedFile)
        clearForm()
    }

    func loadExportedFile(_ file: ExportedFile) {
        let contentParts = file.content.components(separatedBy: "---")
        if contentParts.count > 2 {
            // YAML front matter is between first and second '---'
            // Optionally parse YAML for link, cited, etc.
            // For now, just load the body
            bodyText = contentParts[2].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } else {
            bodyText = file.content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        title = file.filename.replacingOccurrences(of: ".md", with: "").components(separatedBy: "-")
            .dropFirst().joined(separator: " ")
    }

    func clearForm() {
        title = ""
        bodyText = ""
        link = ""
        citation = ""
    }

    func cleanupExportFile() {
        if let url = exportURL {
            try? FileManager.default.removeItem(at: url)
            exportURL = nil
        }
    }
}

struct FooterMenuBar: View {
    @Binding var showArchive: Bool
    @Binding var showSettings: Bool
    let exportAction: () -> Void
    let saveAction: () -> Void
    let clearAction: () -> Void
    let exportDisabled: Bool

    var body: some View {
        HStack {
            Button(action: { showArchive = true }) {
                Image(systemName: "archivebox")
                    .font(.title2)
            }
            Spacer()
            Button(action: saveAction) {
                Image(systemName: "tray.and.arrow.down")
                    .font(.title2)
            }
            .disabled(exportDisabled)
            Spacer()
            Button(action: exportAction) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
            }
            .disabled(exportDisabled)
            Spacer()
            Button(action: clearAction) {
                Image(systemName: "xmark.circle")
                    .font(.title2)
            }
            Spacer()
            Button(action: { showSettings = true }) {
                Image(systemName: "gear")
                    .font(.title2)
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .frame(maxWidth: .infinity)
    }
}

struct ArchiveView: View {
    @ObservedObject var store: ExportHistoryStore
    var onSelect: ((ExportedFile) -> Void)? = nil
    var body: some View {
        Text("ArchiveView placeholder")
    }
}

struct SettingsView: View {
    var body: some View {
        Text("SettingsView placeholder")
    }
}

#if os(iOS)
    struct ShareSheet: UIViewControllerRepresentable {
        var activityItems: [Any]
        var applicationActivities: [UIActivity]? = nil

        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(
                activityItems: activityItems, applicationActivities: applicationActivities)
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context)
        {}
    }
#endif
