import SwiftUI

struct MainMapScreen: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var location: LocationManager
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(Prefs.showCompass) private var showCompass = true

    var body: some View {
        GeometryReader { geo in
            ZStack {
                GameMapView(state: state)
                    .ignoresSafeArea()

                // vignettatura del tema (bordi scuri come nelle schermate di riferimento)
                if state.theme.vignette > 0 {
                    RadialGradient(colors: [.clear, .black.opacity(state.theme.vignette)],
                                   center: .center, startRadius: geo.size.width * 0.42,
                                   endRadius: geo.size.height * 0.62)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                // sfocatura superiore solo mentre l'intestazione d'avvio mostra giorno, ora e posizione
                if state.showHeader && state.panel != .navigating {
                    // in modalità scura: materiale scuro più denso + velatura nera, sfocatura ben visibile
                    ZStack {
                        Rectangle()
                            .fill(colorScheme == .dark ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.ultraThinMaterial))
                        if colorScheme == .dark {
                            Rectangle().fill(Color.black.opacity(0.32))
                        }
                    }
                    .environment(\.colorScheme, colorScheme)
                    .mask(LinearGradient(stops: [.init(color: .black, location: 0),
                                                 .init(color: .black, location: 0.6),
                                                 .init(color: .clear, location: 1)],
                                         startPoint: .top, endPoint: .bottom))
                        .frame(height: geo.safeAreaInsets.top + (colorScheme == .dark ? 200 : 170))
                        .frame(maxHeight: .infinity, alignment: .top)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                VStack(spacing: 0) {
                    ZStack {
                        if state.panel == .navigating {
                            NavigationBanner()
                                .transition(.move(edge: .top).combined(with: .opacity))
                        } else if state.showHeader {
                            HeaderView()
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        } else if state.panel != .directions {
                            VStack(spacing: 10) {
                                TopBar()
                                if state.panel == .none || state.panel == .results {
                                    CategoryChips()
                                }
                                if state.showSearchArea && state.panel == .results {
                                    Button { state.searchThisArea() } label: {
                                        Label("Cerca in questa zona", systemImage: "arrow.clockwise")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 16).frame(height: 38)
                                            .glassEffect(.regular.tint(Color(state.theme.accent).opacity(0.75)).interactive(),
                                                         in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .transition(.scale.combined(with: .opacity))
                                }
                                HStack {
                                    Spacer()
                                    if showCompass && abs(state.mapHeading) > 2 {
                                        CompassButton()
                                            .padding(.trailing, 18)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(.top, 8)
                    Spacer()
                }

                // controlli inferiori
                VStack {
                    Spacer()
                    if state.panel == .none {
                        BottomControls()
                            .padding(.bottom, max(geo.safeAreaInsets.bottom, 12) + 8)
                            .transition(.opacity)
                    }
                }

                // pannelli
                VStack {
                    Spacer()
                    panel
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.88), value: state.panel)
        .animation(.easeInOut(duration: 0.2), value: abs(state.mapHeading) > 2)
        .sheet(isPresented: $state.showSteps) {
            StepsSheet()
                .environmentObject(state)
        }
        .sheet(isPresented: $state.showAlongRoute) {
            AlongRouteSheet()
                .environmentObject(state)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: state.showSearchArea)
        .animation(.easeInOut(duration: 0.3), value: state.isLoadingRoute)
        .alert("Indicazioni", isPresented: Binding(get: { state.routeError != nil },
                                                   set: { if !$0 { state.routeError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(state.routeError ?? "")
        }
    }

    @ViewBuilder
    private var panel: some View {
        switch state.panel {
        case .pinned:
            PinnedPlacePanel().transition(.move(edge: .bottom))
        case .directions:
            DirectionsPanel().transition(.move(edge: .bottom))
        case .navigating:
            NavigationPanel().transition(.move(edge: .bottom))
        case .saved:
            SavedPlacesPanel().transition(.move(edge: .bottom))
        case .results:
            ResultsPanel().transition(.move(edge: .bottom))
        case .none:
            EmptyView()
        }
    }
}

struct HeaderView: View {
    @EnvironmentObject var location: LocationManager
    @State private var now = Date()

    var body: some View {
        VStack(spacing: 2) {
            Text(Formatters.dayTime.string(from: now))
                .font(.system(size: 17, weight: .bold))
            Text(location.placeName)
                .font(.system(size: 34, weight: .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.8), radius: 8, y: 2)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .onAppear { now = Date() }
    }
}

struct TopBar: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var location: LocationManager

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 10) {
                Button { state.showMapSelection = true } label: {
                    GlassCircle(size: 44) {
                        Image(systemName: "globe.europe.africa.fill")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                Button { state.showSearch = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                        Text(location.placeName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .frame(maxWidth: 250)
                    .contentShape(Capsule())
                    .glassEffect(.regular.interactive(), in: Capsule())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                Button { state.showSettings = true } label: {
                    GlassCircle(size: 44) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
    }
}

struct BottomControls: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        GlassEffectContainer(spacing: 18) {
            HStack(spacing: 18) {
                Button { state.panel = .saved } label: {
                    GlassCircle(size: 46) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)

                Button { state.pinCurrentPosition() } label: {
                    GlassCircle(size: 58, tint: Color(hex: 0x0A6CFF).opacity(0.18)) { BluePinIcon() }
                }
                .buttonStyle(.plain)

                Button { state.cycleTracking() } label: {
                    GlassCircle(size: 46) {
                        Image(systemName: state.tracking == .heading ? "safari.fill" : "location.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Scorciatoie di ricerca sotto la barra (come i chip di Google Maps)
struct CategoryChips: View {
    @EnvironmentObject var state: AppState

    private struct Chip: Identifiable {
        let title: String
        let icon: String
        var id: String { title }
    }

    private let baseItems: [Chip] = [
        Chip(title: "Ristoranti", icon: "fork.knife"), Chip(title: "Benzina", icon: "fuelpump.fill"),
        Chip(title: "Caffè", icon: "cup.and.saucer.fill"), Chip(title: "Supermercati", icon: "cart.fill"),
        Chip(title: "Hotel", icon: "bed.double.fill"), Chip(title: "Farmacie", icon: "pills.fill"),
        Chip(title: "Parcheggi", icon: "parkingsign"), Chip(title: "Bancomat", icon: "creditcard.fill"),
        Chip(title: "Ospedali", icon: "cross.case.fill")
    ]
    @AppStorage(Prefs.engine) private var engine = "gas"

    /// con auto elettrica o plug-in "Benzina" diventa "Ricarica" (come Google Maps)
    private var items: [Chip] {
        guard engine == "electric" || engine == "plugin" else { return baseItems }
        return baseItems.map { $0.title == "Benzina" ? Chip(title: "Ricarica elettrica", icon: "bolt.car.fill") : $0 }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(items) { item in
                        Button { state.searchCategory(item.title) } label: {
                            HStack(spacing: 6) {
                                Image(systemName: item.icon).font(.system(size: 13, weight: .bold))
                                Text(item.title).font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .contentShape(Capsule())
                            .glassEffect(.regular.tint(state.resultsTitle == item.title && state.panel == .results
                                                       ? Color(state.theme.accent).opacity(0.7) : nil).interactive(),
                                         in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 2)
            }
        }
    }
}

/// Bussola: compare quando la mappa è ruotata, toccala per tornare al nord
struct CompassButton: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        Button { state.map.resetNorth() } label: {
            GlassCircle(size: 44) {
                Image(systemName: "location.north.line.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFF3B4E), .white)
                    .rotationEffect(.degrees(-state.mapHeading))
            }
        }
        .buttonStyle(.plain)
    }
}
