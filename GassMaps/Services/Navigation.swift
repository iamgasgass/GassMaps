import Foundation
import CoreLocation
import AVFoundation

/// Avanzamento lungo il percorso (calcolato ad ogni posizione GPS).
struct RouteProgress: Equatable {
    /// distanza percorsa dall'inizio del percorso
    var traveled: CLLocationDistance = 0
    /// distanza mancante all'arrivo
    var remaining: CLLocationDistance = 0
    /// distanza minima dalla linea del percorso (per capire se si è fuori percorso)
    var offset: CLLocationDistance = 0
    /// indice della prossima manovra in `RouteInfo.steps`
    var nextStep: Int = 0
    /// distanza alla prossima manovra
    var toManeuver: CLLocationDistance = 0
    /// tempo mancante stimato
    var remainingTime: TimeInterval = 0
}

enum RouteMath {
    /// metri tra due coordinate (approssimazione locale, precisa a scala urbana)
    static func meters(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let k = 111_320.0
        let dx = (b.longitude - a.longitude) * k * cos((a.latitude + b.latitude) / 2 * .pi / 180)
        let dy = (b.latitude - a.latitude) * k
        return sqrt(dx * dx + dy * dy)
    }

    /// distanze cumulative lungo la polilinea
    static func cumulative(_ coords: [CLLocationCoordinate2D]) -> [Double] {
        var out = [Double](repeating: 0, count: coords.count)
        for i in 1..<max(coords.count, 1) where i < coords.count {
            out[i] = out[i - 1] + meters(coords[i - 1], coords[i])
        }
        return out
    }

    /// proiezione del punto sulla polilinea: (distanza lungo il percorso, distanza dalla linea)
    static func project(_ p: CLLocationCoordinate2D, on coords: [CLLocationCoordinate2D],
                        cumulative cum: [Double], from startIndex: Int = 0) -> (along: Double, offset: Double, index: Int) {
        guard coords.count > 1 else { return (0, coords.first.map { meters($0, p) } ?? 0, 0) }
        let k = 111_320.0
        let cosLat = cos(p.latitude * .pi / 180)
        var best = (along: 0.0, offset: Double.greatestFiniteMagnitude, index: 0)
        let lower = max(0, startIndex - 5)
        for i in lower..<(coords.count - 1) {
            let a = coords[i], b = coords[i + 1]
            let ax = (a.longitude - p.longitude) * k * cosLat, ay = (a.latitude - p.latitude) * k
            let bx = (b.longitude - p.longitude) * k * cosLat, by = (b.latitude - p.latitude) * k
            let vx = bx - ax, vy = by - ay
            let len2 = vx * vx + vy * vy
            var t = len2 > 0 ? -(ax * vx + ay * vy) / len2 : 0
            t = min(max(t, 0), 1)
            let cx = ax + t * vx, cy = ay + t * vy
            let d = sqrt(cx * cx + cy * cy)
            if d < best.offset {
                best = (cum[i] + t * sqrt(len2), d, i)
            }
        }
        return best
    }
}

/// Icona della manovra a partire dal testo dell'istruzione (italiano o inglese).
enum ManeuverIcon {
    static func symbol(for instruction: String) -> String {
        let s = instruction.lowercased()
        func has(_ words: String...) -> Bool { words.contains { s.contains($0) } }
        if has("arriv", "destinazione", "destination") { return "mappin.circle.fill" }
        if has("inversione", "u-turn", "make a u") { return "arrow.uturn.left" }
        if has("rotonda", "roundabout", "rotatoria") { return "arrow.triangle.turn.up.right.circle.fill" }
        if has("uscita", "exit", "svincolo") {
            return has("sinistra", "left") ? "arrow.up.left" : "arrow.up.right"
        }
        if has("leggermente a destra", "slight right", "mantieni la destra", "keep right", "tieni la destra") {
            return "arrow.up.right"
        }
        if has("leggermente a sinistra", "slight left", "mantieni la sinistra", "keep left", "tieni la sinistra") {
            return "arrow.up.left"
        }
        if has("a destra", "turn right", "right onto", "destra") { return "arrow.turn.up.right" }
        if has("a sinistra", "turn left", "left onto", "sinistra") { return "arrow.turn.up.left" }
        if has("traghetto", "ferry") { return "ferry.fill" }
        return "arrow.up"
    }
}

/// Guida vocale in italiano (come le indicazioni vocali di Google Maps).
final class VoiceGuide {
    static let shared = VoiceGuide()
    private let synth = AVSpeechSynthesizer()
    var muted = false

    func speak(_ text: String) {
        guard !muted, !text.isEmpty else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
        try? session.setActive(true)
        if synth.isSpeaking { synth.stopSpeaking(at: .word) }
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "it-IT")
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 1.02
        synth.speak(u)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
