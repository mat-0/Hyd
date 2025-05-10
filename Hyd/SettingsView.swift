//
//  SettingsView.swift
//  Hyde
//

import SwiftUI

#if os(iOS)
    import UIKit
#else

#endif
#if canImport(UniformTypeIdentifiers)
    import UniformTypeIdentifiers
#endif

struct SettingsView: View {
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"
    @AppStorage("defaultAuthor") private var defaultAuthor: String = ""
    @AppStorage("defaultTags") private var defaultTags: String = ""
    @AppStorage("swipeLeftShortAction") private var swipeLeftShortAction: String = "delete"
    @AppStorage("swipeLeftLongAction") private var swipeLeftLongAction: String = "restore"
    @AppStorage("swipeRightShortAction") private var swipeRightShortAction: String = "export"
    @AppStorage("swipeRightLongAction") private var swipeRightLongAction: String = "preview"

    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $preferredColorScheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(SegmentedPickerStyle())
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
        .navigationTitle("Settings")
    }
}
