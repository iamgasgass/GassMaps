import Foundation
import MapKit

final class SearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query: String = "" {
        didSet { updateQuery() }
    }
    @Published var completions: [MKLocalSearchCompletion] = []
    @Published var categoryResults: [MKMapItem] = []
    @Published var activeCategory: String?
    @Published var isSearching = false

    private let completer = MKLocalSearchCompleter()
    var region: MKCoordinateRegion? {
        didSet { if let r = region { completer.region = r } }
    }

    static let nearbyCategories: [String] = [
        "Stazione di servizio", "Ristorante", "Caffè", "Hotel", "Parcheggio",
        "Farmacia", "Supermercato", "Ospedale", "Bancomat", "Palestra"
    ]

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    private func updateQuery() {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty {
            completions = []
            completer.cancel()
        } else {
            activeCategory = nil
            completer.queryFragment = q
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.completions = Array(completer.results.prefix(20))
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {}

    /// posizione di riferimento per ordinare i risultati per vicinanza
    var userLocation: CLLocation?

    func resolve(_ completion: MKLocalSearchCompletion, done: @escaping (MKMapItem?) -> Void) {
        let request = MKLocalSearch.Request(completion: completion)
        if let r = region { request.region = r }
        let title = completion.title
        let subtitle = completion.subtitle
        let user = userLocation
        MKLocalSearch(request: request).start { response, _ in
            let items = response?.mapItems ?? []
            let best = SearchService.bestMatch(items, title: title, subtitle: subtitle, near: user)
            DispatchQueue.main.async { done(best) }
        }
    }

    /// Sceglie il risultato che corrisponde davvero al suggerimento toccato:
    /// stesso nome e indirizzo coerente con il sottotitolo; a parità, il più vicino.
    static func bestMatch(_ items: [MKMapItem], title: String, subtitle: String, near: CLLocation?) -> MKMapItem? {
        guard !items.isEmpty else { return nil }
        func norm(_ s: String) -> String {
            s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }.joined(separator: " ")
        }
        let t = norm(title)
        let subTokens = Set(norm(subtitle).split(separator: " ").map(String.init).filter { $0.count > 1 })
        func score(_ item: MKMapItem) -> Double {
            var sc = 0.0
            let name = norm(item.name ?? "")
            if name == t { sc += 100 } else if name.contains(t) || t.contains(name) { sc += 40 }
            let pm = item.placemark
            let addr = norm([pm.thoroughfare, pm.subThoroughfare, pm.postalCode, pm.locality,
                             pm.subLocality, pm.administrativeArea, pm.subAdministrativeArea, pm.country,
                             pm.title].compactMap { $0 }.joined(separator: " "))
            let addrTokens = Set(addr.split(separator: " ").map(String.init))
            if !subTokens.isEmpty {
                let hit = Double(subTokens.intersection(addrTokens).count) / Double(subTokens.count)
                sc += hit * 80
            }
            if let near = near, let loc = pm.location {
                sc -= min(loc.distance(from: near) / 1000, 200) * 0.05
            }
            return sc
        }
        return items.max { score($0) < score($1) }
    }

    func searchCategory(_ name: String) {
        let user = userLocation
        activeCategory = name
        isSearching = true
        categoryResults = []
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = name
        request.resultTypes = .pointOfInterest
        if let r = region { request.region = r }
        MKLocalSearch(request: request).start { [weak self] response, _ in
            var items = response?.mapItems ?? []
            if let user = user {
                items.sort { ($0.placemark.location?.distance(from: user) ?? .infinity)
                    < ($1.placemark.location?.distance(from: user) ?? .infinity) }
            }
            DispatchQueue.main.async {
                self?.isSearching = false
                self?.categoryResults = items
            }
        }
    }

    func searchText(done: @escaping (MKMapItem?) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let r = region { request.region = r }
        let q = query
        let user = userLocation
        MKLocalSearch(request: request).start { response, _ in
            let best = SearchService.bestMatch(response?.mapItems ?? [], title: q, subtitle: "", near: user)
            DispatchQueue.main.async { done(best) }
        }
    }
}

enum DirectionsService {
    /// Percorso in auto. Se è disponibile il luogo trovato dalla ricerca (`destinationItem`)
    /// si usa quello, così Apple calcola il percorso verso l'ingresso reale del luogo.
    static func route(from: CLLocationCoordinate2D?, to: CLLocationCoordinate2D, destinationItem: MKMapItem? = nil,
                      completion: @escaping (RouteInfo?) -> Void) {
        let request = MKDirections.Request()
        if let from = from {
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        } else {
            request.source = MKMapItem.forCurrentLocation()
        }
        request.destination = destinationItem ?? MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        MKDirections(request: request).calculate { response, _ in
            guard let route = response?.routes.first else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let poly = route.polyline
            var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: poly.pointCount)
            poly.getCoordinates(&coords, range: NSRange(location: 0, length: poly.pointCount))
            let info = RouteInfo(coordinates: coords, travelTime: route.expectedTravelTime, distance: route.distance)
            DispatchQueue.main.async { completion(info) }
        }
    }
}
