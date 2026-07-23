import Foundation
import AuthenticationServices
import SwiftData
import Security
import UserNotifications

/// Lightweight, backend-free account layer built on Sign in with Apple.
/// The Apple user identifier lives in the Keychain; display name/email in defaults.
final class AccountManager: ObservableObject {
    @Published var isSignedIn: Bool
    @Published var displayName: String
    @Published var email: String

    private let idKey = "account.appleUserID"
    private let nameKey = "account.name"
    private let emailKey = "account.email"

    init() {
        let id = Keychain.get("account.appleUserID")
        isSignedIn = id != nil
        displayName = UserDefaults.standard.string(forKey: "account.name") ?? ""
        email = UserDefaults.standard.string(forKey: "account.email") ?? ""
    }

    // MARK: Sign in with Apple
    func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handle(_ result: Result<ASAuthorization, Error>) {
        guard case .success(let auth) = result,
              let cred = auth.credential as? ASAuthorizationAppleIDCredential else { return }
        Keychain.set(cred.user, for: idKey)
        if let n = cred.fullName {
            let full = [n.givenName, n.familyName].compactMap { $0 }.joined(separator: " ")
            if !full.isEmpty {
                displayName = full
                UserDefaults.standard.set(full, forKey: nameKey)
            }
        }
        if let e = cred.email, !e.isEmpty {
            email = e
            UserDefaults.standard.set(e, forKey: emailKey)
        }
        isSignedIn = true
    }

    /// Re-checks the stored Apple credential; signs out if it was revoked in Settings.
    func refreshCredentialState() {
        guard let id = Keychain.get(idKey) else { return }
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: id) { [weak self] state, _ in
            if state == .revoked || state == .notFound {
                DispatchQueue.main.async { self?.signOut() }
            }
        }
    }

    func signOut() {
        Keychain.delete(idKey)
        UserDefaults.standard.removeObject(forKey: nameKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        displayName = ""
        email = ""
        isSignedIn = false
    }

    /// Permanently deletes ALL user data (SwiftData → propagated to iCloud), local
    /// preferences and scheduled notifications, then signs out. No server data is kept.
    @MainActor
    func deleteEverything(context: ModelContext) {
        for p in (try? context.fetch(FetchDescriptor<Profile>())) ?? [] { context.delete(p) }
        for e in (try? context.fetch(FetchDescriptor<PeriodEntry>())) ?? [] { context.delete(e) }
        for l in (try? context.fetch(FetchDescriptor<DayLog>())) ?? [] { context.delete(l) }
        try? context.save()

        SharedStore.clear()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let d = UserDefaults.standard
        let keys = ["selectedProfileID", "onboarded", "default.cycleLength", "lock.enabled",
                    NotificationManager.Keys.periodEnabled, NotificationManager.Keys.ovulationEnabled,
                    NotificationManager.Keys.hour, NotificationManager.Keys.minute]
        keys.forEach { d.removeObject(forKey: $0) }

        signOut()
    }
}

/// Minimal Keychain wrapper for a single string value per key.
enum Keychain {
    static func set(_ value: String, for key: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrAccount as String: key]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(add as CFDictionary, nil)
    }

    static func get(_ key: String) -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrAccount as String: key,
                                     kSecReturnData as String: true,
                                     kSecMatchLimit as String: kSecMatchLimitOne]
        var out: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrAccount as String: key]
        SecItemDelete(query as CFDictionary)
    }
}
