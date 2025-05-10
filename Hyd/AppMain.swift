import Foundation
import SwiftUI

#if os(iOS)
    import UIKit
#endif

#if canImport(UniformTypeIdentifiers)
    import UniformTypeIdentifiers
#endif

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

// Shared model for exported files
struct ExportedFile: Identifiable, Codable, Equatable {
    let id: UUID
    let filename: String
    let date: Date
    let content: String
}

// Shared store for export history
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

// Shared notification name for reimport
extension Notification.Name {
    static let reimportFile = Notification.Name("reimportFile")
}

struct AppColors {
    static var background: Color {
        #if os(iOS)
            return Color(UIColor.systemBackground)
        #else
            return Color(NSColor.windowBackgroundColor)
        #endif
    }
}

// Wrapper struct for previewing markdown
struct PreviewMarkdown: Identifiable, Equatable {
    let id = UUID()
    let text: String
}

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
                Form {
                    Section(header: Text("Title")) {
                        TextField("Enter title", text: $title)
                            .font(.system(size: fontSize))
                    }
                    Section(header: Text("Body (Markdown)")) {
                        TextEditor(text: $bodyText)
                            .frame(minHeight: 200)
                            .font(.system(size: fontSize))
                    }
                    Section(header: Text("Optional")) {
                        TextField("Link", text: $link)
                            .font(.system(size: fontSize))
                        TextField("Citation", text: $citation)
                            .font(.system(size: fontSize))
                        TextField("Author (override default)", text: $optionalAuthor)
                            .font(.system(size: fontSize))
                        TextField("Tags (override default, comma separated)", text: $optionalTags)
                            .font(.system(size: fontSize))
                    }
                    Section {
                        HStack(spacing: 16) {
                            Button(action: saveEntry) {
                                if showAccessibilityLabels {
                                    Label("Save", systemImage: "tray.and.arrow.down.fill")
                                } else {
                                    Image(systemName: "tray.and.arrow.down.fill")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .controlSize(.large)
                            .font(.headline)
                            .disabled(title.isEmpty || bodyText.isEmpty)
                            .if(showAccessibilityLabels) { $0.accessibilityLabel("Save Note") }

                            Button(action: clearForm) {
                                if showAccessibilityLabels {
                                    Label("Clear", systemImage: "trash")
                                } else {
                                    Image(systemName: "trash")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .controlSize(.large)
                            .font(.headline)
                            .if(showAccessibilityLabels) { $0.accessibilityLabel("Clear Form") }
                        }
                    }
                }
                .navigationTitle("")
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
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

struct FooterMenuBar: View {
    @Binding var showArchive: Bool
    @Binding var showSettings: Bool
    let exportAction: () -> Void
    let exportDisabled: Bool
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("showAccessibilityLabels") private var showAccessibilityLabels: Bool = false

    var body: some View {
        HStack {
            Button(action: { showArchive = true }) {
                if showAccessibilityLabels {
                    Label("Archive", systemImage: "archivebox")
                        .font(.system(size: fontSize))
                } else {
                    Image(systemName: "archivebox")
                        .font(.system(size: fontSize))
                }
            }
            .if(showAccessibilityLabels) { $0.accessibilityLabel("Open Archive") }
            Spacer()
            Button(action: exportAction) {
                if showAccessibilityLabels {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.system(size: fontSize))
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: fontSize))
                }
            }
            .disabled(exportDisabled)
            .if(showAccessibilityLabels) { $0.accessibilityLabel("Export Current Note") }
            Spacer()
            Button(action: { showSettings = true }) {
                if showAccessibilityLabels {
                    Label("Settings", systemImage: "gear")
                        .font(.system(size: fontSize))
                } else {
                    Image(systemName: "gear")
                        .font(.system(size: fontSize))
                }
            }
            .if(showAccessibilityLabels) { $0.accessibilityLabel("Open Settings") }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 12)
        .background(AppColors.background)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ArchiveView (moved from ArchiveView.swift)
struct ArchiveView: View {
    @ObservedObject var store: ExportHistoryStore
    var onSelect: ((ExportedFile) -> Void)? = nil
    @AppStorage("swipeLeftShortAction") private var swipeLeftShortAction: String = "delete"
    @AppStorage("swipeLeftLongAction") private var swipeLeftLongAction: String = "export"
    @AppStorage("swipeRightShortAction") private var swipeRightShortAction: String = "restore"
    @AppStorage("swipeRightLongAction") private var swipeRightLongAction: String = "preview"
    @AppStorage("showAccessibilityLabels") private var showAccessibilityLabels: Bool = false
    @State private var selectedFile: ExportedFile?
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @State private var previewMarkdown: PreviewMarkdown? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Archive")
                    .font(.headline)
                    .padding(.leading)
                Spacer()
                Button("Close") { dismiss() }
                    .padding(.trailing)
                    .if(showAccessibilityLabels) { $0.accessibilityLabel("Close Archive") }
            }
            .frame(height: 44)
            #if os(iOS)
                .background(AppColors.background)
            #else
                .background(AppColors.background)
            #endif
            Divider()
            List {
                if store.files.isEmpty {
                    VStack(alignment: .center) {
                        Spacer(minLength: 40)
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No archived items.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Spacer(minLength: 40)
                    }
                    .frame(maxWidth: .infinity)
                    .if(showAccessibilityLabels) { $0.accessibilityLabel("No archived items") }
                } else {
                    ForEach(store.files) { file in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(file.filename).font(.headline)
                                Text(file.date, style: .date).font(.caption).foregroundColor(
                                    .secondary)
                            }
                            Spacer()
                            if file.filename.hasSuffix(".md") {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.accentColor)
                                    .imageScale(.medium)
                                    .opacity(0.85)
                            } else if file.filename.hasSuffix(".draft") {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.gray)
                                    .imageScale(.medium)
                                    .opacity(0.7)
                            } else {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.gray)
                                    .imageScale(.medium)
                                    .opacity(0.5)
                            }
                        }
                        .contentShape(Rectangle())
                        .if(showAccessibilityLabels) {
                            $0.accessibilityLabel(
                                "Exported file \(file.filename), date \(file.date.formatted())")
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                performSwipeAction(swipeLeftShortAction, file: file)
                            } label: {
                                Label(
                                    swipeLeftShortAction.capitalized,
                                    systemImage: iconName(for: swipeLeftShortAction))
                            }
                            .tint(tintColor(for: swipeLeftShortAction))
                            Button {
                                performSwipeAction(swipeLeftLongAction, file: file)
                            } label: {
                                Label(
                                    swipeLeftLongAction.capitalized,
                                    systemImage: iconName(for: swipeLeftLongAction))
                            }
                            .tint(tintColor(for: swipeLeftLongAction))
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                performSwipeAction(swipeRightShortAction, file: file)
                            } label: {
                                Label(
                                    swipeRightShortAction.capitalized,
                                    systemImage: iconName(for: swipeRightShortAction))
                            }
                            .tint(tintColor(for: swipeRightShortAction))
                            Button {
                                performSwipeAction(swipeRightLongAction, file: file)
                            } label: {
                                Label(
                                    swipeRightLongAction.capitalized,
                                    systemImage: iconName(for: swipeRightLongAction))
                            }
                            .tint(tintColor(for: swipeRightLongAction))
                        }
                        .onTapGesture {
                            if let onSelect = onSelect {
                                onSelect(file)
                            } else {
                                previewMarkdown = PreviewMarkdown(text: file.content)
                            }
                        }
                        .contextMenu {
                            Button("Export") { export(file: file) }
                            Button("Reimport") { reimport(file: file) }
                            Button(role: .destructive) {
                                delete(file: file)
                            } label: {
                                Text("Delete")
                            }
                        }
                    }
                    .onDelete(perform: store.delete)
                }
            }
        }
        .sheet(isPresented: $showShareSheet, onDismiss: { shareURL = nil }) {
            if let shareURL = shareURL {
                #if os(iOS)
                    ShareSheet(activityItems: [shareURL])
                #else
                    Text("Sharing is only available on iOS.")
                #endif
            }
        }
        .sheet(item: $previewMarkdown, onDismiss: { previewMarkdown = nil }) { markdown in
            PreviewView(text: markdown.text)
        }
    }

    func performSwipeAction(_ action: String, file: ExportedFile) {
        switch action {
        case "delete":
            delete(file: file)
        case "export":
            export(file: file)
        case "restore":
            reimport(file: file)
        case "preview":
            previewMarkdown = PreviewMarkdown(text: file.content)
        default:
            break
        }
    }

    func iconName(for action: String) -> String {
        switch action {
        case "delete": return "trash"
        case "export": return "square.and.arrow.up"
        case "restore": return "arrow.uturn.backward"
        case "preview": return "eye"
        default: return "eye"
        }
    }

    func tintColor(for action: String) -> Color {
        switch action {
        case "delete": return .red
        case "export": return .blue
        case "restore": return .green
        case "preview": return .orange
        default: return .gray
        }
    }

    func export(file: ExportedFile) {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(file.filename)
        do {
            try file.content.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
            shareURL = fileURL
            showShareSheet = true
        } catch {
            // Show an alert or print error
            print("Failed to export file: \(error.localizedDescription)")
        }
    }

    func reimport(file: ExportedFile) {
        NotificationCenter.default.post(name: .reimportFile, object: file)
    }

    func delete(file: ExportedFile) {
        if let idx = store.files.firstIndex(of: file) {
            store.files.remove(at: idx)
            store.save()
        }
    }
}

// MARK: - SettingsView (moved from SettingsView.swift)
struct SettingsView: View {
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"
    @AppStorage("defaultAuthor") private var defaultAuthor: String = ""
    @AppStorage("defaultTags") private var defaultTags: String = ""
    @AppStorage("swipeLeftShortAction") private var swipeLeftShortAction: String = "delete"
    @AppStorage("swipeLeftLongAction") private var swipeLeftLongAction: String = "restore"
    @AppStorage("swipeRightShortAction") private var swipeRightShortAction: String = "export"
    @AppStorage("swipeRightLongAction") private var swipeRightLongAction: String = "preview"
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("showAccessibilityLabels") private var showAccessibilityLabels: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.headline)
                    .padding(.leading)
                Spacer()
                Button("Close") { dismiss() }
                    .padding(.trailing)
                    .if(showAccessibilityLabels) { $0.accessibilityLabel("Close Settings") }
            }
            .frame(height: 44)
            #if os(iOS)
                .background(AppColors.background)
            #else
                .background(AppColors.background)
            #endif
            Divider()
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $preferredColorScheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .if(showAccessibilityLabels) { $0.accessibilityLabel("Theme Picker") }
                    HStack {
                        Text("Font Size")
                        Slider(value: $fontSize, in: 10...28, step: 2) {
                            Text("Font Size")
                        }
                        .if(showAccessibilityLabels) { $0.accessibilityLabel("Font Size") }
                        Text("\(Int(fontSize)) pt")
                            .frame(width: 48, alignment: .trailing)
                    }
                    Toggle("Enable Accessibility Labels", isOn: $showAccessibilityLabels)
                }
                Section(header: Text("Defaults")) {
                    TextField("Default Author", text: $defaultAuthor)
                    TextField("Default Tags (comma separated)", text: $defaultTags)
                }
                Section(header: Text("Swipe Actions")) {
                    Picker("Left Short Swipe", selection: $swipeLeftShortAction) {
                        Text("Delete").tag("delete")
                        Text("Restore").tag("restore")
                        Text("Export").tag("export")
                        Text("Preview").tag("preview")
                    }
                    Picker("Left Long Swipe", selection: $swipeLeftLongAction) {
                        Text("Delete").tag("delete")
                        Text("Restore").tag("restore")
                        Text("Export").tag("export")
                        Text("Preview").tag("preview")
                    }
                    Picker("Right Short Swipe", selection: $swipeRightShortAction) {
                        Text("Delete").tag("delete")
                        Text("Restore").tag("restore")
                        Text("Export").tag("export")
                        Text("Preview").tag("preview")
                    }
                    Picker("Right Long Swipe", selection: $swipeRightLongAction) {
                        Text("Delete").tag("delete")
                        Text("Restore").tag("restore")
                        Text("Export").tag("export")
                        Text("Preview").tag("preview")
                    }
                }
            }
        }
    }
}

// MARK: - PreviewView (moved from PreviewView.swift)
struct PreviewView: View {
    let text: String
    @AppStorage("showAccessibilityLabels") private var showAccessibilityLabels: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Preview")
                    .font(.headline)
                    .padding(.leading)
                Spacer()
                Button("Close") { dismiss() }
                    .padding(.trailing)
                    .if(showAccessibilityLabels) { $0.accessibilityLabel("Close Preview") }
            }
            .frame(height: 44)
            #if os(iOS)
                .background(AppColors.background)
            #else
                .background(AppColors.background)
            #endif
            Divider()
            ScrollView {
                Text(text)
                    .font(
                        .system(
                            size: UserDefaults.standard.double(forKey: "fontSize") == 0
                                ? 16 : UserDefaults.standard.double(forKey: "fontSize"))
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .if(showAccessibilityLabels) {
                        $0.accessibilityLabel("Previewed Markdown Content")
                    }
            }
        }
        .interactiveDismissDisabled(true)
    }
}

@main
struct HydApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
