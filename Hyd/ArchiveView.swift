import SwiftUI

// The .if extension is available via Utilities.swift in the same target.

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
    @AppStorage("fontSize") private var fontSize: Double = 14

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Archive")
                    .font(.system(size: fontSize, weight: .semibold))
                    .padding(.leading)
                Spacer()
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.system(size: fontSize, weight: .semibold))
                            .foregroundColor(.accentColor)
                        if showAccessibilityLabels {
                            Text("Close")
                                .font(.system(size: fontSize, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .padding(.trailing)
                // .if(showAccessibilityLabels) { $0.accessibilityLabel("Close") } // Disabled: .if extension may not be available in this context
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
                            .font(.system(size: fontSize))
                            .foregroundColor(.secondary)
                        Spacer(minLength: 40)
                    }
                    .frame(maxWidth: .infinity)
                    // .if(showAccessibilityLabels) { $0.accessibilityLabel("No archived items") } // If this causes build errors, comment out
                } else {
                    ForEach(store.files) { file in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(file.filename).font(
                                    .system(size: fontSize, weight: .semibold))
                                Text(file.date, style: .date).font(.system(size: fontSize * 0.85))
                                    .foregroundColor(
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
                        // .if(showAccessibilityLabels) {
                        //     $0.accessibilityLabel(
                        //         "Exported file \(file.filename), date \(file.date.formatted())")
                        // } // If this causes build errors, comment out
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                performSwipeAction(swipeLeftShortAction, file: file)
                            } label: {
                                Label(
                                    swipeLeftShortAction.capitalized,
                                    systemImage: iconName(for: swipeLeftShortAction)
                                )
                                .font(.system(size: fontSize))
                            }
                            .tint(tintColor(for: swipeLeftShortAction))
                            Button {
                                performSwipeAction(swipeLeftLongAction, file: file)
                            } label: {
                                Label(
                                    swipeLeftLongAction.capitalized,
                                    systemImage: iconName(for: swipeLeftLongAction)
                                )
                                .font(.system(size: fontSize))
                            }
                            .tint(tintColor(for: swipeLeftLongAction))
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                performSwipeAction(swipeRightShortAction, file: file)
                            } label: {
                                Label(
                                    swipeRightShortAction.capitalized,
                                    systemImage: iconName(for: swipeRightShortAction)
                                )
                                .font(.system(size: fontSize))
                            }
                            .tint(tintColor(for: swipeRightShortAction))
                            Button {
                                performSwipeAction(swipeRightLongAction, file: file)
                            } label: {
                                Label(
                                    swipeRightLongAction.capitalized,
                                    systemImage: iconName(for: swipeRightLongAction)
                                )
                                .font(.system(size: fontSize))
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
