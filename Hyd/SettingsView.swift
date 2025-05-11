import SwiftUI

// The .if extension and AppColors are available via Utilities.swift in the same target.

struct SettingsView: View {
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"
    @AppStorage("defaultAuthor") private var defaultAuthor: String = ""
    @AppStorage("defaultTags") private var defaultTags: String = ""
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("showAccessibilityLabels") private var showAccessibilityLabels: Bool = false
    @AppStorage("swipeLeftShortAction") private var swipeLeftShortAction: String = "delete"
    @AppStorage("swipeLeftLongAction") private var swipeLeftLongAction: String = "export"
    @AppStorage("swipeRightShortAction") private var swipeRightShortAction: String = "restore"
    @AppStorage("swipeRightLongAction") private var swipeRightLongAction: String = "preview"
    @AppStorage("biometricsEnabled") private var biometricsEnabled: Bool = false
    @Environment(\.dismiss) private var dismiss

    let swipeActions = [
        ("delete", "Delete"),
        ("export", "Export"),
        ("restore", "Restore"),
        ("preview", "Preview"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
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
                .if(showAccessibilityLabels) { $0.accessibilityLabel("Close") }
            }
            .frame(height: 44)
            .background(AppColors.background)
            Divider()
            Form {
                Section(header: Text("Appearance").font(.system(size: fontSize, weight: .semibold)))
                {
                    Picker("Color Scheme", selection: $preferredColorScheme) {
                        Text("System").font(.system(size: fontSize)).tag("system")
                        Text("Light").font(.system(size: fontSize)).tag("light")
                        Text("Dark").font(.system(size: fontSize)).tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    HStack {
                        Text("Font Size").font(.system(size: fontSize))
                        Slider(value: $fontSize, in: 12...20, step: 2) {
                            Text("Font Size").font(.system(size: fontSize))
                        }
                        Text("\(Int(fontSize))")
                            .font(.system(size: fontSize))
                            .frame(width: 32)
                    }
                }
                Section(header: Text("Defaults").font(.system(size: fontSize, weight: .semibold))) {
                    TextField("Default Author", text: $defaultAuthor)
                        .font(.system(size: fontSize))
                    TextField("Default Tags (comma separated)", text: $defaultTags)
                        .font(.system(size: fontSize))
                }
                Section(
                    header: Text("Accessibility").font(.system(size: fontSize, weight: .semibold))
                ) {
                    Toggle("Show Accessibility Labels", isOn: $showAccessibilityLabels)
                        .font(.system(size: fontSize))
                }
                Section(
                    header: Text("Security").font(.system(size: fontSize, weight: .semibold))
                ) {
                    Toggle("Require Biometrics", isOn: $biometricsEnabled)
                        .font(.system(size: fontSize))
                }
                Section(
                    header: Text("Swipe Gestures").font(.system(size: fontSize, weight: .semibold))
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Swipe Left (Short)")
                                .font(.system(size: fontSize))
                            Spacer()
                            Picker("Swipe Left (Short)", selection: $swipeLeftShortAction) {
                                ForEach(swipeActions, id: \.0) { action, label in
                                    Text(label).font(.system(size: fontSize)).tag(action)
                                }
                            }
                            .labelsHidden()
                        }
                        HStack {
                            Text("Swipe Left (Long)")
                                .font(.system(size: fontSize))
                            Spacer()
                            Picker("Swipe Left (Long)", selection: $swipeLeftLongAction) {
                                ForEach(swipeActions, id: \.0) { action, label in
                                    Text(label).font(.system(size: fontSize)).tag(action)
                                }
                            }
                            .labelsHidden()
                        }
                        HStack {
                            Text("Swipe Right (Short)")
                                .font(.system(size: fontSize))
                            Spacer()
                            Picker("Swipe Right (Short)", selection: $swipeRightShortAction) {
                                ForEach(swipeActions, id: \.0) { action, label in
                                    Text(label).font(.system(size: fontSize)).tag(action)
                                }
                            }
                            .labelsHidden()
                        }
                        HStack {
                            Text("Swipe Right (Long)")
                                .font(.system(size: fontSize))
                            Spacer()
                            Picker("Swipe Right (Long)", selection: $swipeRightLongAction) {
                                ForEach(swipeActions, id: \.0) { action, label in
                                    Text(label).font(.system(size: fontSize)).tag(action)
                                }
                            }
                            .labelsHidden()
                        }
                    }
                }
            }
        }
    }
}
