import SwiftUI
import UIKit

struct GlobeMarker {
    let lat: Double
    let lon: Double
    let symbol: String
    var color: UIColor? = nil
}

struct MapTheme: Identifiable, Equatable {
    let id: String
    let name: String
    /// Sfondo della schermata "Selezione mappa"
    let backgroundTop: Color
    let backgroundBottom: Color
    /// Colore del percorso e del segnaposto (quadrifoglio)
    let accent: UIColor
    /// Colore icone POI sulla mappa e alone
    let iconColor: UIColor
    let iconHalo: UIColor
    /// Colore di riempimento ai poli della texture del globo
    let polar: UIColor
    /// Colore del pulsante "Continua" (tinta)
    let buttonTint: Color
    let markers: [GlobeMarker]
    /// Stile etichette del globo
    var globeFont: String = "Futura-CondensedExtraBold"
    var globeUppercase: Bool = false
    var globeLabel: UIColor = .white
    var globeLabelHalo: UIColor = .black
    /// Foschia vicino all'orizzonte e bagliore dell'atmosfera
    var haze: UIColor = UIColor(hex: 0x7F888E)
    /// colore della coda del bagliore (sopra l'orizzonte)
    var glow: UIColor = UIColor(hex: 0x5994FF)
    /// colore della linea luminosa sull'orizzonte
    var glowCore: UIColor = UIColor(hex: 0xEBF0FF)
    /// inclinazione della camera sulla mappa (0 = vista dall'alto)
    var mapPitch: CGFloat = 52
    /// vignettatura scura ai bordi della mappa (0…1)
    var vignette: Double = 0
    /// colore della freccia utente
    var arrowColor: UIColor = .white

    static func == (lhs: MapTheme, rhs: MapTheme) -> Bool { lhs.id == rhs.id }

    var styleURL: URL {
        Bundle.main.url(forResource: id, withExtension: "json")
            ?? URL(string: "https://tiles.openfreemap.org/styles/dark")!
    }

    var globeStyleURL: URL {
        Bundle.main.url(forResource: id + "_globe", withExtension: "json") ?? styleURL
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

enum Themes {
    static let defaultIndex = 1

    static let all: [MapTheme] = [
        MapTheme(
            id: "dust", name: "Dust Valley",
            backgroundTop: Color(hex: 0x051626), backgroundBottom: Color(hex: 0x051626),
            accent: UIColor(hex: 0x8840D8), iconColor: UIColor(hex: 0x2B1B0B), iconHalo: UIColor(hex: 0xE8D6B0),
            polar: UIColor(hex: 0xEFE6D2), buttonTint: .white,
            markers: [
                GlobeMarker(lat: 46, lon: 120, symbol: "dollarsign.circle.fill"),
                GlobeMarker(lat: 31, lon: 125, symbol: "dollarsign.circle.fill"),
                GlobeMarker(lat: 42, lon: 143, symbol: "cup.and.saucer.fill"),
                GlobeMarker(lat: 40, lon: -100, symbol: "dollarsign.circle.fill"),
                GlobeMarker(lat: 48, lon: 10, symbol: "cup.and.saucer.fill")
            ],
            globeFont: "Copperplate-Bold", globeUppercase: true, globeLabel: UIColor(hex: 0x2B1B0B), globeLabelHalo: UIColor(hex: 0xE8D6B0), haze: UIColor(hex: 0xE3D1B8), glow: UIColor(hex: 0x5994FF), glowCore: UIColor(hex: 0xEBF0FF), mapPitch: 0, vignette: 0.6),
        MapTheme(
            id: "noir", name: "Vice Noir",
            backgroundTop: Color(hex: 0x051626), backgroundBottom: Color(hex: 0x051626),
            accent: UIColor(hex: 0x8840D8), iconColor: .white, iconHalo: .black,
            polar: UIColor(hex: 0x4A4F53), buttonTint: .white,
            markers: [
                GlobeMarker(lat: 52, lon: -1, symbol: "shoe.fill"),
                GlobeMarker(lat: 44, lon: 26, symbol: "star.circle.fill"),
                GlobeMarker(lat: 38, lon: 52, symbol: "car.side.fill"),
                GlobeMarker(lat: 26, lon: 77, symbol: "suit.diamond.fill"),
                GlobeMarker(lat: 32, lon: 103, symbol: "house.fill"),
                GlobeMarker(lat: 50, lon: 128, symbol: "house.lodge.fill"),
                GlobeMarker(lat: 23, lon: 121, symbol: "house.lodge.fill"),
                GlobeMarker(lat: 38, lon: 150, symbol: "wineglass.fill"),
                GlobeMarker(lat: 20, lon: 175, symbol: "wineglass.fill"),
                GlobeMarker(lat: 33, lon: -160, symbol: "shoe.fill"),
                GlobeMarker(lat: 52, lon: -112, symbol: "car.side.fill"),
                GlobeMarker(lat: 46, lon: -88, symbol: "suit.diamond.fill"),
                GlobeMarker(lat: 40.7, lon: -74, symbol: "house.fill"),
                GlobeMarker(lat: 33, lon: -117, symbol: "car.side.fill"),
                GlobeMarker(lat: 40, lon: -128, symbol: "star.circle.fill")
            ],
            globeFont: "Futura-CondensedExtraBold", globeUppercase: false, globeLabel: .white, globeLabelHalo: .black, haze: UIColor(hex: 0x7D8389), glow: UIColor(hex: 0x5994FF), glowCore: UIColor(hex: 0xEBF0FF), mapPitch: 40, vignette: 0.25),
        MapTheme(
            id: "bunker", name: "Bunker OS",
            backgroundTop: Color(hex: 0x040E04), backgroundBottom: Color(hex: 0x040E04),
            accent: UIColor(hex: 0x45FF45), iconColor: UIColor(hex: 0x5DFF5D), iconHalo: .black,
            polar: UIColor(hex: 0x0D260D), buttonTint: Color(hex: 0x8FE58F),
            markers: [
                GlobeMarker(lat: 45, lon: -40, symbol: "person.fill"),
                GlobeMarker(lat: 40, lon: -75, symbol: "atom"),
                GlobeMarker(lat: 55, lon: 40, symbol: "person.fill"),
                GlobeMarker(lat: 35, lon: 110, symbol: "atom")
            ],
            globeFont: "Menlo-Bold", globeUppercase: true, globeLabel: UIColor(hex: 0x5DFF5D), globeLabelHalo: .black, haze: UIColor(hex: 0x0F3A12), glow: UIColor(hex: 0x33FF4D), glowCore: UIColor(hex: 0x9CFF9C)),
        MapTheme(
            id: "pixel", name: "Pixel Land",
            backgroundTop: Color(hex: 0x051626), backgroundBottom: Color(hex: 0x051626),
            accent: UIColor(hex: 0x8840D8), iconColor: .white, iconHalo: UIColor(hex: 0x1D1D4A),
            polar: UIColor(hex: 0xF4F7F7), buttonTint: .white,
            markers: [
                GlobeMarker(lat: 38, lon: -30, symbol: "mug.fill", color: UIColor(hex: 0xF2B233)),
                GlobeMarker(lat: 22, lon: -32, symbol: "mug.fill", color: UIColor(hex: 0xF2B233)),
                GlobeMarker(lat: 53, lon: 2, symbol: "circle.hexagongrid.fill", color: UIColor(hex: 0xC8C8D8)),
                GlobeMarker(lat: 30, lon: -60, symbol: "suit.diamond.fill", color: UIColor(hex: 0x2ED36B)),
                GlobeMarker(lat: 10, lon: 20, symbol: "mug.fill", color: UIColor(hex: 0xF2B233))
            ],
            globeFont: "Courier-Bold", globeUppercase: false, globeLabel: .white, globeLabelHalo: UIColor(hex: 0x1D1D4A), haze: UIColor(hex: 0x8F8DE0), glow: UIColor(hex: 0x5994FF), glowCore: UIColor(hex: 0xEBF0FF), mapPitch: 28, vignette: 0.3),
        MapTheme(
            id: "neon", name: "Neon District",
            backgroundTop: Color(hex: 0x051626), backgroundBottom: Color(hex: 0x051626),
            accent: UIColor(hex: 0xFF2E7E), iconColor: UIColor(hex: 0x3FF2FF), iconHalo: .black,
            polar: UIColor(hex: 0x1A1424), buttonTint: .white,
            markers: [
                GlobeMarker(lat: 56, lon: 8, symbol: "camera.aperture"),
                GlobeMarker(lat: 42, lon: 13, symbol: "gearshape.fill"),
                GlobeMarker(lat: 29, lon: 3, symbol: "camera.aperture"),
                GlobeMarker(lat: 33, lon: -12, symbol: "bus.fill")
            ],
            globeFont: "AvenirNextCondensed-DemiBold", globeUppercase: true, globeLabel: UIColor(hex: 0x3FF2FF), globeLabelHalo: .black, haze: UIColor(hex: 0x1A1430), glow: UIColor(hex: 0x5994FF), glowCore: UIColor(hex: 0xEBF0FF), mapPitch: 55, vignette: 0.2, arrowColor: UIColor(hex: 0x5CF29A)),
        MapTheme(
            id: "palm", name: "Palm Coast",
            backgroundTop: Color(hex: 0x051626), backgroundBottom: Color(hex: 0x051626),
            accent: UIColor(hex: 0x8840D8), iconColor: .white, iconHalo: UIColor(hex: 0x1C1C1C),
            polar: UIColor(hex: 0xE8EEF0), buttonTint: .white,
            markers: [
                GlobeMarker(lat: 53, lon: -2, symbol: "globe.americas.fill", color: UIColor(hex: 0x8A5AE8)),
                GlobeMarker(lat: 46, lon: 28, symbol: "star.circle.fill", color: UIColor(hex: 0xF2C230)),
                GlobeMarker(lat: 40, lon: 50, symbol: "car.side.fill", color: UIColor(hex: 0x2E6BF2)),
                GlobeMarker(lat: 27, lon: 75, symbol: "die.face.5.fill", color: .white)
            ],
            globeFont: "Futura-CondensedExtraBold", globeUppercase: false, globeLabel: .white, globeLabelHalo: .black, haze: UIColor(hex: 0xA5ABB8), glow: UIColor(hex: 0x5994FF), glowCore: UIColor(hex: 0xEBF0FF), mapPitch: 22, vignette: 0.55),
        MapTheme(
            id: "heat", name: "Street Heat",
            backgroundTop: Color(hex: 0x0B0E20), backgroundBottom: Color(hex: 0x0B0E20),
            accent: UIColor(hex: 0xFF3D8B), iconColor: .white, iconHalo: UIColor(hex: 0x22003F),
            polar: UIColor(hex: 0xC9B3FF), buttonTint: .white,
            markers: [
                GlobeMarker(lat: 28, lon: 77, symbol: "die.face.5.fill"),
                GlobeMarker(lat: 35, lon: 105, symbol: "house.fill"),
                GlobeMarker(lat: 45, lon: 125, symbol: "building.columns.fill")
            ],
            globeFont: "AvenirNextCondensed-HeavyItalic", globeUppercase: true, globeLabel: .white, globeLabelHalo: UIColor(hex: 0x22003F), haze: UIColor(hex: 0x3A1660), glow: UIColor(hex: 0x9A4DFF), glowCore: UIColor(hex: 0xE6D9F2)),
        MapTheme(
            id: "kingdom", name: "Old Kingdom",
            backgroundTop: Color(hex: 0x2A2E29), backgroundBottom: Color(hex: 0x2A2E29),
            accent: UIColor(hex: 0x8840D8), iconColor: UIColor(hex: 0x2B1B0B), iconHalo: UIColor(hex: 0xE2C895),
            polar: UIColor(hex: 0xE3D3B0), buttonTint: .white,
            markers: [
                GlobeMarker(lat: 50, lon: 115, symbol: "bag.fill"),
                GlobeMarker(lat: 33, lon: 98, symbol: "house.fill"),
                GlobeMarker(lat: 27, lon: 130, symbol: "bag.fill")
            ],
            globeFont: "Georgia", globeUppercase: false, globeLabel: UIColor(hex: 0x2B1B0B), globeLabelHalo: UIColor(hex: 0xD9BB85), haze: UIColor(hex: 0x6E7258), glow: UIColor(hex: 0xE6CC8C), glowCore: UIColor(hex: 0xF5EBD2))
    ]
}
