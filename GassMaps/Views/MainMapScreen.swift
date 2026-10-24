import SwiftUI

struct MainMapScreen: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var location: LocationManager

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

                // nebbia/sfocatura all'orizzonte e vignettatura
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(LinearGradient(colors: [.black, .black.opacity(0.7), .clear],
                                             startPoint: .top, endPoint: .bottom))
                        .overlay(
                            LinearGradient(colors: [.black.opacity(0.55), .clear],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .frame(height: geo.safeAreaInsets.top + 150)
                    Spacer()
                    // sfocatura progressiva in basso (profondità di campo, come nelle schermate)
                    if state.theme.id == "neon" || state.theme.id == "palm" {
                        LinearGradient(colors: [.clear, .black.opacity(0.45)], startPoint: .top, endPoint: .bottom)
                            .frame(height: 180)
                    } else {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(LinearGradient(colors: [.clear, .black.opacity(0.75), .black],
                                             startPoint: .top, endPoint: .bottom))
                        .overlay(LinearGradient(colors: [.clear, .black.opacity(0.25)],
                                                startPoint: .top, endPoint: .bottom))
                        .frame(height: 200)
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    ZStack {
                        if state.showHeader {
                            HeaderView()
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        } else if state.panel != .navigating && state.panel != .directions {
                            TopBar()
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
