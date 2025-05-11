import LocalAuthentication
import SwiftUI

@main
struct HydApp: App {
    @AppStorage("biometricsEnabled") private var biometricsEnabled: Bool = false
    @State private var isUnlocked = false

    var body: some Scene {
        WindowGroup {
            RootView(biometricsEnabled: biometricsEnabled, isUnlocked: $isUnlocked)
        }
    }
}

struct RootView: View {
    let biometricsEnabled: Bool
    @Binding var isUnlocked: Bool
    var body: some View {
        if biometricsEnabled && !isUnlocked {
            BiometricLockView(isUnlocked: $isUnlocked)
        } else {
            ContentView()
        }
    }
}
