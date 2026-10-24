import UIKit
import MapLibre

/// Immagini disegnate a runtime e registrate nello stile MapLibre.
enum MapIcons {
    static let poiSymbols: [String: String] = [
        "gm-poi-park": "tree.fill",
        "gm-poi-cinema": "video.fill",
        "gm-poi-rail": "tram.fill",
        "gm-poi-library": "book.fill",
        "gm-poi-fuel": "fuelpump.fill",
        "gm-poi-food": "fork.knife",
        "gm-poi-cafe": "cup.and.saucer.fill",
        "gm-poi-shop": "bag.fill",
        "gm-poi-health": "cross.case.fill",
        "gm-poi-school": "graduationcap.fill",
        "gm-poi-parking": "parkingsign.circle.fill",
        "gm-poi-sport": "sportscourt.fill"
    ]

    static func install(in style: MLNStyle, theme: MapTheme) {
        for name in allNames {
            if let img = image(named: name, theme: theme) {
                style.setImage(img, forName: name)
            }
        }
    }

    static var allNames: [String] {
        Array(poiSymbols.keys) + ["gm-poi-default", "gm-oneway", "gm-shield", "gm-dot"]
    }

    static func image(named name: String, theme: MapTheme) -> UIImage? {
        switch name {
        case "gm-poi-default": return clover(color: theme.accent, size: 44)
        case "gm-oneway": return oneway(color: theme.iconColor)
        case "gm-shield": return shield(theme: theme)
        case "gm-dot": return dot(color: theme.iconColor)
        default:
            if let symbol = poiSymbols[name] {
                return outlinedSymbol(symbol, color: theme.iconColor, halo: theme.iconHalo, pointSize: 30)
            }
            return nil
        }
    }

    /// Simbolo SF con contorno (stile icone mappa "videogioco")
    static func outlinedSymbol(_ name: String, color: UIColor, halo: UIColor, pointSize: CGFloat) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .black)
        guard let base = UIImage(systemName: name, withConfiguration: config) else { return nil }
        let pad: CGFloat = 6
        let size = CGSize(width: base.size.width + pad * 2, height: base.size.height + pad * 2)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2
        return UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
            let haloImg = base.withTintColor(halo, renderingMode: .alwaysOriginal)
            let r = CGRect(x: pad, y: pad, width: base.size.width, height: base.size.height)
            let o: CGFloat = 2.6
            for dx in stride(from: -o, through: o, by: o) {
                for dy in stride(from: -o, through: o, by: o) where dx != 0 || dy != 0 {
                    haloImg.draw(in: r.offsetBy(dx: dx, dy: dy))
                }
            }
            base.withTintColor(color, renderingMode: .alwaysOriginal).draw(in: r)
        }
    }

    /// Quadrifoglio viola (segnaposto luoghi)
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
            // contorno bianco
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
