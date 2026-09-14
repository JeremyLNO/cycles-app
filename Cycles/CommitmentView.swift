import SwiftUI

/// Shown once at first launch: explains why Cycles is 100% free thanks to Crazy Bee
/// Labs' commitment (Cycles, Pillo, Respire). Also reachable from Settings.
struct CommitmentView: View {
    /// Provided when shown at first launch; nil when opened from Settings.
    var onContinue: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.systemDefault.rawValue

    private var lang: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .en }
    private let commitmentURL = URL(string: "https://www.crazybeelabs.com/commitment")!
    /// The studio's catalogue — the other free apps this one belongs to.
    private let appsURL = URL(string: "https://www.crazybeelabs.com/apps")!

    private let rows: [(String, String)] = [
        ("checkmark.seal.fill", "free_row_ads"),
        ("lock.shield.fill", "free_row_privacy"),
        ("heart.fill", "free_row_suite"),
    ]

    var body: some View {
        ZStack {
            CyclesBackground()
            VStack(spacing: 18) {
                Spacer(minLength: 12)

                Image(systemName: "gift.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Palette.rose)

                Text(L.t("free_title", lang))
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.center)

                Text(L.t("free_intro", lang))
                    .font(.subheadline)
                    .foregroundStyle(Palette.sub)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(rows, id: \.1) { icon, key in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: icon)
                                    .foregroundStyle(Palette.rose)
                                    .frame(width: 24)
                                Text(L.t(key, lang))
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }

                Spacer(minLength: 8)

                // Footer: Crazy Bee Labs logo + link to the commitment page.
                Link(destination: commitmentURL) {
                    VStack(spacing: 5) {
                        Image("CrazyBeeLogo")
                            .resizable().scaledToFit()
                            .frame(height: 34)
                        Text("Crazy Bee Labs")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(Palette.ink)
                        HStack(spacing: 4) {
                            Text(L.t("free_link", lang))
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.rose)
                    }
                }

                // Second destination: the screen says Cycles belongs to a family of free apps,
                // so it should also show where to find them.
                Link(destination: appsURL) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.2x2.fill")
                        Text(L.t("free_other_apps", lang))
                        Image(systemName: "arrow.up.right")
                            .font(.caption2.weight(.bold))
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.rose)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(Palette.rose.opacity(0.35), lineWidth: 1))
                }
                .padding(.top, 10)

                Button {
                    onContinue?()
                    dismiss()
                } label: {
                    Text(L.t(onContinue != nil ? "continue" : "done", lang))
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(LinearGradient(colors: [Palette.rose, Palette.roseDeep],
                                                                  startPoint: .leading, endPoint: .trailing)))
                }
            }
            .padding(24)
        }
    }
}
