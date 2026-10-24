import SwiftUI
import StoreKit
import SafariServices

struct SettingsScreen: View {
    @EnvironmentObject var state: AppState
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL
    @State private var showIconPicker = false
    @State private var showDeleteConfirm = false
    @State private var safariURL: URL?
    @State private var restoreMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                BackCircleButton { state.showSettings = false }
                Text("Impostazioni")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 18)

            ScrollView {
                VStack(spacing: 12) {
                    Menu {
                        ForEach(DistanceUnit.allCases) { unit in
                            Button {
                                state.units = unit
                            } label: {
                                if unit == state.units {
                                    Label(unit.title, systemImage: "checkmark")
                                } else {
                                    Text(unit.title)
                                }
                            }
                        }
                    } label: {
                        SettingsRow(icon: AnyView(Image(systemName: "gauge.with.dots.needle.33percent")),
                                    title: "Unità di distanza") {
                            HStack(spacing: 4) {
                                Text(state.units.title)
                                Image(systemName: "chevron.up.chevron.down").font(.system(size: 11, weight: .semibold))
                            }
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.45))
                        }
                    }

                    Button { showIconPicker = true } label: {
                        SettingsRow(icon: AnyView(AppIconGlyph()), title: "Icona app")
                    }

                    ShareLink(item: AppConfig.shareURL, message: Text(AppConfig.shareText)) {
                        SettingsRow(icon: AnyView(ShareNodesGlyph()), title: "Condividi")
                    }

                    Button { requestReview() } label: {
                        SettingsRow(icon: AnyView(Image(systemName: "star.fill")), title: "Valutaci")
                    }

                    Button { openURL(AppConfig.discordURL) } label: {
                        SettingsRow(icon: AnyView(Image(systemName: "gamecontroller.fill")),
                                    title: "Unisciti alla community Discord")
                    }

                    Button {
                        if let url = URL(string: "mailto:\(AppConfig.contactEmail)") { openURL(url) }
                    } label: {
                        SettingsRow(icon: AnyView(Image(systemName: "info.circle.fill")), title: "Contattaci")
                    }

                    Button { safariURL = AppConfig.privacyURL } label: {
                        SettingsRow(icon: AnyView(Image(systemName: "checkmark.shield.fill")),
                                    title: "Informativa sulla privacy")
                    }

                    Button { safariURL = AppConfig.termsURL } label: {
                        SettingsRow(icon: AnyView(Image(systemName: "doc.text.fill")), title: "Termini di servizio")
                    }

                    Button { showDeleteConfirm = true } label: {
                        SettingsRow(icon: AnyView(Image(systemName: "trash.fill")), title: "Cancella i miei dati",
                                    destructive: true)
                    }

                    Spacer().frame(height: 22)

                    Button { restorePurchases() } label: {
                        SettingsRow(icon: AnyView(Image(systemName: "clock.arrow.circlepath")),
                                    title: "Ripristina acquisti")
                    }
                }
                .buttonStyle(PressableStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showIconPicker) {
            AppIconPicker()
                .presentationDetents([.medium])
                .presentationBackground(Color(white: 0.06))
        }
        .sheet(item: Binding(get: { safariURL.map(IdentifiableURL.init) },
                             set: { safariURL = $0?.url })) { item in
            SafariView(url: item.url).ignoresSafeArea()
        }
        .confirmationDialog("Cancellare tutti i tuoi dati?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Cancella i miei dati", role: .destructive) { state.deleteAllData() }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text("Posizioni salvate, cronologia e luoghi esplorati verranno eliminati.")
        }
        .alert("Ripristina acquisti", isPresented: Binding(get: { restoreMessage != nil },
                                                          set: { if !$0 { restoreMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreMessage ?? "")
        }
    }

    private func restorePurchases() {
        Task {
            do {
                try await AppStore.sync()
                await MainActor.run { restoreMessage = "Acquisti ripristinati." }
            } catch {
                await MainActor.run { restoreMessage = "Nessun acquisto da ripristinare." }
            }
        }
    }
}

struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

struct SettingsRow<Trailing: View>: View {
    var icon: AnyView
    var title: String
    var destructive: Bool = false
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 14) {
            icon
                .font(.system(size: 19, weight: .semibold))
                .frame(width: 26)
            Text(title)
                .font(.system(size: 17, weight: .medium))
            Spacer()
            trailing
        }
        .foregroundStyle(destructive ? Color(hex: 0xFF3B4E) : .white)
        .padding(.horizontal, 18)
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(destructive ? Color(hex: 0x3A0A10) : Color(white: 0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(destructive ? Color(hex: 0xFF3B4E).opacity(0.25) : Color.white.opacity(0.05))
        )
        .contentShape(Rectangle())
    }
}

extension SettingsRow where Trailing == EmptyView {
    init(icon: AnyView, title: String, destructive: Bool = false) {
        self.init(icon: icon, title: title, destructive: destructive) { EmptyView() }
    }
}

struct AppIconGlyph: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Color.white).frame(width: 20, height: 20)
            Circle().strokeBorder(Color.black, lineWidth: 2.5).frame(width: 10, height: 10)
        }
    }
}

struct ShareNodesGlyph: View {
    var body: some View {
        Canvas { ctx, size in
            let a = CGPoint(x: size.width * 0.22, y: size.height * 0.5)
            let b = CGPoint(x: size.width * 0.78, y: size.height * 0.2)
            let c = CGPoint(x: size.width * 0.78, y: size.height * 0.8)
            var p = Path()
            p.move(to: b); p.addLine(to: a); p.addLine(to: c)
            ctx.stroke(p, with: .foreground, lineWidth: 2.2)
            for pt in [a, b, c] {
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 4, y: pt.y - 4, width: 8, height: 8)), with: .foreground)
            }
        }
        .frame(width: 22, height: 22)
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}

struct AppIconPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var current: String? = UIApplication.shared.alternateIconName

    private struct IconOption: Identifiable {
        let name: String?
        let preview: String
        let title: String
        var id: String { preview }
    }

    private let options: [IconOption] = [
        IconOption(name: nil, preview: "IconPreviewDefault", title: "Classica"),
        IconOption(name: "AppIconLight", preview: "IconPreviewLight", title: "Chiara"),
        IconOption(name: "AppIconNeon", preview: "IconPreviewNeon", title: "Neon")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Icona app")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.top, 24)
            HStack(spacing: 18) {
                ForEach(options) { option in
                    Button {
                        UIApplication.shared.setAlternateIconName(option.name) { _ in
                            DispatchQueue.main.async {
                                current = UIApplication.shared.alternateIconName
                            }
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(option.preview)
                                .resizable()
                                .frame(width: 84, height: 84)
                                .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 19, style: .continuous)
                                        .strokeBorder(current == option.name ? Color.white : Color.white.opacity(0.1),
                                                      lineWidth: current == option.name ? 3 : 1)
                                )
                            Text(option.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}
