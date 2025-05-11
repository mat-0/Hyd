import SwiftUI

// All shared types and extensions are available since all files are in the same target.

struct FooterMenuBar: View {
    @Binding var showArchive: Bool
    @Binding var showSettings: Bool
    let exportAction: () -> Void
    let exportDisabled: Bool
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("showAccessibilityLabels") private var showAccessibilityLabels: Bool = false

    var body: some View {
        HStack {
            Spacer()
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
            Spacer()
        }
        .padding(.vertical, 8)
        .background(AppColors.background)
        .overlay(Divider(), alignment: .top)
        .frame(maxWidth: .infinity)
    }
}
