import SwiftUI
import SwiftData
import AuthenticationServices

/// "My account" page: optional Sign in with Apple, sign-out, and real account +
/// data deletion. The app works fully without an account (local + iCloud).
struct AccountView: View {
    @EnvironmentObject private var account: AccountManager
    @Environment(\.modelContext) private var ctx
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.systemDefault.rawValue

    @State private var showDeleteConfirm = false

    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }
    private let privacyURL = URL(string: "https://www.crazybeelabs.com/privacy-policy/")!

    var body: some View {
        ZStack {
            CyclesBackground()
            ScrollView {
                VStack(spacing: 18) {
                    if account.isSignedIn {
                        signedInCard
                        signOutButton
                    } else {
                        signInCard
                    }
                    privacyRow
                    deleteCard
                }
                .padding(20)
            }
        }
        .navigationTitle(L.t("account_title", lang))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(L.t("account_delete_q", lang),
                            isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button(L.t("account_delete", lang), role: .destructive) {
                account.deleteEverything(context: ctx)
            }
            Button(L.t("cancel", lang), role: .cancel) {}
        } message: {
            Text(L.t("account_delete_msg", lang))
        }
    }

    // MARK: Signed in
    private var signedInCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 46)).foregroundStyle(Palette.rose)
                VStack(alignment: .leading, spacing: 3) {
                    Text(account.displayName.isEmpty ? L.t("account_apple_user", lang) : account.displayName)
                        .font(.system(.headline, design: .rounded)).foregroundStyle(Palette.ink)
                    if !account.email.isEmpty {
                        Text(account.email).font(.caption).foregroundStyle(Palette.sub)
                    }
                    Label(L.t("account_via_apple", lang), systemImage: "apple.logo")
                        .font(.caption2).foregroundStyle(Palette.sub)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var signOutButton: some View {
        Button { account.signOut() } label: {
            Text(L.t("account_signout", lang))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Palette.rose)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Capsule().fill(Palette.card).overlay(Capsule().stroke(Palette.rose.opacity(0.4), lineWidth: 1)))
        }
    }

    // MARK: Signed out
    private var signInCard: some View {
        GlassCard {
            VStack(spacing: 14) {
                Text(L.t("account_signin_intro", lang))
                    .font(.subheadline).foregroundStyle(Palette.sub)
                    .multilineTextAlignment(.center)

                SignInWithAppleButton(.signIn) { request in
                    account.configureRequest(request)
                } onCompletion: { result in
                    account.handle(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .clipShape(Capsule())

                Text(L.t("account_more_soon", lang))
                    .font(.caption2).foregroundStyle(Palette.sub)
            }
        }
    }

    // MARK: Privacy
    private var privacyRow: some View {
        Link(destination: privacyURL) {
            GlassCard {
                HStack {
                    Label(L.t("privacy_policy", lang), systemImage: "hand.raised.fill")
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(Palette.sub)
                }
            }
        }
    }

    // MARK: Delete
    private var deleteCard: some View {
        VStack(spacing: 8) {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label(L.t("account_delete", lang), systemImage: "trash.fill")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(Color.red.opacity(0.10)))
            }
            Text(L.t("account_delete_footer", lang))
                .font(.caption2).foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }
}
