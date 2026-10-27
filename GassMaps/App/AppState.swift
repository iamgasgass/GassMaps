import SwiftUI
import CoreLocation
import MapKit

enum AppPhase: Equatable {
    case splash, map
}

enum BottomPanelKind: Equatable {
    case none, pinned, directions, navigating, saved, results
}

enum TrackingState: Equatable {
    case none, follow, heading
}

/// Cosa sta scegliendo l'utente nella ricerca
enum SearchPurpose: Equatable {
    case destination, origin, stop
}

final class AppState: ObservableObject {
    // MARK: Navigazione schermate
    @Published var phase: AppPhase = .splash
    @Published var showHeader = true
    @Published var showSearch = false
    @Published var showSettings = false
    @Published var showMapSelection = false
    @Published var showSteps = false

    // MARK: Tema
    @Published var themeIndex: Int {
        didSet { UserDefaults.standard.set(themeIndex, forKey: Keys.theme) }
    }
    var theme: MapTheme { Themes.all[themeIndex] }

    // MARK: Pannelli / mappa
    @Published var panel: BottomPanelKind = .none
    @Published var pinnedPlace: Place?
    @Published var placeDetails = PlaceDetails()
    /// luogo esatto restituito dalla ricerca (usato per un percorso preciso verso l'ingresso)
    var destinationItem: MKMapItem?
    @Published var isLoadingRoute = false
    @Published var tracking: TrackingState = .follow
    @Published var routeError: String?
    @Published var mapHeading: Double = 0

    // MARK: Indicazioni (come Google Maps)
    @Published var travelMode: TravelMode = .car
    @Published var routes: [RouteInfo] = []
    @Published var selectedRoute = 0
    @Published var modeETAs: [TravelMode: TimeInterval] = [:]
    @Published var routeOptions: RouteOptions {
        didSet {
            if let d = try? JSONEncoder().encode(routeOptions) { UserDefaults.standard.set(d, forKey: Keys.options) }
        }
    }
    var route: RouteInfo? { routes.indices.contains(selectedRoute) ? routes[selectedRoute] : nil }
    /// indici (in `routes`) dei percorsi alternativi disegnati in grigio
    var alternativeIndices: [Int] = []

    // MARK: Navigazione svolta per svolta
    @Published var progress = RouteProgress()
    @Published var speedKmh: Int = 0
    @Published var isRerouting = false
    @Published var voiceMuted = false {
        didSet {
            VoiceGuide.shared.muted = voiceMuted
            if voiceMuted { VoiceGuide.shared.stop() }
        }
    }
    @Published var arrived = false
    private var cumulative: [Double] = []
    private var lastProjectionIndex = 0
    private var announced: Set<String> = []
    private var offRouteCount = 0
    private var lastReroute = Date.distantPast

    // MARK: Partenza personalizzata, tappa, orario (come Google Maps)
    @Published var searchPurpose: SearchPurpose = .destination
    @Published var origin: Place? = nil
    @Published var stop: Place? = nil
    @Published var departure: Date? = nil

    // MARK: Risultati di ricerca sulla mappa
    @Published var searchResults: [MKMapItem] = []
    @Published var resultsTitle = ""
    @Published var showSearchArea = false
    private var resultsCenter: CLLocation?

    // MARK: Ricerca lungo il percorso
    @Published var alongRouteResults: [MKMapItem] = []
    @Published var alongRouteQuery = ""
    @Published var showAlongRoute = false
    @Published var isSearchingAlongRoute = false

    // MARK: Dati utente
    @Published var saved: [Place] = [] { didSet { persist(saved, Keys.saved) } }
    @Published var history: [Place] = [] { didSet { persist(history, Keys.history) } }
    @Published var home: Place? = nil { didSet { persistOne(home, Keys.home) } }
    @Published var work: Place? = nil { didSet { persistOne(work, Keys.work) } }
    /// dove ho parcheggiato
    @Published var parking: Place? = nil { didSet { persistOne(parking, Keys.parking) } }
    @Published var explored: Set<String> = [] {
        didSet { UserDefaults.standard.set(Array(explored), forKey: Keys.explored) }
    }
    @Published var units: DistanceUnit {
        didSet { UserDefaults.standard.set(units.rawValue, forKey: Keys.units) }
    }

    let location = LocationManager()
    let map = MapController()

    enum Keys {
        static let theme = "gm.theme"
        static let saved = "gm.saved"
        static let history = "gm.history"
        static let explored = "gm.explored"
        static let units = "gm.units"
        static let home = "gm.home"
        static let work = "gm.work"
        static let options = "gm.routeOptions"
        static let parking = "gm.parking"
    }

    init() {
        let d = UserDefaults.standard
        if d.object(forKey: Keys.theme) != nil {
            themeIndex = min(max(d.integer(forKey: Keys.theme), 0), Themes.all.count - 1)
        } else {
            themeIndex = Themes.defaultIndex
        }
        units = DistanceUnit(rawValue: d.string(forKey: Keys.units) ?? "") ?? .metric
        routeOptions = (d.data(forKey: Keys.options)).flatMap { try? JSONDecoder().decode(RouteOptions.self, from: $0) }
            ?? RouteOptions()
        saved = AppState.load(Keys.saved)
        history = AppState.load(Keys.history)
        home = AppState.loadOne(Keys.home)
        work = AppState.loadOne(Keys.work)
        parking = AppState.loadOne(Keys.parking)
        explored = Set(d.stringArray(forKey: Keys.explored) ?? [])
        map.state = self
        location.onUpdate = { [weak self] loc in self?.locationUpdated(loc) }
    }

    private func persist(_ places: [Place], _ key: String) {
        if let data = try? JSONEncoder().encode(places) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func persistOne(_ place: Place?, _ key: String) {
        if let p = place, let data = try? JSONEncoder().encode(p) {
            UserDefaults.standard.set(data, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private static func load(_ key: String) -> [Place] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([Place].self, from: data) else { return [] }
        return list
    }

    private static func loadOne(_ key: String) -> Place? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Place.self, from: data)
    }

    // MARK: - Avvio

    func finishSplash() {
        phase = .map
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.easeInOut(duration: 0.45)) { self.showHeader = false }
        }
    }

    // MARK: - Luoghi

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

    func pin(_ place: Place, fly: Bool = true, item: MKMapItem? = nil) {
        clearRoute()
        origin = nil
        stop = nil
        departure = nil
        searchPurpose = .destination
        destinationItem = item
        pinnedPlace = place
        panel = .pinned
        map.showPin(place)
        if fly { map.fly(to: place.coordinate) }
        loadDetails(for: place, item: item)
    }

    /// Scheda del luogo: categoria, telefono, sito e tempi di percorrenza (come Google Maps)
    func loadDetails(for place: Place, item: MKMapItem?) {
        placeDetails = PlaceDetails()
        if let item = item {
            applyDetails(item)
        } else if !place.name.isEmpty {
            PlaceLookup.find(name: place.name, near: place.coordinate) { [weak self] found in
                guard let self = self, self.pinnedPlace?.id == place.id, let found = found else { return }
                self.destinationItem = found
                self.applyDetails(found)
                if var p = self.pinnedPlace, p.address.isEmpty || p.address.hasPrefix("Ricerca") {
                    p.address = Place.formatFull(found.placemark)
                    self.pinnedPlace = p
                }
            }
        }
        for mode in [TravelMode.car, .walk] {
            DirectionsService.eta(to: place.coordinate, destinationItem: item, mode: mode) { [weak self] t in
                guard let self = self, self.pinnedPlace?.id == place.id else { return }
                if mode == .car { self.placeDetails.carETA = t } else { self.placeDetails.walkETA = t }
            }
        }
    }

    private func applyDetails(_ item: MKMapItem) {
        placeDetails.category = PlaceLookup.categoryName(item.pointOfInterestCategory)
        placeDetails.phone = item.phoneNumber
        placeDetails.website = item.url
    }

    /// Tocco su un'icona della mappa
    func openPOI(name: String, coordinate: CLLocationCoordinate2D) {
        let place = Place(name: name, address: "", coordinate: coordinate)
        pin(place, fly: true)
        Geocoder.reverse(coordinate) { [weak self] address in
            guard let self = self, var p = self.pinnedPlace, p.id == place.id, p.address.isEmpty else { return }
            p.address = address
            self.pinnedPlace = p
        }
    }

    func select(mapItem: MKMapItem) {
        let place = Place(mapItem: mapItem)
        addToHistory(place)
        choose(place, item: mapItem)
    }

    /// Luogo scelto dalla ricerca: destinazione, punto di partenza o tappa
    func choose(_ place: Place, item: MKMapItem? = nil) {
        showSearch = false
        switch searchPurpose {
        case .origin:
            searchPurpose = .destination
            origin = place
            requestDirections()
        case .stop:
            searchPurpose = .destination
            stop = place
            if panel == .navigating, let loc = location.location { reroute(from: loc) } else { requestDirections() }
        case .destination:
            map.clearResults()
            searchResults = []
            pin(place, item: item)
        }
    }

    /// Inverte partenza e destinazione
    func swapEnds() {
        guard let dest = pinnedPlace else { return }
        let here = location.location.map { Place(name: "La tua posizione", address: "", coordinate: $0.coordinate) }
        guard let newDest = origin ?? here else { return }
        let keepStop = stop
        let newOrigin: Place? = dest
        pinnedPlace = newDest
        destinationItem = nil
        origin = newOrigin
        stop = keepStop
        if origin?.name == "La tua posizione" { origin = nil }
        map.showPin(newDest)
        requestDirections()
    }

    func saveParking() {
        guard let l = location.location else { routeError = "Posizione non disponibile"; return }
        let place = Place(name: "Auto parcheggiata", address: "Salvata alle \(Formatters.time.string(from: Date()))",
                          coordinate: l.coordinate)
        parking = place
        Geocoder.reverse(l.coordinate) { [weak self] address in
            guard let self = self, var p = self.parking, p.id == place.id else { return }
            p.address = address
            self.parking = p
        }
    }

    func addToHistory(_ place: Place) {
        var h = history.filter { !($0.name == place.name && $0.address == place.address) }
        h.insert(place, at: 0)
        history = Array(h.prefix(15))
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

    func setHome(_ place: Place) { var p = place; if p.name.isEmpty { p.name = "Casa" }; home = p }
    func setWork(_ place: Place) { var p = place; if p.name.isEmpty { p.name = "Lavoro" }; work = p }

    /// Percorso immediato verso Casa / Lavoro
    func go(to place: Place) {
        showSearch = false
        pin(place, fly: false)
        requestDirections()
    }

    // MARK: - Risultati di ricerca (categorie, "Ristoranti vicino a te"…)

    func showResults(_ items: [MKMapItem], title: String) {
        guard !items.isEmpty else {
            routeError = "Nessun risultato per \"\(title)\" in questa zona"
            return
        }
        showSearch = false
        clearRoute()
        pinnedPlace = nil
        map.removePin()
        searchResults = items
        resultsTitle = title
        panel = .results
        showSearchArea = false
        let coords = items.map { $0.placemark.coordinate }
        let lat = coords.map { $0.latitude }.reduce(0, +) / Double(coords.count)
        let lon = coords.map { $0.longitude }.reduce(0, +) / Double(coords.count)
        resultsCenter = CLLocation(latitude: lat, longitude: lon)
        map.showResults(items)
    }

    func searchCategory(_ query: String, inVisibleArea: Bool = false) {
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = query
        req.resultTypes = [.pointOfInterest, .address]
        if inVisibleArea, let r = map.visibleRegion {
            req.region = r
        } else if let c = location.location?.coordinate ?? map.centerCoordinate {
            req.region = MKCoordinateRegion(center: c, latitudinalMeters: 6000, longitudinalMeters: 6000)
        }
        let user = location.location
        MKLocalSearch(request: req).start { [weak self] response, _ in
            var items = response?.mapItems ?? []
            if let user = user {
                items.sort { ($0.placemark.location?.distance(from: user) ?? .infinity)
                    < ($1.placemark.location?.distance(from: user) ?? .infinity) }
            }
            DispatchQueue.main.async { self?.showResults(items, title: query) }
        }
    }

    /// La mappa è stata spostata lontano dai risultati → mostra "Cerca in questa zona"
    func mapMoved() {
        guard panel == .results, let c = map.centerCoordinate, let rc = resultsCenter else { return }
        let moved = CLLocation(latitude: c.latitude, longitude: c.longitude).distance(from: rc) > 900
        if moved != showSearchArea { showSearchArea = moved }
    }

    func searchThisArea() {
        showSearchArea = false
        searchCategory(resultsTitle, inVisibleArea: true)
    }

    func closeResults() {
        searchResults = []
        map.clearResults()
        panel = .none
        map.setBottomInset(0)
    }

    // MARK: - Indicazioni

    func requestDirections(mode: TravelMode? = nil) {
        guard let dest = pinnedPlace else { return }
        if let mode = mode { travelMode = mode }
        let from = origin?.coordinate ?? location.location?.coordinate
        isLoadingRoute = true
        let requested = travelMode
        let handler: ([RouteInfo]) -> Void = { [weak self] infos in
            guard let self = self, self.travelMode == requested else { return }
            self.isLoadingRoute = false
            guard !infos.isEmpty else {
                self.routeError = requested == .transit
                    ? "Nessun collegamento con i mezzi pubblici disponibile per questa destinazione"
                    : "Impossibile calcolare il percorso"
                if self.panel != .directions { return }
                self.routes = []
                self.map.clearRoute()
                return
            }
            self.routes = infos
            self.selectedRoute = 0
            self.panel = .directions
            self.drawRoutes(overview: true)
        }
        if let stop = stop, requested != .transit {
            DirectionsService.routesVia(from: from, stop: stop, to: dest.coordinate, destinationItem: destinationItem,
                                        mode: requested, options: routeOptions, departure: departure, completion: handler)
        } else {
            DirectionsService.routes(from: from, to: dest.coordinate, destinationItem: destinationItem,
                                     mode: requested, options: routeOptions, departure: departure, completion: handler)
        }
        // tempi per tutte le modalità (come le schede in alto di Google Maps)
        for m in TravelMode.allCases {
            DirectionsService.eta(from: from, to: dest.coordinate, destinationItem: destinationItem, mode: m,
                                  departure: departure) { [weak self] t in
                self?.modeETAs[m] = t
            }
        }
    }

    func selectRoute(_ index: Int) {
        guard routes.indices.contains(index) else { return }
        selectedRoute = index
        drawRoutes(overview: false)
    }

    private func drawRoutes(overview: Bool) {
        guard let main = route, !main.etaOnly else {
            map.clearRoute()
            return
        }
        let altPairs = routes.enumerated().filter { $0.offset != selectedRoute && $0.element.coordinates.count > 1 }
        alternativeIndices = altPairs.map { $0.offset }
        map.showRoute(main.coordinates, alternatives: altPairs.map { $0.element.coordinates }, overview: overview)
    }

    /// Indicazioni per i mezzi pubblici nell'app Mappe di Apple (MapKit non fornisce il tracciato dei mezzi)
    func openTransitInMaps() {
        guard let dest = pinnedPlace else { return }
        let item = destinationItem ?? MKMapItem(placemark: MKPlacemark(coordinate: dest.coordinate))
        if item.name == nil { item.name = dest.name.isEmpty ? "Destinazione" : dest.name }
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeTransit])
    }

    /// "Avvia" direttamente dalla scheda del luogo
    func startDirectly() {
        guard let dest = pinnedPlace else { return }
        isLoadingRoute = true
        DirectionsService.routes(from: location.location?.coordinate, to: dest.coordinate,
                                 destinationItem: destinationItem, mode: travelMode == .transit ? .car : travelMode,
                                 options: routeOptions) { [weak self] infos in
            guard let self = self else { return }
            self.isLoadingRoute = false
            guard !infos.isEmpty else { self.routeError = "Impossibile calcolare il percorso"; return }
            self.routes = infos
            self.selectedRoute = 0
            self.drawRoutes(overview: false)
            self.startNavigation()
        }
    }

    // MARK: - Navigazione svolta per svolta

    func startNavigation() {
        guard let r = route, !r.etaOnly else { return }
        // mostra solo il percorso scelto
        map.showRoute(r.coordinates, alternatives: [], overview: false)
        cumulative = RouteMath.cumulative(r.coordinates)
        lastProjectionIndex = 0
        announced = []
        offRouteCount = 0
        arrived = false
        progress = RouteProgress(traveled: 0, remaining: r.distance, offset: 0,
                                 nextStep: r.steps.count > 1 ? 1 : 0,
                                 toManeuver: r.steps.count > 1 ? r.steps[1].startDistance : r.distance,
                                 remainingTime: r.travelTime)
        panel = .navigating
        location.setNavigating(true)
        UIApplication.shared.isIdleTimerDisabled = true
        map.startNavigation()
        if let first = r.steps.first?.instruction {
            VoiceGuide.shared.speak(first)
        }
        if let loc = location.location { updateNavigation(loc) }
    }

    func endNavigation() {
        location.setNavigating(false)
        UIApplication.shared.isIdleTimerDisabled = false
        VoiceGuide.shared.stop()
        showSteps = false
        clearRoute()
        panel = pinnedPlace == nil ? .none : .pinned
        map.recenter()
    }

    func clearRoute() {
        routes = []
        selectedRoute = 0
        map.clearRoute()
    }

    func dismissPanel() {
        if panel == .navigating { return }
        if panel == .directions {
            clearRoute()
            origin = nil
            stop = nil
            departure = nil
            panel = .pinned
            if let p = pinnedPlace { map.fly(to: p.coordinate) }
            return
        }
        if panel == .pinned && !searchResults.isEmpty {
            pinnedPlace = nil
            map.removePin()
            panel = .results
            map.showResults(searchResults)
            return
        }
        panel = .none
        pinnedPlace = nil
        map.removePin()
        map.setBottomInset(0)
    }

    /// Chiamato ad ogni aggiornamento GPS (anche in background durante la navigazione)
    func locationUpdated(_ loc: CLLocation) {
        if let p = pinnedPlace, loc.distance(from: CLLocation(latitude: p.latitude, longitude: p.longitude)) < 60 {
            if !explored.contains(p.exploreKey) { explored.insert(p.exploreKey) }
        }
        if panel == .navigating { updateNavigation(loc) }
    }

    private func updateNavigation(_ loc: CLLocation) {
        guard let r = route, r.coordinates.count > 1, cumulative.count == r.coordinates.count else { return }
        speedKmh = loc.speed >= 0 ? Int((loc.speed * 3.6).rounded()) : 0

        var proj = RouteMath.project(loc.coordinate, on: r.coordinates, cumulative: cumulative, from: lastProjectionIndex)
        if proj.offset > 40 {
            proj = RouteMath.project(loc.coordinate, on: r.coordinates, cumulative: cumulative, from: 0)
        }
        lastProjectionIndex = proj.index
        let total = cumulative.last ?? r.distance
        let traveled = proj.along
        let remaining = max(0, total - traveled)

        // prossima manovra
        var next = r.steps.count
        for (i, step) in r.steps.enumerated() where i > 0 && step.startDistance > traveled + 3 {
            next = i
            break
        }
        let toManeuver = next < r.steps.count ? r.steps[next].startDistance - traveled : remaining
        let ratio = total > 0 ? remaining / total : 0

        progress = RouteProgress(traveled: traveled, remaining: remaining, offset: proj.offset,
                                 nextStep: min(next, max(r.steps.count - 1, 0)), toManeuver: max(0, toManeuver),
                                 remainingTime: r.travelTime * ratio)

        // tappa raggiunta
        if let s = stop, loc.distance(from: CLLocation(latitude: s.latitude, longitude: s.longitude)) < 40 {
            stop = nil
            VoiceGuide.shared.speak("Hai raggiunto la tappa \(s.name)")
        }

        // arrivo
        if remaining < 25 && !arrived {
            arrived = true
            VoiceGuide.shared.speak("Sei arrivato a destinazione")
            if let p = pinnedPlace { explored.insert(p.exploreKey) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                guard let self = self, self.panel == .navigating else { return }
                self.endNavigation()
            }
            return
        }

        // guida vocale: avvisi prima della manovra
        if next < r.steps.count {
            let instruction = r.steps[next].instruction
            let thresholds: [Double] = r.mode == .walk ? [120, 25] : [900, 350, 60]
            for th in thresholds.reversed() where toManeuver <= th {
                let key = "\(next)-\(Int(th))"
                if !announced.contains(key) {
                    // registra anche le soglie più lontane per non ripeterle
                    for t2 in thresholds where t2 >= th { announced.insert("\(next)-\(Int(t2))") }
                    if th == thresholds.last {
                        VoiceGuide.shared.speak(instruction)
                    } else {
                        VoiceGuide.shared.speak("Tra \(units.spoken(toManeuver)), \(lowerFirst(instruction))")
                    }
                }
                break
            }
        }

        // fuori percorso → ricalcolo automatico
        let limit: Double = r.mode == .walk ? 40 : 55
        if proj.offset > limit && loc.horizontalAccuracy < 60 {
            offRouteCount += 1
        } else {
            offRouteCount = 0
        }
        if offRouteCount >= 2 && Date().timeIntervalSince(lastReroute) > 8 {
            reroute(from: loc)
        }
    }

    private func lowerFirst(_ s: String) -> String {
        guard let f = s.first else { return s }
        return f.lowercased() + s.dropFirst()
    }

    private func reroute(from loc: CLLocation) {
        guard let dest = pinnedPlace, let mode = route?.mode else { return }
        lastReroute = Date()
        offRouteCount = 0
        isRerouting = true
        VoiceGuide.shared.speak("Ricalcolo del percorso")
        let done: ([RouteInfo]) -> Void = { [weak self] infos in
            guard let self = self, self.panel == .navigating else { return }
            self.isRerouting = false
            guard let first = infos.first else { return }
            self.routes = [first]
            self.selectedRoute = 0
            self.cumulative = RouteMath.cumulative(first.coordinates)
            self.lastProjectionIndex = 0
            self.announced = []
            self.map.showRoute(first.coordinates, alternatives: [], overview: false)
            if let l = self.location.location { self.updateNavigation(l) }
        }
        if let s = stop {
            DirectionsService.routesVia(from: loc.coordinate, stop: s, to: dest.coordinate, destinationItem: destinationItem,
                                        mode: mode, options: routeOptions, departure: nil, completion: done)
        } else {
            DirectionsService.routes(from: loc.coordinate, to: dest.coordinate, destinationItem: destinationItem,
                                     mode: mode, options: routeOptions, alternatives: false, completion: done)
        }
    }

    // MARK: - Cerca lungo il percorso (benzinai, ristoranti… senza allontanarsi)

    func searchAlongRoute(_ query: String) {
        guard let r = route, r.coordinates.count > 1, cumulative.count == r.coordinates.count else { return }
        alongRouteQuery = query
        isSearchingAlongRoute = true
        alongRouteResults = []
        let startIdx = max(0, lastProjectionIndex)
        let traveled = progress.traveled
        var ahead: [CLLocationCoordinate2D] = []
        for i in startIdx..<r.coordinates.count where cumulative[i] - traveled < 30_000 {
            ahead.append(r.coordinates[i])
        }
        guard let first = ahead.first else { isSearchingAlongRoute = false; return }
        var minLat = first.latitude, maxLat = first.latitude, minLon = first.longitude, maxLon = first.longitude
        for c in ahead {
            minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = query
        req.resultTypes = .pointOfInterest
        req.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(latitudeDelta: max(0.02, (maxLat - minLat) * 1.2), longitudeDelta: max(0.02, (maxLon - minLon) * 1.2)))
        let coords = r.coordinates, cum = cumulative
        MKLocalSearch(request: req).start { [weak self] response, _ in
            let items = (response?.mapItems ?? []).compactMap { item -> (MKMapItem, Double)? in
                let p = RouteMath.project(item.placemark.coordinate, on: coords, cumulative: cum, from: 0)
                guard p.offset < 600, p.along > traveled else { return nil }
                return (item, p.along)
            }
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
            DispatchQueue.main.async {
                self?.isSearchingAlongRoute = false
                self?.alongRouteResults = Array(items.prefix(20))
            }
        }
    }

    /// Aggiunge una tappa durante la navigazione e ricalcola
    func addStop(_ item: MKMapItem) {
        stop = Place(mapItem: item)
        showAlongRoute = false
        if let loc = location.location { reroute(from: loc) }
    }

    /// Testo da condividere con l'orario di arrivo
    var shareETAText: String {
        let dest = pinnedPlace.map { $0.name.isEmpty ? $0.address : $0.name } ?? "destinazione"
        let eta = Formatters.time.string(from: Date().addingTimeInterval(progress.remainingTime))
        return "Sto arrivando a \(dest): arrivo previsto alle \(eta) (\(RouteInfo.duration(progress.remainingTime)))."
    }

    func showRouteOverview() {
        guard let r = route else { return }
        map.showRoute(r.coordinates, alternatives: [], overview: true)
    }

    func cycleTracking() {
        switch tracking {
        case .follow: map.setTracking(.heading)
        case .heading: map.setTracking(.follow)
        case .none:
            if panel == .navigating { map.startNavigation() } else { map.setTracking(.follow) }
        }
    }

    func deleteAllData() {
        saved = []
        history = []
        explored = []
        home = nil
        work = nil
        parking = nil
        themeIndex = Themes.defaultIndex
        units = .metric
        routeOptions = RouteOptions()
    }
}
