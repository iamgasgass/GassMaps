import UIKit
import MapLibre

/// Categorie dei luoghi mostrate sulla mappa (devono coincidere con tools/generate_styles.py)
enum POICategory: String, CaseIterable {
    case park, cinema, rail, library, fuel, food, cafe, bar, shop, clothes, health, police,
         bank, lodging, school, parking, sport, worship, museum, car, `default`

    var imageName: String { "gm-poi-\(rawValue)" }
}

/// Come viene "incorniciata" l'icona, nello stile del gioco a cui si ispira il tema.
enum IconFrame {
    /// glifo con contorno (stile radar GTA V)
    case outline(halo: UIColor)
    /// glifo chiaro su disco scuro con anello (stile RDR)
    case badge(fill: UIColor, ring: UIColor)
    /// glifo dentro un esagono (stile Cyberpunk / Pip-Boy)
    case hexagon(fill: UIColor, ring: UIColor)
    /// glifo pixelato con contorno (stile blocchi)
    case pixel(halo: UIColor)
}

struct ThemeIconSet {
    let frame: IconFrame
    /// categoria -> (simbolo SF, colore)
    let glyphs: [POICategory: (String, UIColor)]
    /// se true l'icona predefinita è il quadrifoglio viola (tema Vice Noir, come nell'originale)
    let cloverDefault: Bool
}

enum MapIcons {
    // MARK: Set di icone per tema

    static func iconSet(for theme: MapTheme) -> ThemeIconSet {
        let w = UIColor.white
        switch theme.id {
        case "noir": // GTA V — icone nere con contorno bianco (come nelle schermate)
            let w = UIColor.black
            return ThemeIconSet(frame: .outline(halo: .white), glyphs: [
                .park: ("tree.fill", w), .cinema: ("video.fill", w), .rail: ("tram.fill", w),
                .library: ("book.fill", w), .fuel: ("fuelpump.fill", w),
                .food: ("takeoutbag.and.cup.and.straw.fill", w), .cafe: ("cup.and.saucer.fill", w),
                .bar: ("wineglass.fill", w), .shop: ("basket.fill", w), .clothes: ("tshirt.fill", w),
                .health: ("cross.fill", w), .police: ("star.circle.fill", w), .bank: ("dollarsign", w),
                .lodging: ("house.fill", w), .school: ("graduationcap.fill", w), .parking: ("parkingsign", w),
                .sport: ("figure.run", w), .worship: ("building.columns.fill", w),
                .museum: ("building.columns.fill", w), .car: ("car.side.fill", w)
            ], cloverDefault: true)

        case "palm": // GTA San Andreas: icone colorate
            return ThemeIconSet(frame: .outline(halo: .black), glyphs: [
                .park: ("tree.fill", UIColor(hex: 0x3DBE4A)), .cinema: ("film.fill", w),
                .rail: ("tram.fill", UIColor(hex: 0xF2C230)), .library: ("book.fill", UIColor(hex: 0xC98A3A)),
                .fuel: ("fuelpump.fill", UIColor(hex: 0xE04A3A)), .food: ("fork.knife", UIColor(hex: 0xF29A2E)),
                .cafe: ("cup.and.saucer.fill", UIColor(hex: 0xF29A2E)), .bar: ("wineglass.fill", UIColor(hex: 0xE85AA8)),
                .shop: ("cart.fill", UIColor(hex: 0x2E9BF2)), .clothes: ("tshirt.fill", UIColor(hex: 0xF29A2E)),
                .health: ("cross.fill", UIColor(hex: 0xE83A3A)), .police: ("star.fill", UIColor(hex: 0xF2C230)),
                .bank: ("dollarsign.circle.fill", UIColor(hex: 0x3DBE4A)), .lodging: ("house.fill", UIColor(hex: 0x3DBE4A)),
                .school: ("graduationcap.fill", w), .parking: ("parkingsign", UIColor(hex: 0x2E9BF2)),
                .sport: ("dumbbell.fill", UIColor(hex: 0xE04A3A)), .worship: ("building.columns.fill", w),
                .museum: ("building.columns.fill", w), .car: ("car.side.fill", UIColor(hex: 0x2E6BF2)),
                .default: ("globe.americas.fill", UIColor(hex: 0x8A5AE8))
            ], cloverDefault: false)

        case "dust": // western (RDR)
            let ink = UIColor(hex: 0x1A120A)
            return ThemeIconSet(frame: .badge(fill: ink, ring: UIColor(hex: 0xEADBB8)), glyphs: [
                .park: ("tree.fill", w), .cinema: ("theatermasks.fill", w), .rail: ("train.side.front.car", w),
                .library: ("book.closed.fill", w), .fuel: ("flame.fill", w), .food: ("fork.knife", w),
                .cafe: ("cup.and.saucer.fill", w), .bar: ("mug.fill", w), .shop: ("bag.fill", w),
                .clothes: ("hanger", w), .health: ("cross.fill", w), .police: ("star.fill", w),
                .bank: ("dollarsign", w), .lodging: ("bed.double.fill", w), .school: ("pencil", w),
                .parking: ("figure.equestrian.sports", w), .sport: ("target", w), .worship: ("cross", w),
                .museum: ("building.columns.fill", w), .car: ("figure.equestrian.sports", w),
                .default: ("dollarsign", w)
            ], cloverDefault: false)

        case "bunker": // terminale verde (Pip-Boy)
            let g = UIColor(hex: 0x5DFF5D)
            return ThemeIconSet(frame: .hexagon(fill: UIColor(hex: 0x031203), ring: g), glyphs: [
                .park: ("tree.fill", g), .cinema: ("film.fill", g), .rail: ("tram.fill", g),
                .library: ("book.fill", g), .fuel: ("bolt.fill", g), .food: ("fork.knife", g),
                .cafe: ("cup.and.saucer.fill", g), .bar: ("wineglass.fill", g), .shop: ("cart.fill", g),
                .clothes: ("tshirt.fill", g), .health: ("cross.case.fill", g), .police: ("shield.fill", g),
                .bank: ("dollarsign.circle", g), .lodging: ("house.fill", g), .school: ("graduationcap.fill", g),
                .parking: ("parkingsign", g), .sport: ("figure.boxing", g), .worship: ("building.columns.fill", g),
                .museum: ("building.columns.fill", g), .car: ("car.fill", g), .default: ("atom", g)
            ], cloverDefault: false)

        case "pixel": // mondo a blocchi: oggetti pixelati colorati
            return ThemeIconSet(frame: .pixel(halo: UIColor(hex: 0x1D1D1D)), glyphs: [
                .park: ("tree.fill", UIColor(hex: 0x4FAF2F)), .cinema: ("film.fill", UIColor(hex: 0xBDBDBD)),
                .rail: ("tram.fill", UIColor(hex: 0x9E9E9E)), .library: ("book.fill", UIColor(hex: 0x8B5A2B)),
                .fuel: ("flame.fill", UIColor(hex: 0xFF8A1F)), .food: ("carrot.fill", UIColor(hex: 0xFF8A1F)),
                .cafe: ("mug.fill", UIColor(hex: 0xE8A33A)), .bar: ("mug.fill", UIColor(hex: 0xF2B233)),
                .shop: ("shippingbox.fill", UIColor(hex: 0xA0702E)), .clothes: ("tshirt.fill", UIColor(hex: 0x4A7BD8)),
                .health: ("heart.fill", UIColor(hex: 0xE02424)), .police: ("shield.fill", UIColor(hex: 0xBDBDBD)),
                .bank: ("suit.diamond.fill", UIColor(hex: 0x2ED36B)), .lodging: ("bed.double.fill", UIColor(hex: 0xD8332E)),
                .school: ("book.closed.fill", UIColor(hex: 0x8B5A2B)), .parking: ("cube.fill", UIColor(hex: 0x9E9E9E)),
                .sport: ("figure.run", w), .worship: ("sparkles", UIColor(hex: 0xC07BFF)),
                .museum: ("building.columns.fill", UIColor(hex: 0xBDBDBD)), .car: ("cart.fill", UIColor(hex: 0x9E9E9E)),
                .default: ("suit.diamond.fill", UIColor(hex: 0x3FE0E0))
            ], cloverDefault: false)

        case "neon": // Cyberpunk: esagoni neri con bordo ciano
            return ThemeIconSet(frame: .outline(halo: UIColor(hex: 0x3A0A16)), glyphs: [
                .park: ("leaf.fill", w), .cinema: ("film.fill", w), .rail: ("tram.fill", w),
                .library: ("book.fill", w), .fuel: ("bolt.car.fill", w), .food: ("fork.knife", w),
                .cafe: ("cup.and.saucer.fill", w), .bar: ("wineglass.fill", w), .shop: ("bag.fill", w),
                .clothes: ("tshirt.fill", w), .health: ("cross.fill", w), .police: ("shield.lefthalf.filled", w),
                .bank: ("dollarsign", w), .lodging: ("house.fill", w), .school: ("graduationcap.fill", w),
                .parking: ("parkingsign", w), .sport: ("figure.boxing", w), .worship: ("sparkles", w),
                .museum: ("building.columns.fill", w), .car: ("car.fill", w), .default: ("cpu.fill", w)
            ], cloverDefault: false)

        case "heat": // corse notturne
            return ThemeIconSet(frame: .outline(halo: UIColor(hex: 0x22003F)), glyphs: [
                .park: ("tree.fill", w), .cinema: ("film.fill", w), .rail: ("tram.fill", w),
                .library: ("book.fill", w), .fuel: ("fuelpump.fill", w), .food: ("fork.knife", w),
                .cafe: ("cup.and.saucer.fill", w), .bar: ("die.face.5.fill", w), .shop: ("cart.fill", w),
                .clothes: ("tshirt.fill", w), .health: ("cross.fill", w), .police: ("light.beacon.max.fill", w),
                .bank: ("building.columns.fill", w), .lodging: ("house.fill", w), .school: ("graduationcap.fill", w),
                .parking: ("parkingsign", w), .sport: ("flag.checkered", w), .worship: ("building.columns.fill", w),
                .museum: ("building.columns.fill", w), .car: ("car.fill", w), .default: ("flag.checkered", w)
            ], cloverDefault: false)

        default: // "kingdom" – medievale
            let gold = UIColor(hex: 0xF2C230)
            return ThemeIconSet(frame: .outline(halo: UIColor(hex: 0x2B1B0B)), glyphs: [
                .park: ("tree.fill", w), .cinema: ("theatermasks.fill", w), .rail: ("figure.equestrian.sports", w),
                .library: ("book.closed.fill", w), .fuel: ("flame.fill", w), .food: ("fork.knife", w),
                .cafe: ("mug.fill", w), .bar: ("mug.fill", w), .shop: ("bag.fill", w),
                .clothes: ("hanger", w), .health: ("leaf.fill", w), .police: ("shield.fill", w),
                .bank: ("bag.fill", w), .lodging: ("house.fill", w), .school: ("scroll.fill", w),
                .parking: ("figure.equestrian.sports", w), .sport: ("figure.fencing", w), .worship: ("building.columns.fill", w),
                .museum: ("crown.fill", w), .car: ("figure.equestrian.sports", w), .default: ("exclamationmark", gold)
            ], cloverDefault: false)
        }
    }

    // MARK: Installazione nello stile

    static func install(in style: MLNStyle, theme: MapTheme) {
        for name in allNames {
            if let img = image(named: name, theme: theme) {
                style.setImage(img, forName: name)
            }
        }
    }

    static var allNames: [String] {
        POICategory.allCases.map { $0.imageName }
            + ["gm-oneway", "gm-shield", "gm-dot"]
            + Textures.names
    }

    static func image(named name: String, theme: MapTheme) -> UIImage? {
        switch name {
        case "gm-oneway": return oneway(color: theme.iconColor)
        case "gm-shield": return shield(theme: theme)
        case "gm-dot": return dot(color: theme.iconColor)
        case _ where Textures.names.contains(name): return Textures.image(named: name)
        default:
            guard name.hasPrefix("gm-poi-"),
                  let cat = POICategory(rawValue: String(name.dropFirst("gm-poi-".count))) else { return nil }
            return poiIcon(cat, theme: theme, pointSize: 30)
        }
    }

    /// Icona di una categoria nello stile del tema.
    static func poiIcon(_ cat: POICategory, theme: MapTheme, pointSize: CGFloat) -> UIImage? {
        let set = iconSet(for: theme)
        if cat == .default && set.cloverDefault {
            return clover(color: theme.accent, size: pointSize * 1.45)
        }
        if theme.id == "pixel", let sprite = PixelArt.sprite(for: cat) {
            return sprite
        }
        let glyph = set.glyphs[cat] ?? set.glyphs[.default] ?? ("mappin", theme.iconColor)
        return framedSymbol(glyph.0, color: glyph.1, frame: set.frame, pointSize: pointSize)
    }

    /// Icona per un simbolo qualunque nello stile del tema (usata dai segnaposto del globo).
    static func themedSymbol(_ symbol: String, color: UIColor? = nil, theme: MapTheme, pointSize: CGFloat) -> UIImage? {
        let set = iconSet(for: theme)
        let c = color ?? set.glyphs[.default]?.1 ?? theme.iconColor
        return framedSymbol(symbol, color: c, frame: set.frame, pointSize: pointSize)
    }

    // MARK: Disegno

    static func framedSymbol(_ name: String, color: UIColor, frame: IconFrame, pointSize: CGFloat) -> UIImage? {
        switch frame {
        case .outline(let halo):
            return outlinedSymbol(name, color: color, halo: halo, pointSize: pointSize)
        case .pixel(let halo):
            guard let small = outlinedSymbol(name, color: color, halo: halo, pointSize: pointSize * 0.42, scale: 1) else { return nil }
            return pixelate(small, factor: 2.4)
        case .badge(let fill, let ring):
            return enclosed(name, color: color, pointSize: pointSize) { ctx, rect in
                ctx.setFillColor(fill.cgColor)
                ctx.fillEllipse(in: rect)
                ctx.setStrokeColor(ring.cgColor)
                ctx.setLineWidth(rect.width * 0.07)
                ctx.strokeEllipse(in: rect.insetBy(dx: rect.width * 0.035, dy: rect.width * 0.035))
            }
        case .hexagon(let fill, let ring):
            return enclosed(name, color: color, pointSize: pointSize) { ctx, rect in
                let path = hexagonPath(in: rect)
                ctx.addPath(path)
                ctx.setFillColor(fill.cgColor)
                ctx.fillPath()
                ctx.addPath(path)
                ctx.setStrokeColor(ring.cgColor)
                ctx.setLineWidth(rect.width * 0.07)
                ctx.strokePath()
            }
        }
    }

    private static func hexagonPath(in rect: CGRect) -> CGPath {
        let p = CGMutablePath()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = rect.width / 2 * 0.95
        for i in 0..<6 {
            let a = CGFloat(i) * .pi / 3 - .pi / 2
            let pt = CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }

    private static func enclosed(_ name: String, color: UIColor, pointSize: CGFloat,
                                 background: (CGContext, CGRect) -> Void) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize * 0.62, weight: .bold)
        guard let base = UIImage(systemName: name, withConfiguration: config) else { return nil }
        let side = pointSize * 1.45
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: fmt).image { ctx in
            let rect = CGRect(x: 1, y: 1, width: side - 2, height: side - 2)
            background(ctx.cgContext, rect)
            let s = base.size
            let r = CGRect(x: (side - s.width) / 2, y: (side - s.height) / 2, width: s.width, height: s.height)
            base.withTintColor(color, renderingMode: .alwaysOriginal).draw(in: r)
        }
    }

    private static func pixelate(_ image: UIImage, factor: CGFloat) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let w = Int(CGFloat(cg.width) * factor)
        let h = Int(CGFloat(cg.height) * factor)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2
        return UIGraphicsImageRenderer(size: CGSize(width: CGFloat(w) / 2, height: CGFloat(h) / 2), format: fmt).image { ctx in
            let c = ctx.cgContext
            c.interpolationQuality = .none
            c.translateBy(x: 0, y: CGFloat(h) / 2)
            c.scaleBy(x: 1, y: -1)
            c.draw(cg, in: CGRect(x: 0, y: 0, width: CGFloat(w) / 2, height: CGFloat(h) / 2))
        }
    }

    /// Simbolo SF con contorno
    static func outlinedSymbol(_ name: String, color: UIColor, halo: UIColor, pointSize: CGFloat,
                               scale: CGFloat = 2) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .black)
        guard let base = UIImage(systemName: name, withConfiguration: config) else { return nil }
        let o: CGFloat = max(1, pointSize * 0.085)
        let pad = o * 2.4
        let size = CGSize(width: base.size.width + pad * 2, height: base.size.height + pad * 2)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = scale
        return UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
            let haloImg = base.withTintColor(halo, renderingMode: .alwaysOriginal)
            let r = CGRect(x: pad, y: pad, width: base.size.width, height: base.size.height)
            for i in 0..<12 {
                let a = CGFloat(i) / 12 * 2 * .pi
                haloImg.draw(in: r.offsetBy(dx: cos(a) * o, dy: sin(a) * o))
            }
            base.withTintColor(color, renderingMode: .alwaysOriginal).draw(in: r)
        }
    }

    /// Quadrifoglio viola (segnaposto luoghi, tema Vice Noir)
    static func clover(color: UIColor, size: CGFloat) -> UIImage {
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2
        return UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: fmt).image { ctx in
            let c = ctx.cgContext
            let s = size
            let petal = s * 0.36
            let mid = s / 2
            let centers = [
                CGPoint(x: mid, y: mid - petal * 0.62),
                CGPoint(x: mid, y: mid + petal * 0.62),
                CGPoint(x: mid - petal * 0.62, y: mid),
                CGPoint(x: mid + petal * 0.62, y: mid)
            ]
            c.setFillColor(UIColor.white.cgColor)
            for p in centers {
                c.fillEllipse(in: CGRect(x: p.x - petal / 2 - 2, y: p.y - petal / 2 - 2, width: petal + 4, height: petal + 4))
            }
            c.setFillColor(color.cgColor)
            for p in centers {
                c.fillEllipse(in: CGRect(x: p.x - petal / 2, y: p.y - petal / 2, width: petal, height: petal))
            }
            c.fillEllipse(in: CGRect(x: mid - petal * 0.55, y: mid - petal * 0.55, width: petal * 1.1, height: petal * 1.1))
            c.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
            c.fillEllipse(in: CGRect(x: mid - petal * 0.2, y: mid - petal * 0.2, width: petal * 0.4, height: petal * 0.4))
        }
    }

    static func oneway(color: UIColor) -> UIImage {
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2
        return UIGraphicsImageRenderer(size: CGSize(width: 24, height: 14), format: fmt).image { ctx in
            let c = ctx.cgContext
            c.setStrokeColor(color.cgColor)
            c.setLineWidth(2.4)
            c.setLineCap(.round)
            c.setLineJoin(.round)
            c.move(to: CGPoint(x: 3, y: 7)); c.addLine(to: CGPoint(x: 20, y: 7))
            c.move(to: CGPoint(x: 14, y: 2.5)); c.addLine(to: CGPoint(x: 20, y: 7)); c.addLine(to: CGPoint(x: 14, y: 11.5))
            c.strokePath()
        }
    }

    static func shield(theme: MapTheme) -> UIImage {
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2
        let color: UIColor
        switch theme.id {
        case "bunker": color = UIColor(hex: 0x0F5F0F)
        case "neon", "heat": color = UIColor(hex: 0xFF2E7E)
        case "dust", "kingdom": color = UIColor(hex: 0x6B4A28)
        default: color = UIColor(hex: 0x2F47C9)
        }
        return UIGraphicsImageRenderer(size: CGSize(width: 24, height: 16), format: fmt).image { _ in
            let path = UIBezierPath(roundedRect: CGRect(x: 1, y: 1, width: 22, height: 14), cornerRadius: 3)
            color.setFill(); path.fill()
            UIColor.white.setStroke(); path.lineWidth = 1.2; path.stroke()
        }
    }

    static func dot(color: UIColor) -> UIImage {
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2
        return UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12), format: fmt).image { ctx in
            ctx.cgContext.setFillColor(UIColor.black.withAlphaComponent(0.6).cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: 12, height: 12))
            ctx.cgContext.setFillColor(color.cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x: 2.5, y: 2.5, width: 7, height: 7))
        }
    }
}
