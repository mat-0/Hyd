import Foundation
import SwiftUI

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

// Wrapper struct for previewing markdown
struct PreviewMarkdown: Identifiable, Equatable {
    let id = UUID()
    let text: String
}

extension Notification.Name {
    static let reimportFile = Notification.Name("reimportFile")
}
