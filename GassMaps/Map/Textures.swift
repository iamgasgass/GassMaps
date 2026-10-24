import UIKit

/// Texture ripetibili usate come "background-pattern" / "fill-pattern" negli stili mappa.
/// Disegnate interamente dall'app (nessuna immagine esterna).
enum Textures {
    static let names = ["gm-paper", "gm-grass", "gm-water", "gm-planks", "gm-stone"]

    private static var cache: [String: UIImage] = [:]

    static func image(named name: String) -> UIImage? {
        if let c = cache[name] { return c }
        let img: UIImage?
        switch name {
        case "gm-paper": img = paper()
        case "gm-grass": img = blocks(colors: [0x6E9050, 0x6A8C4A, 0x76985A, 0x648646, 0x7A9C58, 0x70924E], block: 8, count: 8)
        case "gm-water": img = blocks(colors: [0x5A5ABE, 0x5454B6, 0x6060C6, 0x5050B0, 0x5C5CC2], block: 8, count: 8)
        case "gm-planks": img = planks()
        case "gm-stone": img = stone()
        default: img = nil
        }
        if let img = img { cache[name] = img }
        return img
    }

    private static func renderer(_ side: CGFloat) -> UIGraphicsImageRenderer {
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2
        fmt.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: fmt)
    }

    /// Pergamena: base sabbia + puntini e fibre (ripetibile: tutto avvolto sui bordi)
    private static func paper() -> UIImage {
        let side: CGFloat = 256
        var rng = SeededGenerator(seed: 7)
        return renderer(side).image { ctx in
            let c = ctx.cgContext
            c.setFillColor(UIColor(hex: 0xD4C09A).cgColor)
            c.fill(CGRect(x: 0, y: 0, width: side, height: side))
            // macchie morbide
            for _ in 0..<40 {
                let x = CGFloat.random(in: 0..<side, using: &rng), y = CGFloat.random(in: 0..<side, using: &rng)
                let r = CGFloat.random(in: 10...40, using: &rng)
                let dark = Bool.random(using: &rng)
                let col = (dark ? UIColor(hex: 0xA88F66) : UIColor(hex: 0xE6D6B4)).withAlphaComponent(0.10)
                c.setFillColor(col.cgColor)
                for dx in [-side, 0, side] { for dy in [-side, 0, side] {
                    c.fillEllipse(in: CGRect(x: x - r + dx, y: y - r + dy, width: r * 2, height: r * 2))
                } }
            }
            // granelli
            for _ in 0..<2600 {
                let x = CGFloat.random(in: 0..<side, using: &rng), y = CGFloat.random(in: 0..<side, using: &rng)
                let a = CGFloat.random(in: 0.05...0.22, using: &rng)
                let col = Bool.random(using: &rng) ? UIColor(hex: 0x6E5A3A) : UIColor(hex: 0xF2E6C8)
                c.setFillColor(col.withAlphaComponent(a).cgColor)
                c.fill(CGRect(x: x, y: y, width: 0.8, height: 0.8))
            }
            // fibre
            c.setLineWidth(0.5)
            for _ in 0..<70 {
                let x = CGFloat.random(in: 0..<side, using: &rng), y = CGFloat.random(in: 0..<side, using: &rng)
                let len = CGFloat.random(in: 4...14, using: &rng)
                let ang = CGFloat.random(in: 0..<(2 * .pi), using: &rng)
                c.setStrokeColor(UIColor(hex: 0x8A7552).withAlphaComponent(0.18).cgColor)
                for dx in [-side, 0, side] { for dy in [-side, 0, side] {
                    c.move(to: CGPoint(x: x + dx, y: y + dy))
                    c.addLine(to: CGPoint(x: x + dx + cos(ang) * len, y: y + dy + sin(ang) * len))
                } }
                c.strokePath()
            }
        }
    }

    /// Griglia di blocchi colorati (erba / acqua pixelate)
    private static func blocks(colors: [UInt32], block: CGFloat, count: Int) -> UIImage {
        var rng = SeededGenerator(seed: UInt64(colors[0]))
        let side = block * CGFloat(count)
        return renderer(side).image { ctx in
            let c = ctx.cgContext
            c.interpolationQuality = .none
            c.setShouldAntialias(false)
            for i in 0..<count {
                for j in 0..<count {
                    let col = colors[Int.random(in: 0..<colors.count, using: &rng)]
                    c.setFillColor(UIColor(hex: col).cgColor)
                    c.fill(CGRect(x: CGFloat(i) * block, y: CGFloat(j) * block, width: block, height: block))
                }
            }
        }
    }

    /// Assi di legno (tetti)
    private static func planks() -> UIImage {
        var rng = SeededGenerator(seed: 11)
        let side: CGFloat = 32
        return renderer(side).image { ctx in
            let c = ctx.cgContext
            c.setShouldAntialias(false)
            let tones: [UInt32] = [0xB0834E, 0xA87A46, 0xB88C56, 0xA0723F]
            for row in 0..<4 {
                let y = CGFloat(row) * 8
                c.setFillColor(UIColor(hex: tones[row % tones.count]).cgColor)
                c.fill(CGRect(x: 0, y: y, width: side, height: 8))
                for _ in 0..<10 {
                    let x = CGFloat(Int.random(in: 0..<16, using: &rng)) * 2
                    let yy = y + CGFloat(Int.random(in: 1..<3, using: &rng)) * 2
                    c.setFillColor(UIColor(hex: 0x8C6236).cgColor)
                    c.fill(CGRect(x: x, y: yy, width: 4, height: 2))
                }
                c.setFillColor(UIColor(hex: 0x6E4A26).cgColor)
                c.fill(CGRect(x: 0, y: y + 6, width: side, height: 2))
                let cut = CGFloat(row % 2 == 0 ? 12 : 26)
                c.fill(CGRect(x: cut, y: y, width: 2, height: 8))
            }
        }
    }

    /// Blocchi di pietra (edifici alti)
    private static func stone() -> UIImage {
        var rng = SeededGenerator(seed: 23)
        let side: CGFloat = 32
        return renderer(side).image { ctx in
            let c = ctx.cgContext
            c.setShouldAntialias(false)
            let tones: [UInt32] = [0x8C8C8C, 0x7E7E7E, 0x989898, 0x868686, 0x737373]
            for i in 0..<8 {
                for j in 0..<8 {
                    c.setFillColor(UIColor(hex: tones[Int.random(in: 0..<tones.count, using: &rng)]).cgColor)
                    c.fill(CGRect(x: CGFloat(i) * 4, y: CGFloat(j) * 4, width: 4, height: 4))
                }
            }
            c.setFillColor(UIColor(hex: 0x5E5E5E).cgColor)
            c.fill(CGRect(x: 0, y: 15, width: side, height: 2))
            c.fill(CGRect(x: 0, y: 31, width: side, height: 1))
            c.fill(CGRect(x: 15, y: 0, width: 2, height: 16))
            c.fill(CGRect(x: 6, y: 16, width: 2, height: 16))
            c.fill(CGRect(x: 24, y: 16, width: 2, height: 16))
        }
    }
}

/// Piccoli sprite in pixel art disegnati per il tema a blocchi.
enum PixelArt {
    private static let palette: [Character: UInt32] = [
        "k": 0x2A1A0E, "b": 0x8A4E24, "m": 0xC77A3E, "l": 0xE3A56A, "w": 0xF2EEE6, "g": 0xBDB6AA,
        "c": 0x2BB5B0, "C": 0x64E8E0, "d": 0x167A78, "D": 0x0E4F4E
    ]

    // coscia di pollo arrosto (cibo)
    private static let food = [
        "....kkkk....",
        "...kmmmmk...",
        "..kmllmmmk..",
        ".kmlmmmmbk..",
        ".kmmmmmbbk..",
        ".kmmmmbbk...",
        "..kbbbbk....",
        "...kkkwk....",
        "......kwk...",
        ".....kwgwk..",
        ".....kgwgk..",
        "......kkk..."
    ]

    // corazza/maglia (abbigliamento)
    private static let clothes = [
        "..DDD..DDD..",
        ".DcCcDDcCcD.",
        "DcCCcccCCcD.",
        "DccDcccDccD.",
        ".DDdcCcdDD..",
        "..DcCCCcD...",
        "..DcCccdD...",
        "..DccccdD...",
        "..DdcccdD...",
        "..DDddddD...",
        "...DDDDD....",
        "............"
    ]

    static func sprite(for cat: POICategory) -> UIImage? {
        switch cat {
        case .food, .cafe: return render(food, pixel: 3.4)
        case .clothes, .shop: return render(clothes, pixel: 3.4)
        default: return nil
        }
    }

    private static func render(_ rows: [String], pixel: CGFloat) -> UIImage {
        let h = CGFloat(rows.count), w = CGFloat(rows.first?.count ?? 0)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2
        return UIGraphicsImageRenderer(size: CGSize(width: w * pixel, height: h * pixel), format: fmt).image { ctx in
            let c = ctx.cgContext
            c.setShouldAntialias(false)
            for (y, row) in rows.enumerated() {
                for (x, ch) in row.enumerated() {
                    guard let hex = palette[ch] else { continue }
                    c.setFillColor(UIColor(hex: hex).cgColor)
                    c.fill(CGRect(x: CGFloat(x) * pixel, y: CGFloat(y) * pixel, width: pixel, height: pixel))
                }
            }
        }
    }
}
