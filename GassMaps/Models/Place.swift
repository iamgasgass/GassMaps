import Foundation
import CoreLocation
import MapKit

struct Place: Codable, Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Chiave usata per ricordare i luoghi esplorati (arrotondata a ~10 m)
    var exploreKey: String {
        String(format: "%.4f,%.4f", latitude, longitude)
    }

    init(name: String, address: String, coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.address = address
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    init(mapItem: MKMapItem) {
        let pm = mapItem.placemark
        self.init(name: mapItem.name ?? pm.name ?? "Posizione",
                  address: Place.formatShort(pm),
                  coordinate: pm.coordinate)
    }

    /// "84131 Salerno, Italia"
    static func formatShort(_ pm: CLPlacemark) -> String {
        var parts: [String] = []
        let city = [pm.postalCode, pm.locality].compactMap { $0 }.joined(separator: " ")
        if !city.isEmpty { parts.append(city) }
        if let country = pm.country { parts.append(country) }
        return parts.joined(separator: ", ")
    }

    /// "Via Trento 47, 84092 Bellizzi Salerno, Italy"
    static func formatFull(_ pm: CLPlacemark) -> String {
        var parts: [String] = []
        let street = [pm.thoroughfare, pm.subThoroughfare].compactMap { $0 }.joined(separator: " ")
        if !street.isEmpty { parts.append(street) }
        let city = [pm.postalCode, pm.locality, pm.subAdministrativeArea].compactMap { $0 }.joined(separator: " ")
        if !city.isEmpty { parts.append(city) }
        if let country = pm.country { parts.append(country) }
        return parts.isEmpty ? (pm.name ?? "") : parts.joined(separator: ", ")
    }
}

struct RouteInfo: Equatable {
    var coordinates: [CLLocationCoordinate2D]
    var travelTime: TimeInterval
    var distance: CLLocationDistance

    static func == (lhs: RouteInfo, rhs: RouteInfo) -> Bool {
        lhs.travelTime == rhs.travelTime && lhs.distance == rhs.distance && lhs.coordinates.count == rhs.coordinates.count
    }

    var arrival: Date { Date().addingTimeInterval(travelTime) }
    var minutes: Int { max(1, Int((travelTime / 60).rounded())) }
}

enum DistanceUnit: String, CaseIterable, Identifiable {
    case metric, imperial
    var id: String { rawValue }

    var title: String {
        switch self {
        case .metric: return "Metrico (KM)"
        case .imperial: return "Imperiale (MI)"
        }
    }

    var shortLabel: String { self == .metric ? "km" : "mi" }

    func value(_ meters: CLLocationDistance) -> String {
        let v = self == .metric ? meters / 1000 : meters / 1609.344
        if v < 10 { return String(format: "%.1f", v).replacingOccurrences(of: ".0", with: "") }
        return String(Int(v.rounded()))
    }
}

enum Formatters {
    static let time: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "HH:mm"
        return f
    }()

    static let dayTime: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "EEEE, HH:mm"
        return f
    }()
}
