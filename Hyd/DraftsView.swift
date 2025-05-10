import SwiftUI

struct Draft: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var bodyText: String
    var link: String
    var citation: String
    var date: Date
}

class DraftStore: ObservableObject {
    @Published var drafts: [Draft] = []
    private let storageKey = "drafts"

    init() {
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
                drafts = [
                    Draft(
                        id: UUID(),
                        title: "Test Draft",
                        bodyText: "# Hello World\nThis is a test draft for UI testing.",
                        link: "https://example.com",
                        citation: "Test Citation",
                        date: Date()
                    )
                ]
                return
            }
        #endif
        load()
    }

    func addOrUpdate(_ draft: Draft) {
        if let idx = drafts.firstIndex(where: { $0.id == draft.id }) {
            drafts[idx] = draft
        } else {
            drafts.insert(draft, at: 0)
        }
        save()
    }

    func delete(at offsets: IndexSet) {
        drafts.remove(atOffsets: offsets)
        save()
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([Draft].self, from: data)
        {
            drafts = decoded
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(drafts) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

struct DraftsView: View {
    @ObservedObject var store: DraftStore
    var onSelect: (Draft) -> Void
    @AppStorage("swipeLeftShortAction") private var swipeLeftShortAction: String = "delete"
    @AppStorage("swipeLeftLongAction") private var swipeLeftLongAction: String = "export"
    @AppStorage("swipeRightShortAction") private var swipeRightShortAction: String = "restore"
    @AppStorage("swipeRightLongAction") private var swipeRightLongAction: String = "export"
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @AppStorage("defaultAuthor") private var defaultAuthor: String = ""
    @AppStorage("defaultTags") private var defaultTags: String = ""
    @State private var previewMarkdown: String? = nil
    @Environment(\.dismiss) private var dismiss

    func exportDraft(_ draft: Draft) {
        let date = ISO8601DateFormatter().string(from: draft.date).prefix(10)
        let safeTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
        let filename = "\(date)-\(safeTitle).md"
        let yaml = """
            ---
            title: \(draft.title)
            \(draft.link.isEmpty ? "" : "link: \(draft.link)\n")\(draft.citation.isEmpty ? "" : "cited: \(draft.citation)\n")author: \(defaultAuthor)\n\(defaultTags.isEmpty ? "" : "tags: [\(defaultTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: ", "))]\n")date: \(date)\n\n---\n\n
            """
        let markdown = yaml + draft.bodyText + "\n"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        do {
            try markdown.write(to: fileURL, atomically: true, encoding: .utf8)
            shareURL = fileURL
            showShareSheet = true
        } catch {
            // Handle error
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Drafts")
                    .font(.headline)
                    .padding(.leading)
                Spacer()
                Button("Close") { dismiss() }
                    .padding(.trailing)
            }
            .frame(height: 44)
            #if os(iOS)
                .background(Color(UIColor.systemBackground))
            #else
                .background(Color(NSColor.windowBackgroundColor))
            #endif
            Divider()
            List {
                ForEach(store.drafts) { draft in
                    VStack(alignment: .leading) {
                        Text(draft.title.isEmpty ? "Untitled" : draft.title).font(.headline)
                        Text(draft.date, style: .date).font(.caption).foregroundColor(
                            .secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(draft) }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            performSwipeAction(swipeLeftShortAction, draft: draft)
                        } label: {
                            Label(
                                swipeLeftShortAction.capitalized,
                                systemImage: iconName(for: swipeLeftShortAction))
                        }
                        .tint(tintColor(for: swipeLeftShortAction))
                        Button {
                            performSwipeAction(swipeLeftLongAction, draft: draft)
                        } label: {
                            Label(
                                swipeLeftLongAction.capitalized,
                                systemImage: iconName(for: swipeLeftLongAction))
                        }
                        .tint(tintColor(for: swipeLeftLongAction))
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            performSwipeAction(swipeRightShortAction, draft: draft)
                        } label: {
                            Label(
                                swipeRightShortAction.capitalized,
                                systemImage: iconName(for: swipeRightShortAction))
                        }
                        .tint(tintColor(for: swipeRightShortAction))
                        Button {
                            performSwipeAction(swipeRightLongAction, draft: draft)
                        } label: {
                            Label(
                                swipeRightLongAction.capitalized,
                                systemImage: iconName(for: swipeRightLongAction))
                        }
                        .tint(tintColor(for: swipeRightLongAction))
                    }
                }
                .sheet(
                    isPresented: Binding<Bool>(
                        get: { previewMarkdown != nil },
                        set: { if !$0 { previewMarkdown = nil } }
                    )
                ) {
                    if let markdown = previewMarkdown {
                        PreviewView(text: markdown)
                    }
                }
            }
        }
    }

    func performSwipeAction(_ action: String, draft: Draft) {
        switch action {
        case "delete":
            if let idx = store.drafts.firstIndex(of: draft) {
                store.delete(at: IndexSet(integer: idx))
            }
        case "export":
            exportDraft(draft)
        case "restore":
            onSelect(draft)
        case "preview":
            // Prevent multiple presentations
            if previewMarkdown == nil {
                previewMarkdown = markdownForDraft(draft)
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

    func markdownForDraft(_ draft: Draft) -> String {
        let date = ISO8601DateFormatter().string(from: draft.date).prefix(10)
        let yaml = """
            ---
            title: \(draft.title)
            \(draft.link.isEmpty ? "" : "link: \(draft.link)\n")\(draft.citation.isEmpty ? "" : "cited: \(draft.citation)\n")author: \(defaultAuthor)\n\(defaultTags.isEmpty ? "" : "tags: [\(defaultTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: ", "))]\n")date: \(date)\n\n---\n\n
            """
        return yaml + draft.bodyText + "\n"
    }
}
