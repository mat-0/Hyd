import SwiftUI

struct AppColors {
    static var background: Color {
        #if os(iOS)
            return Color(UIColor.systemBackground)
        #else
            return Color(NSColor.windowBackgroundColor)
        #endif
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
