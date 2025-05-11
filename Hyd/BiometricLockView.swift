import LocalAuthentication
import SwiftUI

struct BiometricLockView: View {
    @Binding var isUnlocked: Bool
    @State private var errorMessage: String?
    @AppStorage("fontSize") private var fontSize: Double = 14

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "faceid")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.accentColor)
            Text("Unlock with Biometrics or Passcode")
                .font(.system(size: fontSize, weight: .semibold))
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: fontSize))
            }
            Button("Authenticate") {
                authenticate()
            }
            .font(.system(size: fontSize, weight: .semibold))
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear(perform: authenticate)
    }

    func authenticate() {
        let context = LAContext()
        var error: NSError?
        // Use biometrics only (Face ID/Touch ID), fallback to passcode only if biometrics unavailable
        let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
        if context.canEvaluatePolicy(policy, error: &error) {
            context.evaluatePolicy(policy, localizedReason: "Unlock Hyd") { success, authError in
                DispatchQueue.main.async {
                    if success {
                        isUnlocked = true
                    } else {
                        // If biometrics fail, try passcode fallback
                        authenticateWithPasscode(context: context)
                    }
                }
            }
        } else {
            // If biometrics unavailable, fallback to passcode
            authenticateWithPasscode(context: context)
        }
    }

    func authenticateWithPasscode(context: LAContext) {
        let policy: LAPolicy = .deviceOwnerAuthentication
        context.evaluatePolicy(policy, localizedReason: "Unlock Hyd with Passcode") {
            success, authError in
            DispatchQueue.main.async {
                if success {
                    isUnlocked = true
                } else {
                    errorMessage = authError?.localizedDescription ?? "Failed to authenticate."
                }
            }
        }
    }
}
