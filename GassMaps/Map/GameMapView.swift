import SwiftUI
import MapLibre

struct GameMapView: UIViewRepresentable {
    @ObservedObject var state: AppState

    func makeCoordinator() -> MapCoordinator {
        MapCoordinator(state: state)
    }

    func makeUIView(context: Context) -> MLNMapView {
        let map = MLNMapView(frame: .zero, styleURL: state.theme.styleURL)
        map.delegate = context.coordinator
        map.backgroundColor = .black
        map.logoView.isHidden = true
        map.compassView.isHidden = true
        map.attributionButtonPosition = .bottomLeft
        map.attributionButtonMargins = CGPoint(x: 8, y: 6)
        map.attributionButton.alpha = 0.45
        map.showsUserLocation = true
        map.allowsTilting = true
        map.allowsRotating = true
        map.minimumZoomLevel = 2
        map.maximumZoomLevel = 19.5
        map.setZoomLevel(MapController.defaultZoom, animated: false)

        let longPress = UILongPressGestureRecognizer(target: context.coordinator,
                                                     action: #selector(MapCoordinator.handleLongPress(_:)))
        map.addGestureRecognizer(longPress)

        context.coordinator.currentStyleID = state.theme.id
        state.map.attach(map)
        return map
    }

    func updateUIView(_ map: MLNMapView, context: Context) {
        context.coordinator.state = state
        if context.coordinator.currentStyleID != state.theme.id {
            context.coordinator.currentStyleID = state.theme.id
            map.styleURL = state.theme.styleURL
        }
    }
}

final class MapCoordinator: NSObject, MLNMapViewDelegate {
    var state: AppState
    var currentStyleID: String = ""

    init(state: AppState) {
        self.state = state
    }

    // MARK: Stile

    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        MapIcons.install(in: style, theme: state.theme)
        state.map.installRoute(in: style)
    }

    func mapView(_ mapView: MLNMapView, didFailToLoadImage imageName: String) -> UIImage? {
        MapIcons.image(named: imageName, theme: state.theme)
    }

    // MARK: Annotazioni

    func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
        if annotation is MLNUserLocation {
            return UserArrowView()
        }
        let id = "gm-pin"
        let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? PinBubbleView)
            ?? PinBubbleView(reuseIdentifier: id)
        let title = annotation.title ?? nil
        view.configure(title: title ?? "", accent: state.theme.accent)
        return view
    }

    func mapView(_ mapView: MLNMapView, annotationCanShowCallout annotation: MLNAnnotation) -> Bool {
        false
    }

    // MARK: Posizione

    func mapView(_ mapView: MLNMapView, didUpdate userLocation: MLNUserLocation?) {
        guard let loc = userLocation?.location else { return }
        state.map.initialPosition(loc.coordinate)
        state.locationUpdated(loc)
    }

    func mapView(_ mapView: MLNMapView, didChange mode: MLNUserTrackingMode, animated: Bool) {
        let t: TrackingState
        switch mode {
        case .follow: t = .follow
        case .followWithHeading, .followWithCourse: t = .heading
        default: t = .none
        }
        if state.tracking != t {
            DispatchQueue.main.async { self.state.tracking = t }
        }
    }

    // MARK: Gesture

    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let map = gesture.view as? MLNMapView else { return }
        let point = gesture.location(in: map)
        let coord = map.convert(point, toCoordinateFrom: map)
        let place = Place(name: "", address: "Ricerca indirizzo...", coordinate: coord)
        state.pin(place, fly: false)
        Geocoder.reverse(coord) { [weak self] address in
            guard let self = self, var p = self.state.pinnedPlace, p.latitude == coord.latitude else { return }
            p.address = address
            self.state.pinnedPlace = p
        }
    }
}
