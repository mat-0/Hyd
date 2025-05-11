import SwiftUI

struct PreviewView: View {
    let text: String
    @AppStorage("fontSize") private var fontSize: Double = 14
    @AppStorage("showAccessibilityLabels") private var showAccessibilityLabels: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Preview")
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
            ScrollView {
                Text(text)
                    .padding()
                    .font(.system(size: fontSize))
            }
        }
    }
}
