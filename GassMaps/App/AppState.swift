import SwiftUI
import CoreLocation
import MapKit

enum AppPhase: Equatable {
    case splash, map
}

enum BottomPanelKind: Equatable {
    case none, pinned, directions, navigating, saved
}

enum TrackingState: Equatable {
    case none, follow, heading
}

final class AppState: ObservableObject {
    // MARK: Navigazione schermate
    @Published var phase: AppPhase = .splash
    @Published var showHeader = true
    @Published var showSearch = false
    @Published var showSettings = false
    @Published var showMapSelection = false

    // MARK: Tema
    @Published var themeIndex: Int {
        didSet { UserDefaults.standard.set(themeIndex, forKey: Keys.theme) }
    }
    var theme: MapTheme { Themes.all[themeIndex] }

    // MARK: Pannelli / mappa
    @Published var panel: BottomPanelKind = .none
    @Published var pinnedPlace: Place?
    @Published var route: RouteInfo?
    @Published var isLoadingRoute = false
    @Published var tracking: TrackingState = .follow
    @Published var routeError: String?

    // MARK: Dati utente
    @Published var saved: [Place] = [] { didSet { persist(saved, Keys.saved) } }
    @Published var history: [Place] = [] { didSet { persist(history, Keys.history) } }
    @Published var explored: Set<String> = [] {
        didSet { UserDefaults.standard.set(Array(explored), forKey: Keys.explored) }
    }
    @Published var units: DistanceUnit {
        didSet { UserDefaults.standard.set(units.rawValue, forKey: Keys.units) }
    }

    let location = LocationManager()
    let map = MapController()

    private var lastRerouteLocation: CLLocation?
    private var lastRerouteDate = Date.distantPast

    enum Keys {
        static let theme = "gm.theme"
        static let saved = "gm.saved"
        static let history = "gm.history"
        static let explored = "gm.explored"
        static let units = "gm.units"
    }

    init() {
        let d = UserDefaults.standard
        if d.object(forKey: Keys.theme) != nil {
            themeIndex = min(max(d.integer(forKey: Keys.theme), 0), Themes.all.count - 1)
        } else {
            themeIndex = Themes.defaultIndex
        }
        units = DistanceUnit(rawValue: d.string(forKey: Keys.units) ?? "") ?? .metric
        saved = AppState.load(Keys.saved)
        history = AppState.load(Keys.history)
        explored = Set(d.stringArray(forKey: Keys.explored) ?? [])
        map.state = self
    }

    private func persist(_ places: [Place], _ key: String) {
        if let data = try? JSONEncoder().encode(places) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func load(_ key: String) -> [Place] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([Place].self, from: data) else { return [] }
        return list
    }

    // MARK: - Azioni

    func finishSplash() {
        phase = .map
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.easeInOut(duration: 0.45)) { self.showHeader = false }
        }
    }

    /// Pulsante centrale: fissa la posizione al centro della mappa / posizione attuale
    func pinCurrentPosition() {
        let coord = map.centerCoordinate ?? location.location?.coordinate
        guard let c = coord else { return }
        pin(Place(name: "", address: "Ricerca indirizzo...", coordinate: c), fly: false)
        Geocoder.reverse(c) { [weak self] address in
            guard let self = self, var p = self.pinnedPlace, p.latitude == c.latitude else { return }
            p.address = address
            self.pinnedPlace = p
        }
    }

    func pin(_ place: Place, fly: Bool = true) {
        clearRoute()
        pinnedPlace = place
        panel = .pinned
        map.showPin(place)
        if fly { map.fly(to: place.coordinate) }
    }

    func select(mapItem: MKMapItem) {
        let place = Place(mapItem: mapItem)
        addToHistory(place)
        showSearch = false
        pin(place)
    }

    func addToHistory(_ place: Place) {
        var h = history.filter { !($0.name == place.name && $0.address == place.address) }
        h.insert(place, at: 0)
        history = Array(h.prefix(12))
    }

    func toggleSave(_ place: Place) {
        if let idx = saved.firstIndex(where: { $0.exploreKey == place.exploreKey && $0.name == place.name }) {
            saved.remove(at: idx)
        } else {
            var p = place
            if p.name.isEmpty { p.name = p.address.components(separatedBy: ",").first ?? "Posizione" }
            saved.insert(p, at: 0)
        }
    }

    func isSaved(_ place: Place) -> Bool {
        saved.contains { $0.exploreKey == place.exploreKey }
    }

    func requestDirections() {
        guard let dest = pinnedPlace else { return }
        guard let from = location.location?.coordinate else {
            routeError = "Posizione non disponibile"
            return
        }
        isLoadingRoute = true
        DirectionsService.route(from: from, to: dest.coordinate) { [weak self] info in
            guard let self = self else { return }
            self.isLoadingRoute = false
            guard let info = info else {
                self.routeError = "Impossibile calcolare il percorso"
                return
            }
            self.route = info
            self.panel = .directions
            self.map.showRoute(info.coordinates, overview: true)
        }
    }

    func startNavigation() {
        guard route != nil else { return }
        panel = .navigating
        lastRerouteLocation = location.location
        lastRerouteDate = Date()
        map.startNavigation()
    }

    func endNavigation() {
        clearRoute()
        panel = pinnedPlace == nil ? .none : .pinned
        map.recenter()
    }

    func clearRoute() {
        route = nil
        map.clearRoute()
    }

    func dismissPanel() {
        if panel == .navigating { return }
        if panel == .directions {
            clearRoute()
            panel = .pinned
            if let p = pinnedPlace { map.fly(to: p.coordinate) }
            return
        }
        panel = .none
        pinnedPlace = nil
        map.removePin()
        map.setBottomInset(0)
    }

    /// Chiamato ad ogni aggiornamento di posizione
    func locationUpdated(_ loc: CLLocation) {
        if let p = pinnedPlace, loc.distance(from: CLLocation(latitude: p.latitude, longitude: p.longitude)) < 60 {
            if !explored.contains(p.exploreKey) { explored.insert(p.exploreKey) }
            if panel == .navigating { endNavigation() }
        }
        guard panel == .navigating, let dest = pinnedPlace else { return }
        let moved = lastRerouteLocation.map { loc.distance(from: $0) } ?? .infinity
        if moved > 150 || Date().timeIntervalSince(lastRerouteDate) > 30 {
            lastRerouteLocation = loc
            lastRerouteDate = Date()
            DirectionsService.route(from: loc.coordinate, to: dest.coordinate) { [weak self] info in
                guard let self = self, self.panel == .navigating, let info = info else { return }
                self.route = info
                self.map.showRoute(info.coordinates, overview: false)
            }
        }
    }

    func cycleTracking() {
        switch tracking {
        case .follow: map.setTracking(.heading)
        case .heading: map.setTracking(.follow)
        case .none: map.setTracking(.follow)
        }
    }

    func deleteAllData() {
        saved = []
        history = []
        explored = []
        themeIndex = Themes.defaultIndex
        units = .metric
    }
}
