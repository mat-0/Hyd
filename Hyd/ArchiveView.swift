import SwiftUI

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

struct ArchiveView: View {
    @ObservedObject var store: ExportHistoryStore
    var onSelect: ((ExportedFile) -> Void)? = nil
    @AppStorage("swipeLeftShortAction") private var swipeLeftShortAction: String = "delete"
    @AppStorage("swipeLeftLongAction") private var swipeLeftLongAction: String = "export"
    @AppStorage("swipeRightShortAction") private var swipeRightShortAction: String = "restore"
    @AppStorage("swipeRightLongAction") private var swipeRightLongAction: String = "export"
    @State private var selectedFile: ExportedFile?
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @State private var previewMarkdown: String? = nil
    @Environment(\.dismiss) private var dismiss

    func exportFile(_ file: ExportedFile) {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(file.filename)
        do {
            try file.content.write(to: fileURL, atomically: true, encoding: .utf8)
            shareURL = fileURL
            showShareSheet = true
        } catch {
            // Handle error
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Archive")
                    .font(.headline)
                    .padding(.leading)
                Spacer()
                Button("Close") { dismiss() }
                    .padding(.trailing)
            }
            .frame(height: 44)
            .background(Color(.systemBackground))
            Divider()
            List {
                ForEach(store.files) { file in
                    VStack(alignment: .leading) {
                        Text(file.filename).font(.headline)
                        Text(file.date, style: .date).font(.caption).foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
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
                            selectedFile = file
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
                .sheet(
                    isPresented: Binding<Bool>(
                        get: { previewMarkdown != nil },
                        set: { if !$0 { previewMarkdown = nil } }
                    ),
                    onDismiss: { previewMarkdown = nil }
                ) {
                    if let markdown = previewMarkdown {
                        PreviewView(text: markdown)
                    }
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
        .alert(item: $selectedFile) { file in
            Alert(
                title: Text(file.filename), message: Text(file.content),
                dismissButton: .default(Text("OK")))
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
            // Prevent multiple presentations and only set if nil
            if previewMarkdown == nil {
                DispatchQueue.main.async {
                    previewMarkdown = file.content
                }
            }
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
        try? file.content.write(to: fileURL, atomically: true, encoding: .utf8)
        shareURL = fileURL
        showShareSheet = true
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

extension Notification.Name {
    static let reimportFile = Notification.Name("reimportFile")
}
