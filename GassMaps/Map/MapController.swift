import UIKit
import CoreLocation
import MapLibre
import MapKit

/// Segnaposto di un risultato di ricerca
final class ResultAnnotation: MLNPointAnnotation {
    var index = 0
}

/// Ponte tra SwiftUI e MLNMapView.
final class MapController {
    weak var mapView: MLNMapView?
    weak var state: AppState?

    private(set) var routeCoordinates: [CLLocationCoordinate2D] = []
    private(set) var alternativeCoordinates: [[CLLocationCoordinate2D]] = []
    private var resultAnnotations: [ResultAnnotation] = []
    private var pinAnnotation: MLNPointAnnotation?
    private var didInitialPosition = false

    static let defaultPitch: CGFloat = 52
    /// inclinazione della camera per il tema attivo
    var pitch: CGFloat { state?.theme.mapPitch ?? MapController.defaultPitch }
    static let defaultZoom: Double = 16.4

    static let routeSourceID = "gm-route"
    static let routeLayerID = "gm-route-line"
    static let routeCasingID = "gm-route-casing"
    static let altSourceID = "gm-route-alt"
    static let altLayerID = "gm-route-alt-line"
    static let altCasingID = "gm-route-alt-casing"

    var centerCoordinate: CLLocationCoordinate2D? { mapView?.centerCoordinate }

    func attach(_ map: MLNMapView) {
        mapView = map
    }

    // MARK: - Camera

    func initialPosition(_ coordinate: CLLocationCoordinate2D) {
        guard !didInitialPosition, let m = mapView else { return }
        didInitialPosition = true
        let cam = MLNMapCamera(lookingAtCenter: coordinate, altitude: 650, pitch: pitch, heading: 0)
        m.setCamera(cam, animated: false)
        m.setZoomLevel(MapController.defaultZoom, animated: false)
        m.setUserTrackingMode(.follow, animated: false, completionHandler: nil)
    }

    func recenter() {
        guard let m = mapView else { return }
        setBottomInset(0)
        if let loc = m.userLocation?.location ?? state?.location.location {
            let cam = MLNMapCamera(lookingAtCenter: loc.coordinate, altitude: 650,
                                   pitch: pitch, heading: m.direction)
            m.fly(to: cam, withDuration: 0.8) { [weak self] in
                self?.mapView?.setZoomLevel(MapController.defaultZoom, animated: true)
                self?.setTracking(.follow)
            }
        } else {
            setTracking(.follow)
        }
    }

    func setTracking(_ t: TrackingState) {
        guard let m = mapView else { return }
        switch t {
        case .none: m.setUserTrackingMode(.none, animated: true, completionHandler: nil)
        case .follow: m.setUserTrackingMode(.follow, animated: true, completionHandler: nil)
        case .heading: m.setUserTrackingMode(.followWithHeading, animated: true, completionHandler: nil)
        }
        state?.tracking = t
    }

    func fly(to coordinate: CLLocationCoordinate2D) {
        guard let m = mapView else { return }
        m.setUserTrackingMode(.none, animated: false, completionHandler: nil)
        state?.tracking = .none
        setBottomInset(330)
        let cam = MLNMapCamera(lookingAtCenter: coordinate, altitude: 700,
                               pitch: pitch, heading: m.direction)
        m.fly(to: cam, withDuration: 1.1, completionHandler: nil)
    }

    func setBottomInset(_ bottom: CGFloat) {
        guard let m = mapView else { return }
        m.setContentInset(UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0), animated: true)
    }

    // MARK: - Pin

    func showPin(_ place: Place) {
        guard let m = mapView else { return }
        removePin()
        let a = MLNPointAnnotation()
        a.coordinate = place.coordinate
        a.title = place.name
        m.addAnnotation(a)
        pinAnnotation = a
        if place.name.isEmpty {
            setBottomInset(330)
            m.setUserTrackingMode(.none, animated: false, completionHandler: nil)
            state?.tracking = .none
            let cam = MLNMapCamera(lookingAtCenter: place.coordinate, altitude: 700,
                                   pitch: pitch, heading: m.direction)
            m.setCamera(cam, withDuration: 0.6, animationTimingFunction: CAMediaTimingFunction(name: .easeInEaseOut))
        }
    }

    func removePin() {
        if let a = pinAnnotation { mapView?.removeAnnotation(a) }
        pinAnnotation = nil
    }

    // MARK: - Percorso

    func showRoute(_ coordinates: [CLLocationCoordinate2D], overview: Bool) {
        showRoute(coordinates, alternatives: [], overview: overview)
    }

    /// Percorso scelto (colore del tema) + alternative (grigie, toccabili) come in Google Maps
    func showRoute(_ coordinates: [CLLocationCoordinate2D], alternatives: [[CLLocationCoordinate2D]], overview: Bool) {
        routeCoordinates = coordinates
        alternativeCoordinates = alternatives.filter { $0.count > 1 }
        guard let m = mapView else { return }
        if let style = m.style { installRoute(in: style) }
        guard overview, coordinates.count > 1 else { return }

        var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0
        for c in coordinates + alternativeCoordinates.flatMap({ $0 }) {
            minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        let bounds = MLNCoordinateBounds(sw: CLLocationCoordinate2D(latitude: minLat, longitude: minLon),
                                         ne: CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon))
        m.setUserTrackingMode(.none, animated: false, completionHandler: nil)
        state?.tracking = .none
        m.contentInset = .zero
        // Come nel video: vista dall'alto, nord in su, percorso intero nella parte alta sopra il pannello,
        // movimento rapido (~0,5 s) senza "volo".
        let cam = m.cameraThatFitsCoordinateBounds(bounds, edgePadding: UIEdgeInsets(top: 150, left: 34, bottom: 380, right: 34))
        cam.pitch = 0
        cam.heading = 0
        m.setCamera(cam, withDuration: 0.5, animationTimingFunction: CAMediaTimingFunction(name: .easeOut))
    }

    func installRoute(in style: MLNStyle) {
        installAlternatives(in: style)
        guard routeCoordinates.count > 1 else { return }
        var coords = routeCoordinates
        let line = MLNPolylineFeature(coordinates: &coords, count: UInt(coords.count))

        if let source = style.source(withIdentifier: MapController.routeSourceID) as? MLNShapeSource {
            source.shape = line
            return
        }
        let source = MLNShapeSource(identifier: MapController.routeSourceID, shape: line, options: nil)
        style.addSource(source)

        let accent = state?.theme.accent ?? UIColor(hex: 0x7B2CF0)

        let casing = MLNLineStyleLayer(identifier: MapController.routeCasingID, source: source)
        casing.lineColor = NSExpression(forConstantValue: UIColor.black.withAlphaComponent(0.55))
        casing.lineWidth = NSExpression(forConstantValue: 11)
        casing.lineCap = NSExpression(forConstantValue: "round")
        casing.lineJoin = NSExpression(forConstantValue: "round")

        let layer = MLNLineStyleLayer(identifier: MapController.routeLayerID, source: source)
        layer.lineColor = NSExpression(forConstantValue: accent)
        layer.lineWidth = NSExpression(forConstantValue: 6.5)
        layer.lineCap = NSExpression(forConstantValue: "round")
        layer.lineJoin = NSExpression(forConstantValue: "round")

        if let below = style.layer(withIdentifier: "road-oneway") {
            style.insertLayer(casing, below: below)
            style.insertLayer(layer, below: below)
        } else {
            style.addLayer(casing)
            style.addLayer(layer)
        }
    }

    private func installAlternatives(in style: MLNStyle) {
        let shapes: [MLNShape] = alternativeCoordinates.map { coords in
            var c = coords
            return MLNPolylineFeature(coordinates: &c, count: UInt(c.count))
        }
        let collection = MLNShapeCollectionFeature(shapes: shapes)
        if let source = style.source(withIdentifier: MapController.altSourceID) as? MLNShapeSource {
            source.shape = collection
            return
        }
        guard !shapes.isEmpty else { return }
        let source = MLNShapeSource(identifier: MapController.altSourceID, shape: collection, options: nil)
        style.addSource(source)
        let casing = MLNLineStyleLayer(identifier: MapController.altCasingID, source: source)
        casing.lineColor = NSExpression(forConstantValue: UIColor.black.withAlphaComponent(0.45))
        casing.lineWidth = NSExpression(forConstantValue: 10)
        casing.lineCap = NSExpression(forConstantValue: "round")
        casing.lineJoin = NSExpression(forConstantValue: "round")
        let layer = MLNLineStyleLayer(identifier: MapController.altLayerID, source: source)
        layer.lineColor = NSExpression(forConstantValue: UIColor(white: 0.62, alpha: 0.95))
        layer.lineWidth = NSExpression(forConstantValue: 5.5)
        layer.lineCap = NSExpression(forConstantValue: "round")
        layer.lineJoin = NSExpression(forConstantValue: "round")
        // le alternative stanno sotto al percorso scelto
        if let below = style.layer(withIdentifier: MapController.routeCasingID) ?? style.layer(withIdentifier: "road-oneway") {
            style.insertLayer(casing, below: below)
            style.insertLayer(layer, below: below)
        } else {
            style.addLayer(casing)
            style.addLayer(layer)
        }
    }

    func clearRoute() {
        routeCoordinates = []
        alternativeCoordinates = []
        guard let style = mapView?.style else { return }
        if let source = style.source(withIdentifier: MapController.routeSourceID) as? MLNShapeSource {
            source.shape = nil
        }
        if let source = style.source(withIdentifier: MapController.altSourceID) as? MLNShapeSource {
            source.shape = nil
        }
    }

    /// Indice dell'alternativa più vicina al punto toccato (entro 26 pt), se c'è
    func alternativeIndex(near point: CGPoint) -> Int? {
        guard let m = mapView else { return nil }
        var best: (Int, CGFloat)?
        for (i, coords) in alternativeCoordinates.enumerated() {
            let pts = coords.map { m.convert($0, toPointTo: m) }
            for j in 0..<(pts.count - 1) {
                let d = MapController.distance(point, pts[j], pts[j + 1])
                if d < 26 && (best == nil || d < best!.1) { best = (i, d) }
            }
        }
        return best?.0
    }

    private static func distance(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let vx = b.x - a.x, vy = b.y - a.y
        let len2 = vx * vx + vy * vy
        var t = len2 > 0 ? ((p.x - a.x) * vx + (p.y - a.y) * vy) / len2 : 0
        t = min(max(t, 0), 1)
        let cx = a.x + t * vx - p.x, cy = a.y + t * vy - p.y
        return sqrt(cx * cx + cy * cy)
    }

    // MARK: - Risultati di ricerca

    func showResults(_ items: [MKMapItem]) {
        guard let m = mapView else { return }
        clearResults()
        removePin()
        let anns = items.enumerated().map { i, item -> ResultAnnotation in
            let a = ResultAnnotation()
            a.coordinate = item.placemark.coordinate
            a.title = item.name
            a.index = i
            return a
        }
        resultAnnotations = anns
        m.addAnnotations(anns)
        m.setUserTrackingMode(.none, animated: false, completionHandler: nil)
        state?.tracking = .none
        m.contentInset = .zero
        let coords = anns.map { $0.coordinate }
        guard let first = coords.first else { return }
        var minLat = first.latitude, maxLat = first.latitude, minLon = first.longitude, maxLon = first.longitude
        for c in coords {
            minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        let pad = 0.002
        let bounds = MLNCoordinateBounds(sw: CLLocationCoordinate2D(latitude: minLat - pad, longitude: minLon - pad),
                                         ne: CLLocationCoordinate2D(latitude: maxLat + pad, longitude: maxLon + pad))
        let cam = m.cameraThatFitsCoordinateBounds(bounds, edgePadding: UIEdgeInsets(top: 170, left: 40, bottom: 400, right: 40))
        cam.pitch = min(pitch, 30)
        m.setCamera(cam, withDuration: 0.6, animationTimingFunction: CAMediaTimingFunction(name: .easeInEaseOut))
    }

    func clearResults() {
        if !resultAnnotations.isEmpty { mapView?.removeAnnotations(resultAnnotations) }
        resultAnnotations = []
    }

    /// Area visibile della mappa (per "Cerca in questa zona" e per i suggerimenti di ricerca)
    var visibleRegion: MKCoordinateRegion? {
        guard let m = mapView else { return nil }
        let b = m.visibleCoordinateBounds
        let center = CLLocationCoordinate2D(latitude: (b.sw.latitude + b.ne.latitude) / 2,
                                            longitude: (b.sw.longitude + b.ne.longitude) / 2)
        let span = MKCoordinateSpan(latitudeDelta: max(0.01, abs(b.ne.latitude - b.sw.latitude)),
                                    longitudeDelta: max(0.01, abs(b.ne.longitude - b.sw.longitude)))
        return MKCoordinateRegion(center: center, span: span)
    }

    func resetNorth() {
        mapView?.resetNorth()
    }

    // MARK: - Navigazione

    static func bearing(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> CLLocationDirection {
        let la1 = a.latitude * .pi / 180, la2 = b.latitude * .pi / 180
        let dl = (b.longitude - a.longitude) * .pi / 180
        let y = sin(dl) * cos(la2)
        let x = cos(la1) * sin(la2) - sin(la1) * cos(la2) * cos(dl)
        let deg = atan2(y, x) * 180 / .pi
        return deg < 0 ? deg + 360 : deg
    }

    func startNavigation() {
        guard let m = mapView else { return }
        setBottomInset(230)
        if let loc = m.userLocation?.location ?? state?.location.location {
            // Come nel video: passaggio quasi immediato a una vista molto ravvicinata che segue la marcia
            var course = loc.course >= 0 ? loc.course : m.direction
            if loc.course < 0, routeCoordinates.count > 1 {
                course = MapController.bearing(from: routeCoordinates[0], to: routeCoordinates[min(5, routeCoordinates.count - 1)])
            }
            let cam = MLNMapCamera(lookingAtCenter: loc.coordinate, altitude: 230, pitch: 38, heading: course)
            m.setCamera(cam, withDuration: 0.35, animationTimingFunction: CAMediaTimingFunction(name: .easeOut))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.mapView?.setUserTrackingMode(.followWithCourse, animated: true, completionHandler: nil)
            }
        } else {
            m.setUserTrackingMode(.followWithCourse, animated: true, completionHandler: nil)
        }
        state?.tracking = .heading
    }
}
