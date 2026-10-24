import SwiftUI

struct PinnedPlacePanel: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        BottomPanel(onDismiss: { state.dismissPanel() }) {
            if let place = state.pinnedPlace {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Posizione fissata")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(place.address)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .lineLimit(2)
                        .padding(.top, 4)
                        .padding(.bottom, 18)

                    if state.explored.contains(place.exploreKey) {
                        DashedEmptyCard(icon: "checkmark.seal.fill",
                                        title: "Hai esplorato questo posto",
                                        subtitle: "Sei stato il primo ad arrivare qui.")
                    } else {
                        DashedEmptyCard(icon: "scope",
                                        title: "Nessuno ha ancora esplorato questo posto",
                                        subtitle: "Vai lì e sii il primo.")
                    }

                    if state.isLoadingRoute {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .padding(.top, 18)
                    } else {
                        GlassEffectContainer(spacing: 10) {
                        HStack(spacing: 10) {
                            Button { state.toggleSave(place) } label: {
                                HStack(spacing: 8) {
                                    Text(state.isSaved(place) ? "Salvato" : "Salva")
                                        .font(.system(size: 16, weight: .semibold))
                                    Image(systemName: state.isSaved(place) ? "bookmark.fill" : "bookmark.fill")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .frame(height: 54)
                                .contentShape(Capsule())
                                .glassEffect(.regular.tint(state.isSaved(place) ? Color(state.theme.accent).opacity(0.5) : nil)
                                                .interactive(), in: Capsule())
                            }
                            .buttonStyle(.plain)

                            GlassCapsuleButton(title: "Ottieni indicazioni", icon: "location.fill") {
                                state.requestDirections()
                            }
                        }
                        }
                        .padding(.top, 18)
                    }
                }
            }
        }
    }
}

struct DirectionsPanel: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        BottomPanel(onDismiss: { state.dismissPanel() }) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Indicazioni")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 14) {
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 26)
                        Text("La mia posizione")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Rectangle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 1.5, height: 22)
                        .padding(.leading, 12)
                        .padding(.vertical, 4)
                    HStack(spacing: 14) {
                        CloverIcon(color: Color(state.theme.accent), size: 26)
                            .frame(width: 26)
                        Text(state.pinnedPlace?.name.isEmpty == false ? state.pinnedPlace!.name : "Posizione fissata")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                if let route = state.route {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(route.minutes) min")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundStyle(.white)
                            Text("\(Formatters.time.string(from: route.arrival)) ETA • \(state.units.value(route.distance)) \(state.units.shortLabel)")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.white.opacity(0.45))
                        }
                        Spacer()
                        GlassCapsuleButton(title: "Inizia ora", icon: nil, height: 50) {
                            state.startNavigation()
                        }
                        .frame(width: 130)
                    }
                    .padding(.top, 18)
                }
            }
        }
    }
}

struct NavigationPanel: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            Button { state.cycleTracking() } label: {
                GlassCircle(size: 44) {
                    Image(systemName: "safari.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)

            BottomPanel(onDismiss: nil) {
                VStack(spacing: 18) {
                    if let route = state.route {
                        HStack {
                            stat(Formatters.time.string(from: route.arrival), "arrivo")
                            stat("\(route.minutes)", "min")
                            stat(state.units.value(route.distance), state.units.shortLabel)
                        }
                    }
                    GlassCapsuleButton(title: "Termina percorso", icon: nil, height: 54,
                                       tint: Color(hex: 0xFF3B4E).opacity(0.92), foreground: .white) {
                        state.endNavigation()
                    }
                    .shadow(color: Color(hex: 0xFF2E45).opacity(0.45), radius: 14)
                }
            }
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 24, weight: .heavy)).foregroundStyle(.white)
            Text(label).font(.system(size: 14, weight: .medium)).foregroundStyle(Color.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
    }
}

struct SavedPlacesPanel: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        BottomPanel(onDismiss: { state.panel = .none }) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Posizioni salvate")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.bottom, 16)

                if state.saved.isEmpty {
                    DashedEmptyCard(icon: "bookmark.fill",
                                    title: "Nessuna posizione salvata",
                                    subtitle: "Salva la tua posizione usando l'icona \"Pin\"!")
                        .padding(.bottom, 20)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(state.saved) { place in
                                HStack(spacing: 12) {
                                    Button {
                                        state.pin(place)
                                    } label: {
                                        HStack(spacing: 12) {
                                            CloverIcon(color: Color(state.theme.accent), size: 26)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(place.name.isEmpty ? "Posizione" : place.name)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundStyle(.white)
                                                    .lineLimit(1)
                                                Text(place.address)
                                                    .font(.system(size: 13))
                                                    .foregroundStyle(Color.white.opacity(0.4))
                                                    .lineLimit(1)
                                            }
                                            Spacer(minLength: 0)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    Button {
                                        state.saved.removeAll { $0.id == place.id }
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(Color.white.opacity(0.5))
                                            .frame(width: 36, height: 36)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 64)
                                .glassRow(cornerRadius: 22)
                            }
                        }
                    }
                    .frame(maxHeight: 320)
                    .padding(.bottom, 12)
                }
            }
        }
    }
}
