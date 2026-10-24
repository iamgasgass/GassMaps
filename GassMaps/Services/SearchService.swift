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

    func resolve(_ completion: MKLocalSearchCompletion, done: @escaping (MKMapItem?) -> Void) {
        let request = MKLocalSearch.Request(completion: completion)
        if let r = region { request.region = r }
        MKLocalSearch(request: request).start { response, _ in
            DispatchQueue.main.async { done(response?.mapItems.first) }
        }
    }

    func searchCategory(_ name: String) {
        activeCategory = name
        isSearching = true
        categoryResults = []
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = name
        request.resultTypes = .pointOfInterest
        if let r = region { request.region = r }
        MKLocalSearch(request: request).start { [weak self] response, _ in
            DispatchQueue.main.async {
                self?.isSearching = false
                self?.categoryResults = response?.mapItems ?? []
            }
        }
    }

    func searchText(done: @escaping (MKMapItem?) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let r = region { request.region = r }
        MKLocalSearch(request: request).start { response, _ in
            DispatchQueue.main.async { done(response?.mapItems.first) }
        }
    }
}

enum DirectionsService {
    static func route(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D,
                      completion: @escaping (RouteInfo?) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .automobile
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
