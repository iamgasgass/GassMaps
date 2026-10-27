import SwiftUI
import MapKit

// MARK: - Componenti

/// Pulsante azione della scheda luogo (come la fila di pulsanti di Google Maps)
struct ActionChip: View {
    var title: String
    var icon: String
    var prominent: Bool = false
    var accent: Color = .blue
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 14, weight: .bold))
                Text(title).font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .contentShape(Capsule())
            .glassEffect(.regular.tint(prominent ? accent.opacity(0.85) : nil).interactive(), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

enum ShareLinks {
    static func url(for place: Place) -> URL {
        var c = URLComponents(string: "https://maps.apple.com/")!
        c.queryItems = [URLQueryItem(name: "ll", value: String(format: "%.6f,%.6f", place.latitude, place.longitude)),
                        URLQueryItem(name: "q", value: place.name.isEmpty ? place.address : place.name)]
        return c.url!
    }
}

// MARK: - Scheda del luogo

struct PinnedPlacePanel: View {
    @EnvironmentObject var state: AppState
    @Environment(\.openURL) private var openURL

    var body: some View {
        BottomPanel(onDismiss: { state.dismissPanel() }) {
            if let place = state.pinnedPlace {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(place.name.isEmpty ? "Posizione fissata" : place.name)
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            if !state.placeDetails.category.isEmpty {
                                Text(state.placeDetails.category)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color(state.theme.accent).opacity(0.95))
                            }
                            Text(place.address)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.white.opacity(0.45))
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        Menu {
                            Button { state.setHome(place) } label: { Label("Imposta come Casa", systemImage: "house.fill") }
                            Button { state.setWork(place) } label: { Label("Imposta come Lavoro", systemImage: "briefcase.fill") }
                            Button {
                                UIPasteboard.general.string = String(format: "%.6f, %.6f", place.latitude, place.longitude)
                            } label: { Label("Copia coordinate", systemImage: "doc.on.doc") }
                            Button {
                                UIPasteboard.general.string = place.address
                            } label: { Label("Copia indirizzo", systemImage: "doc.on.clipboard") }
                        } label: {
                            GlassCircle(size: 38) {
                                Image(systemName: "ellipsis").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                            }
                        }
                    }

                    // tempi di percorrenza
                    HStack(spacing: 16) {
                        if let t = state.placeDetails.carETA {
                            Label(RouteInfo.duration(t), systemImage: "car.fill")
                        }
                        if let t = state.placeDetails.walkETA {
                            Label(RouteInfo.duration(t), systemImage: "figure.walk")
                        }
                        if let loc = state.location.location {
                            let d = loc.distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
                            Label("\(state.units.short(d))", systemImage: "location.fill")
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .padding(.top, 10)

                    // azioni
                    if state.isLoadingRoute {
                        ProgressView().tint(.white).scaleEffect(1.2)
                            .frame(maxWidth: .infinity).frame(height: 44).padding(.vertical, 14)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            GlassEffectContainer(spacing: 10) {
                                HStack(spacing: 10) {
                                    ActionChip(title: "Indicazioni", icon: "arrow.triangle.turn.up.right.diamond.fill",
                                               prominent: true, accent: Color(state.theme.accent)) {
                                        state.requestDirections()
                                    }
                                    ActionChip(title: "Avvia", icon: "location.north.fill") { state.startDirectly() }
                                    if let phone = state.placeDetails.phone,
                                       let url = URL(string: "tel:" + phone.filter { "+0123456789".contains($0) }) {
                                        ActionChip(title: "Chiama", icon: "phone.fill") { openURL(url) }
                                    }
                                    ActionChip(title: state.isSaved(place) ? "Salvato" : "Salva",
                                               icon: state.isSaved(place) ? "bookmark.fill" : "bookmark") {
                                        state.toggleSave(place)
                                    }
                                    ShareLink(item: ShareLinks.url(for: place),
                                              subject: Text(place.name),
                                              message: Text(place.name.isEmpty ? place.address : place.name)) {
                                        HStack(spacing: 7) {
                                            Image(systemName: "square.and.arrow.up").font(.system(size: 14, weight: .bold))
                                            Text("Condividi").font(.system(size: 15, weight: .semibold))
                                        }
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16)
                                        .frame(height: 44)
                                        .glassEffect(.regular.interactive(), in: Capsule())
                                    }
                                    if let web = state.placeDetails.website {
                                        ActionChip(title: "Sito web", icon: "globe") { openURL(web) }
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.vertical, 14)
                    }

                    if state.explored.contains(place.exploreKey) {
                        DashedEmptyCard(icon: "checkmark.seal.fill",
                                        title: "Hai esplorato questo posto",
                                        subtitle: "Sei stato il primo ad arrivare qui.")
                    } else {
                        DashedEmptyCard(icon: "scope",
                                        title: "Nessuno ha ancora esplorato questo posto",
                                        subtitle: "Vai lì e sii il primo.")
                    }
                }
            }
        }
    }
}

// MARK: - Indicazioni (modalità, alternative, opzioni)

struct DirectionsPanel: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        BottomPanel(onDismiss: { state.dismissPanel() }) {
            VStack(alignment: .leading, spacing: 12) {
                // da → (tappa) → a, con inversione e aggiunta tappa (come Google Maps)
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 0) {
                        Button {
                            state.searchPurpose = .origin
                            state.showSearch = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: state.origin == nil ? "location.north.fill" : "circle.circle")
                                    .font(.system(size: 18, weight: .bold)).foregroundStyle(.white).frame(width: 26)
                                Text(state.origin?.name.isEmpty == false ? state.origin!.name : (state.origin == nil ? "La tua posizione" : "Partenza"))
                                    .font(.system(size: 16, weight: .bold)).foregroundStyle(.white).lineLimit(1)
                                Spacer(minLength: 0)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Rectangle().fill(Color.white.opacity(0.25)).frame(width: 1.5, height: 12)
                            .padding(.leading, 12).padding(.vertical, 3)
                        if let stop = state.stop {
                            HStack(spacing: 14) {
                                Image(systemName: "smallcircle.filled.circle")
                                    .font(.system(size: 16, weight: .bold)).foregroundStyle(.white).frame(width: 26)
                                Text(stop.name.isEmpty ? "Tappa" : stop.name)
                                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                                Spacer(minLength: 0)
                                Button {
                                    state.stop = nil
                                    state.requestDirections()
                                } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(Color.white.opacity(0.5))
                                }
                                .buttonStyle(.plain)
                            }
                            Rectangle().fill(Color.white.opacity(0.25)).frame(width: 1.5, height: 12)
                                .padding(.leading, 12).padding(.vertical, 3)
                        }
                        HStack(spacing: 14) {
                            CloverIcon(color: Color(state.theme.accent), size: 24).frame(width: 26)
                            Text(destinationName).font(.system(size: 16, weight: .bold)).foregroundStyle(.white).lineLimit(1)
                            Spacer(minLength: 0)
                        }
                    }
                    VStack(spacing: 8) {
                        Button { state.swapEnds() } label: {
                            GlassCircle(size: 38) {
                                Image(systemName: "arrow.up.arrow.down").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        if state.stop == nil && state.travelMode != .transit {
                            Button {
                                state.searchPurpose = .stop
                                state.showSearch = true
                            } label: {
                                GlassCircle(size: 38) {
                                    Image(systemName: "plus").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                // orario di partenza
                HStack(spacing: 10) {
                    Image(systemName: "clock").font(.system(size: 14, weight: .bold))
                    Text(state.departure == nil ? "Parti ora" : "Partenza")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    DatePicker("", selection: Binding(get: { state.departure ?? Date() },
                                                      set: { state.departure = $0; state.requestDirections() }),
                               in: Date().addingTimeInterval(-3600)...,
                               displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(Color(state.theme.accent))
                    if state.departure != nil {
                        Button("Ora") {
                            state.departure = nil
                            state.requestDirections()
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(state.theme.accent))
                    }
                }
                .foregroundStyle(.white)

                // schede delle modalità con i tempi
                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(TravelMode.allCases) { mode in
                            Button { state.requestDirections(mode: mode) } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: mode.icon).font(.system(size: 16, weight: .bold))
                                    Text(state.modeETAs[mode].map { RouteInfo.duration($0) } ?? mode.title)
                                        .font(.system(size: 12, weight: .semibold))
                                        .lineLimit(1).minimumScaleFactor(0.8)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .contentShape(Capsule())
                                .glassEffect(.regular.tint(state.travelMode == mode ? Color(state.theme.accent).opacity(0.8) : nil)
                                                .interactive(), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if state.isLoadingRoute {
                    ProgressView().tint(.white).scaleEffect(1.2).frame(maxWidth: .infinity).frame(height: 90)
                } else if let r = state.route, r.etaOnly {
                    // mezzi pubblici: MapKit fornisce solo il tempo stimato
                    VStack(alignment: .leading, spacing: 8) {
                        Text(r.durationText).font(.system(size: 24, weight: .heavy)).foregroundStyle(.white)
                        Text("Arrivo alle \(Formatters.time.string(from: r.arrival)) con i mezzi pubblici")
                            .font(.system(size: 14)).foregroundStyle(Color.white.opacity(0.55))
                        GlassCapsuleButton(title: "Linee e orari in Mappe", icon: "tram.fill", height: 48) {
                            state.openTransitInMaps()
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(Array(state.routes.enumerated()), id: \.element.id) { i, r in
                                Button { state.selectRoute(i) } label: { routeRow(r, index: i) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 190)

                    HStack(spacing: 10) {
                        Menu {
                            if state.travelMode == .car {
                                Button {
                                    state.routeOptions.avoidTolls.toggle(); state.requestDirections()
                                } label: {
                                    if state.routeOptions.avoidTolls { Label("Evita pedaggi", systemImage: "checkmark") }
                                    else { Text("Evita pedaggi") }
                                }
                                Button {
                                    state.routeOptions.avoidHighways.toggle(); state.requestDirections()
                                } label: {
                                    if state.routeOptions.avoidHighways { Label("Evita autostrade", systemImage: "checkmark") }
                                    else { Text("Evita autostrade") }
                                }
                            }
                            Button { state.showSteps = true } label: { Label("Passaggi", systemImage: "list.bullet") }
                        } label: {
                            GlassCircle(size: 50) {
                                Image(systemName: "slider.horizontal.3").font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                            }
                        }
                        Button { state.showSteps = true } label: {
                            GlassCircle(size: 50) {
                                Image(systemName: "list.bullet").font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        GlassCapsuleButton(title: "Avvia", icon: "location.north.fill", height: 50,
                                           tint: Color(state.theme.accent).opacity(0.9), foreground: .white) {
                            state.startNavigation()
                        }
                        .disabled(state.route == nil)
                    }
                }
            }
        }
    }

    private var destinationName: String {
        guard let p = state.pinnedPlace else { return "Destinazione" }
        return p.name.isEmpty ? "Posizione fissata" : p.name
    }

    private func routeRow(_ r: RouteInfo, index: Int) -> some View {
        let selected = index == state.selectedRoute
        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(r.durationText).font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(index == 0 ? Color(hex: 0x4CD964) : .white)
                    if index == 0 && state.routes.count > 1 {
                        Text("Più veloce").font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Capsule().fill(Color(hex: 0x4CD964).opacity(0.22)))
                            .foregroundStyle(Color(hex: 0x4CD964))
                    }
                }
                Text("\(state.units.value(r.distance)) \(state.units.shortLabel)" + (r.name.isEmpty ? "" : " · via \(r.name)"))
                    .font(.system(size: 13)).foregroundStyle(Color.white.opacity(0.6)).lineLimit(1)
                HStack(spacing: 6) {
                    if r.hasTolls { badge("Pedaggi", "eurosign.circle") }
                    if r.hasHighways { badge("Autostrade", "road.lanes") }
                }
                ForEach(r.advisories.prefix(1), id: \.self) { a in
                    Text(a).font(.system(size: 12)).foregroundStyle(Color(hex: 0xFFB020)).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
            Text("Arrivo\n\(Formatters.time.string(from: r.arrival))")
                .font(.system(size: 12, weight: .semibold)).multilineTextAlignment(.trailing)
                .foregroundStyle(Color.white.opacity(0.6))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(selected ? Color(state.theme.accent).opacity(0.35) : nil).interactive(),
                     in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func badge(_ text: String, _ icon: String) -> some View {
        Label(text, systemImage: icon).font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.7))
    }
}

// MARK: - Navigazione

/// Banner in alto con la prossima manovra (come Google Maps)
struct NavigationBanner: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 50)
                    .contentTransition(.symbolEffect(.replace))
                VStack(alignment: .leading, spacing: 2) {
                    if state.isRerouting {
                        Text("Ricalcolo del percorso…").font(.system(size: 20, weight: .heavy))
                    } else {
                        Text(state.units.short(state.progress.toManeuver))
                            .font(.system(size: 28, weight: .heavy))
                            .contentTransition(.numericText())
                        Text(instruction).font(.system(size: 16, weight: .semibold)).lineLimit(2)
                    }
                }
                .foregroundStyle(.white)
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.tint(Color(state.theme.accent).opacity(0.85)),
                         in: RoundedRectangle(cornerRadius: 28, style: .continuous))

            if let then = thenInstruction {
                HStack(spacing: 6) {
                    Text("Poi").font(.system(size: 14, weight: .semibold))
                    Image(systemName: ManeuverIcon.symbol(for: then)).font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14).frame(height: 34)
                .glassEffect(.regular.tint(Color(state.theme.accent).opacity(0.55)), in: Capsule())
            }
        }
        .padding(.horizontal, 12)
        .animation(.easeInOut(duration: 0.25), value: state.progress.nextStep)
    }

    private var steps: [RouteStep] { state.route?.steps ?? [] }

    private var instruction: String {
        steps.indices.contains(state.progress.nextStep) ? steps[state.progress.nextStep].instruction : "Prosegui sul percorso"
    }

    private var icon: String { ManeuverIcon.symbol(for: instruction) }

    private var thenInstruction: String? {
        let i = state.progress.nextStep + 1
        guard steps.indices.contains(i), steps[i].startDistance - steps[i - 1].startDistance < 300 else { return nil }
        return steps[i].instruction
    }
}

struct NavigationPanel: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .bottom) {
                // velocità attuale
                VStack(spacing: 0) {
                    Text("\(state.speedKmh)").font(.system(size: 22, weight: .heavy)).contentTransition(.numericText())
                    Text(state.units == .metric ? "km/h" : "mph").font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .glassEffect(.regular, in: Circle())
                .padding(.leading, 16)

                Spacer()

                GlassEffectContainer(spacing: 10) {
                    VStack(spacing: 10) {
                        Button { state.voiceMuted.toggle() } label: {
                            GlassCircle(size: 46) {
                                Image(systemName: state.voiceMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        Button { state.showRouteOverview() } label: {
                            GlassCircle(size: 46) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        Button { state.cycleTracking() } label: {
                            GlassCircle(size: 46) {
                                Image(systemName: state.tracking == .heading ? "safari.fill" : "location.north.line.fill")
                                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 16)
            }

            BottomPanel(onDismiss: nil) {
                VStack(spacing: 16) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(RouteInfo.duration(state.progress.remainingTime))
                                .font(.system(size: 26, weight: .heavy))
                                .foregroundStyle(Color(hex: 0x4CD964))
                                .contentTransition(.numericText())
                            Text("\(state.units.short(state.progress.remaining)) · arrivo \(Formatters.time.string(from: Date().addingTimeInterval(state.progress.remainingTime)))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.75))
                        }
                        Spacer()
                        // cerca lungo il percorso
                        Button { state.showAlongRoute = true } label: {
                            GlassCircle(size: 44) {
                                Image(systemName: "magnifyingglass").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        // condividi l'orario di arrivo
                        ShareLink(item: state.shareETAText) {
                            GlassCircle(size: 44) {
                                Image(systemName: "square.and.arrow.up").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                            }
                        }
                        Button { state.showSteps = true } label: {
                            GlassCircle(size: 44) {
                                Image(systemName: "list.bullet").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
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
}

/// Elenco dei passaggi del percorso
struct StepsSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let r = state.route {
                    Section {
                        ForEach(Array(r.steps.enumerated()), id: \.element.id) { i, step in
                            HStack(spacing: 14) {
                                Image(systemName: ManeuverIcon.symbol(for: step.instruction))
                                    .font(.system(size: 20, weight: .bold))
                                    .frame(width: 30)
                                    .foregroundStyle(i == state.progress.nextStep && state.panel == .navigating
                                                     ? Color(state.theme.accent) : .primary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(step.instruction).font(.system(size: 16, weight: .semibold))
                                    if step.distance > 0 {
                                        Text(state.units.short(step.distance)).font(.system(size: 13)).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("\(r.durationText) · \(state.units.value(r.distance)) \(state.units.shortLabel)")
                    }
                }
            }
            .navigationTitle("Passaggi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fine") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Risultati di ricerca

struct ResultsPanel: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        BottomPanel(onDismiss: { state.closeResults() }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(state.resultsTitle).font(.system(size: 22, weight: .heavy)).foregroundStyle(.white).lineLimit(1)
                    Spacer()
                    Button { state.closeResults() } label: {
                        GlassCircle(size: 36) {
                            Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                }
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(state.searchResults.enumerated()), id: \.offset) { _, item in
                            Button { state.pin(Place(mapItem: item), item: item) } label: { row(item) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }

    private func row(_ item: MKMapItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name ?? "Luogo").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                let cat = PlaceLookup.categoryName(item.pointOfInterestCategory)
                Text([cat, distance(item)].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.system(size: 13)).foregroundStyle(Color(state.theme.accent)).lineLimit(1)
                Text(Place.formatFull(item.placemark)).font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.45)).lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").foregroundStyle(Color.white.opacity(0.4))
        }
        .padding(.horizontal, 14).frame(height: 70)
        .glassRow(cornerRadius: 20)
    }

    private func distance(_ item: MKMapItem) -> String {
        guard let loc = state.location.location, let l = item.placemark.location else { return "" }
        return state.units.short(loc.distance(from: l))
    }
}

// MARK: - Posizioni salvate (con Casa e Lavoro)

struct SavedPlacesPanel: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        BottomPanel(onDismiss: { state.panel = .none }) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Posizioni salvate")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.bottom, 12)

                HStack(spacing: 10) {
                    shortcut("Casa", "house.fill", state.home)
                    shortcut("Lavoro", "briefcase.fill", state.work)
                }
                .padding(.bottom, 10)

                // dove ho parcheggiato
                HStack(spacing: 10) {
                    Button {
                        if let p = state.parking { state.pin(p) } else { state.saveParking() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "car.fill").font(.system(size: 16, weight: .bold))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(state.parking == nil ? "Salva parcheggio qui" : "Auto parcheggiata")
                                    .font(.system(size: 15, weight: .bold))
                                Text(state.parking?.address ?? "Ricorda dove hai lasciato l'auto")
                                    .font(.system(size: 11)).foregroundStyle(Color.white.opacity(0.5)).lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .glassRow(cornerRadius: 20)
                    }
                    .buttonStyle(.plain)
                    if state.parking != nil {
                        Button { state.parking = nil } label: {
                            GlassCircle(size: 44) {
                                Image(systemName: "trash").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 12)

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
                    .frame(maxHeight: 300)
                    .padding(.bottom, 12)
                }
            }
        }
    }

    private func shortcut(_ title: String, _ icon: String, _ place: Place?) -> some View {
        Button {
            if let p = place { state.go(to: p) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 16, weight: .bold))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 15, weight: .bold))
                    Text(place == nil ? "Da impostare" : "Indicazioni")
                        .font(.system(size: 11)).foregroundStyle(Color.white.opacity(0.5))
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14).frame(height: 56)
            .frame(maxWidth: .infinity)
            .glassRow(cornerRadius: 20)
        }
        .buttonStyle(.plain)
        .opacity(place == nil ? 0.6 : 1)
    }
}

/// Cerca lungo il percorso durante la navigazione (come Google Maps) e aggiungi una tappa
struct AlongRouteSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    private let queries: [(String, String)] = [
        ("Benzinai", "fuelpump.fill"), ("Ristoranti", "fork.knife"), ("Caffè", "cup.and.saucer.fill"),
        ("Supermercati", "cart.fill"), ("Parcheggi", "parkingsign"), ("Ricarica elettrica", "bolt.car.fill")
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(queries.indices, id: \.self) { i in
                            Button { state.searchAlongRoute(queries[i].0) } label: {
                                Label(queries[i].0, systemImage: queries[i].1)
                                    .font(.system(size: 14, weight: .semibold))
                                    .padding(.horizontal, 14).frame(height: 36)
                                    .glassEffect(.regular.tint(state.alongRouteQuery == queries[i].0
                                                               ? Color(state.theme.accent).opacity(0.7) : nil).interactive(),
                                                 in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                if state.isSearchingAlongRoute {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 30)
                } else if state.alongRouteResults.isEmpty {
                    Text(state.alongRouteQuery.isEmpty ? "Scegli cosa cercare lungo il percorso"
                         : "Nessun risultato lungo il percorso")
                        .font(.system(size: 15)).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity).padding(.top, 30)
                } else {
                    List(Array(state.alongRouteResults.enumerated()), id: \.offset) { _, item in
                        Button { state.addStop(item) } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name ?? "Luogo").font(.system(size: 16, weight: .semibold))
                                    Text(Place.formatFull(item.placemark)).font(.system(size: 12))
                                        .foregroundStyle(.secondary).lineLimit(1)
                                }
                                Spacer()
                                Label("Aggiungi", systemImage: "plus.circle.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color(state.theme.accent))
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 8)
            .navigationTitle("Cerca lungo il percorso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Fine") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
