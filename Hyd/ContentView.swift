//
//  ContentView.swift
//  Hyde
//
//  Created by Mat Benfield on 09/05/2025.
//

import SwiftUI

#if os(iOS)
    import UIKit
    typealias PlatformColor = UIColor
#else
    typealias PlatformColor = NSColor
#endif
#if canImport(UniformTypeIdentifiers)
    import UniformTypeIdentifiers
#endif

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
    @StateObject private var draftStore = DraftStore()
    @State private var currentDraftID: UUID? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showDrafts = false
    @State private var showExportHistory = false
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

                // Footer menu bar overlay
                VStack {
                    Spacer()
                    FooterMenuBar(
                        showDrafts: $showDrafts,
                        showExportHistory: $showExportHistory,
                        showSettings: $showSettings,
                        exportAction: exportMarkdown,
                        clearAction: clearForm,
                        exportDisabled: title.isEmpty || bodyText.isEmpty
                    )
                }
            }
            .background(Color(UIColor.systemBackground))
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
            .sheet(isPresented: $showDrafts) {
                NavigationView {
                    DraftsView(store: draftStore, onSelect: loadDraft)
                }
            }
            .sheet(isPresented: $showExportHistory) {
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
                                in: .whitespacesAndNewlines) ?? ""
                        // Optionally parse link/cited/author/tags from YAML if needed
                    }
                }
            }
            .onChange(of: title) { autosaveDraft() }
            .onChange(of: bodyText) { autosaveDraft() }
            .onChange(of: link) { autosaveDraft() }
            .onChange(of: citation) { autosaveDraft() }
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

    func autosaveDraft() {
        let draft = Draft(
            id: currentDraftID ?? UUID(),
            title: title,
            bodyText: bodyText,
            link: link,
            citation: citation,
            date: Date()
        )
        currentDraftID = draft.id
        draftStore.addOrUpdate(draft)
    }

    func loadDraft(_ draft: Draft) {
        title = draft.title
        bodyText = draft.bodyText
        link = draft.link
        citation = draft.citation
        currentDraftID = draft.id
        withAnimation(.easeInOut) {
            dismiss()
        }
    }

    func loadExportedFile(_ file: ExportedFile) {
        // Parse YAML front matter if needed, here we just load the content after the front matter
        let contentParts = file.content.components(separatedBy: "---")
        if contentParts.count > 2 {
            // YAML front matter is between first and second '---'
            let yaml = contentParts[1]
            // Optionally parse YAML for link, cited, etc.
            // For now, just load the body
            bodyText = contentParts[2].trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            bodyText = file.content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        title = file.filename.replacingOccurrences(of: ".md", with: "").components(separatedBy: "-")
            .dropFirst().joined(separator: " ")
        // Optionally parse link/cited/author/tags from YAML if needed
        // Clear draft id so this is not autosaved as a draft unless edited
        currentDraftID = nil
        withAnimation(.easeInOut) {
            dismiss()
        }
    }

    func clearForm() {
        title = ""
        bodyText = ""
        link = ""
        citation = ""
        currentDraftID = nil
    }

    func cleanupExportFile() {
        if let url = exportURL {
            try? FileManager.default.removeItem(at: url)
            exportURL = nil
        }
    }
}

struct FooterMenuBar: View {
    @Binding var showDrafts: Bool
    @Binding var showExportHistory: Bool
    @Binding var showSettings: Bool
    let exportAction: () -> Void
    let clearAction: () -> Void
    let exportDisabled: Bool

    var body: some View {
        HStack {
            Button(action: { showDrafts = true }) {
                Image(systemName: "doc.text")
                    .font(.title2)
            }
            Spacer()
            Button(action: { showExportHistory = true }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
            }
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
        .background(
            VisualEffectBlur(blurStyle: .systemMaterial)
                .edgesIgnoringSafeArea(.bottom)
        )
        .frame(maxWidth: .infinity)
    }
}

// VisualEffectBlur for background blur (iOS 15+)
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
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
