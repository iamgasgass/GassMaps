import Foundation
import CoreLocation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var authorization: CLAuthorizationStatus = .notDetermined
    @Published var placeName: String = "Ricerca posizione..."

    /// richiamato ad ogni nuova posizione (usato dalla navigazione, anche in background)
    var onUpdate: ((CLLocation) -> Void)?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastGeocoded: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 3
        manager.headingFilter = 2
        authorization = manager.authorizationStatus
    }

    func start() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
    }

    /// Durante la navigazione: massima precisione e aggiornamenti anche con lo schermo spento
    func setNavigating(_ on: Bool) {
        manager.desiredAccuracy = on ? kCLLocationAccuracyBestForNavigation : kCLLocationAccuracyBest
        manager.distanceFilter = on ? kCLDistanceFilterNone : 3
        manager.activityType = on ? .automotiveNavigation : .other
        manager.allowsBackgroundLocationUpdates = on
        manager.showsBackgroundLocationIndicator = on
        manager.pausesLocationUpdatesAutomatically = !on
        manager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorization = manager.authorizationStatus
        }
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // scarta posizioni non valide, troppo imprecise o vecchie (es. la prima cache del GPS)
        guard let loc = locations.last(where: { $0.horizontalAccuracy >= 0 && $0.horizontalAccuracy < 120
                                                && abs($0.timestamp.timeIntervalSinceNow) < 15 }) else { return }
        DispatchQueue.main.async {
            self.location = loc
            self.onUpdate?(loc)
        }
        if lastGeocoded == nil || loc.distance(from: lastGeocoded!) > 250 {
            lastGeocoded = loc
            geocoder.reverseGeocodeLocation(loc, preferredLocale: Locale(identifier: "it_IT")) { [weak self] placemarks, _ in
                guard let pm = placemarks?.first else { return }
                let city = pm.locality ?? pm.name ?? ""
                let area = pm.subAdministrativeArea ?? pm.administrativeArea ?? pm.country ?? ""
                let text = [city, area].filter { !$0.isEmpty }.joined(separator: ", ")
                DispatchQueue.main.async {
                    if !text.isEmpty { self?.placeName = text }
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

enum Geocoder {
    static func reverse(_ coordinate: CLLocationCoordinate2D, completion: @escaping (String) -> Void) {
        let geocoder = CLGeocoder()
        let loc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(loc, preferredLocale: Locale(identifier: "it_IT")) { placemarks, _ in
            let text = placemarks?.first.map { Place.formatFull($0) }
                ?? String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
            DispatchQueue.main.async { completion(text) }
        }
    }
}
