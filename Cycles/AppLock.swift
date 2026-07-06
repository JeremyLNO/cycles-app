import SwiftUI
import LocalAuthentication

/// Gates the app behind Face ID / Touch ID / passcode when the user enables it,
/// and masks the content in the app switcher for privacy.
struct AppLockModifier: ViewModifier {
    @AppStorage("lock.enabled") private var lockEnabled = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var unlocked = false
    @State private var authenticating = false

    private var bypass: Bool { CommandLine.arguments.contains("-unlock") }

    func body(content: Content) -> some View {
        ZStack {
            content

            // Privacy mask shown while the app is not active (app switcher snapshot).
            if lockEnabled && !bypass && scenePhase != .active {
                maskView
            }

            // Full lock screen until the user authenticates.
            if lockEnabled && !bypass && !unlocked {
                lockView
            }
        }
        .animation(.easeInOut(duration: 0.2), value: unlocked)
        .animation(.easeInOut(duration: 0.2), value: scenePhase)
        .task {
            if lockEnabled && !bypass { authenticate() } else { unlocked = true }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                if lockEnabled { unlocked = false }
            } else if phase == .active, lockEnabled, !bypass, !unlocked {
                authenticate()
            }
        }
        .onChange(of: lockEnabled) { _, enabled in
            if !enabled { unlocked = true }
        }
    }

    private var lockView: some View {
        ZStack {
            CyclesBackground()
            VStack(spacing: 18) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Palette.rose)
                Text(L.t("lock_title"))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Palette.ink)
                Button {
                    authenticate()
                } label: {
                    Text(L.t("lock_unlock"))
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28).padding(.vertical, 12)
                        .background(Capsule().fill(Palette.rose))
                }
            }
        }
    }

    private var maskView: some View {
        ZStack {
            CyclesBackground()
            Image(systemName: "lock.heart.fill")
                .font(.system(size: 50))
                .foregroundStyle(Palette.rose.opacity(0.8))
        }
    }

    private func authenticate() {
        guard !authenticating else { return }
        authenticating = true
        let ctx = LAContext()
        var error: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: L.t("lock_reason")) { ok, _ in
                DispatchQueue.main.async {
                    authenticating = false
                    if ok { unlocked = true }
                }
            }
        } else {
            // No biometrics/passcode available — fail open so the user is never locked out.
            authenticating = false
            unlocked = true
        }
    }
}

extension View {
    func appLock() -> some View { modifier(AppLockModifier()) }
}
