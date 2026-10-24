import UIKit
import MapLibre

/// Freccia bianca dell'utente con croce di mira, in stile "videogioco".
final class UserArrowView: MLNUserLocationAnnotationView {
    private let container = CALayer()
    private let arrowLeft = CAShapeLayer()
    private let arrowRight = CAShapeLayer()
    private let hLine = CAGradientLayer()
    private let vLine = CAGradientLayer()
    private var configured = false
    /// colore della freccia per il tema attivo
    static var tint: UIColor = .white
    /// tipo di indicatore per il tema attivo (0 freccia, 1 ingranaggio, 2 anello)
    static var marker: Int = 0
    private var appliedTint: UIColor?
    private var appliedMarker: Int = -1
    private let markerLayer = CALayer()

    override func update() {
        if !configured { configure() }
        if appliedMarker != UserArrowView.marker {
            appliedMarker = UserArrowView.marker
            let arrow = appliedMarker == 0
            arrowLeft.isHidden = !arrow
            arrowRight.isHidden = !arrow
            hLine.isHidden = !arrow
            vLine.isHidden = !arrow
            markerLayer.isHidden = arrow
            markerLayer.contents = UserArrowView.markerImage(appliedMarker)?.cgImage
        }
        if appliedTint != UserArrowView.tint {
            appliedTint = UserArrowView.tint
            var h: CGFloat = 0, sat: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            UserArrowView.tint.getHue(&h, saturation: &sat, brightness: &b, alpha: &a)
            arrowLeft.fillColor = UserArrowView.tint.cgColor
            arrowRight.fillColor = UIColor(hue: h, saturation: sat, brightness: b * 0.78, alpha: a).cgColor
        }
        guard let map = mapView else { return }

        var heading: Double = 0
        if let h = userLocation?.heading, h.trueHeading >= 0 {
            heading = h.trueHeading
        } else if let c = userLocation?.location?.course, c >= 0 {
            heading = c
        }
        let angle = CGFloat((heading - map.direction) * .pi / 180)
        let pitch = CGFloat(map.camera.pitch * .pi / 180)

        var t = CATransform3DIdentity
        t.m34 = -1.0 / 400
        t = CATransform3DRotate(t, pitch * 0.85, 1, 0, 0)
        t = CATransform3DRotate(t, angle, 0, 0, 1)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        container.transform = t
        CATransaction.commit()
    }

    private func configure() {
        configured = true
        frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        clipsToBounds = false
        backgroundColor = .clear

        // croce di mira (in coordinate schermo)
        let lineColor = UIColor.white.withAlphaComponent(0.55).cgColor
        let clear = UIColor.white.withAlphaComponent(0).cgColor
        hLine.colors = [clear, lineColor, lineColor, clear]
        hLine.locations = [0, 0.3, 0.7, 1]
        hLine.startPoint = CGPoint(x: 0, y: 0.5)
        hLine.endPoint = CGPoint(x: 1, y: 0.5)
        hLine.frame = CGRect(x: 22 - 700, y: 21.5, width: 1400, height: 1)
        layer.addSublayer(hLine)

        vLine.colors = [clear, lineColor, lineColor, clear]
        vLine.locations = [0, 0.25, 0.75, 1]
        vLine.startPoint = CGPoint(x: 0.5, y: 0)
        vLine.endPoint = CGPoint(x: 0.5, y: 1)
        vLine.frame = CGRect(x: 21.5, y: 22 - 150, width: 1, height: 450)
        layer.addSublayer(vLine)

        container.frame = bounds
        layer.addSublayer(container)
        markerLayer.frame = bounds.insetBy(dx: -14, dy: -14)
        markerLayer.contentsGravity = .resizeAspect
        markerLayer.isHidden = true
        layer.addSublayer(markerLayer)

        let w: CGFloat = 44
        let left = UIBezierPath()
        left.move(to: CGPoint(x: w / 2, y: 3))
        left.addLine(to: CGPoint(x: 8, y: 40))
        left.addLine(to: CGPoint(x: w / 2, y: 31))
        left.close()
        let right = UIBezierPath()
        right.move(to: CGPoint(x: w / 2, y: 3))
        right.addLine(to: CGPoint(x: w - 8, y: 40))
        right.addLine(to: CGPoint(x: w / 2, y: 31))
        right.close()

        arrowLeft.path = left.cgPath
        arrowLeft.fillColor = UIColor.white.cgColor
        arrowRight.path = right.cgPath
        arrowRight.fillColor = UIColor(white: 0.78, alpha: 1).cgColor
        for l in [arrowLeft, arrowRight] {
            l.frame = container.bounds
            l.shadowColor = UIColor.black.cgColor
            l.shadowOpacity = 0.6
            l.shadowRadius = 4
            l.shadowOffset = CGSize(width: 0, height: 2)
            container.addSublayer(l)
        }
    }
}

extension UserArrowView {
    /// 1 = ingranaggio (Street Heat), 2 = anello-bussola marrone (Old Kingdom)
    static func markerImage(_ kind: Int) -> UIImage? {
        let size = CGSize(width: 72, height: 72)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 3
        return UIGraphicsImageRenderer(size: size, format: fmt).image { ctx in
            let c = ctx.cgContext
            if kind == 1 {
                let cfg = UIImage.SymbolConfiguration(pointSize: 54, weight: .regular)
                if let gear = UIImage(systemName: "gearshape", withConfiguration: cfg) {
                    let r = CGRect(x: (72 - gear.size.width) / 2, y: (72 - gear.size.height) / 2,
                                   width: gear.size.width, height: gear.size.height)
                    c.setShadow(offset: .zero, blur: 3, color: UIColor.black.withAlphaComponent(0.4).cgColor)
                    gear.withTintColor(UIColor.white.withAlphaComponent(0.85), renderingMode: .alwaysOriginal).draw(in: r)
                }
            } else {
                let brown = UIColor(hex: 0x4A2C1A)
                let center = CGPoint(x: 36, y: 36)
                c.setStrokeColor(brown.cgColor)
                c.setLineWidth(5)
                c.strokeEllipse(in: CGRect(x: 14, y: 14, width: 44, height: 44))
                c.setStrokeColor(UIColor(hex: 0xC9A27A).cgColor)
                c.setLineWidth(1.2)
                c.strokeEllipse(in: CGRect(x: 17.5, y: 17.5, width: 37, height: 37))
                c.setFillColor(brown.cgColor)
                for i in 0..<8 {
                    let a = CGFloat(i) * .pi / 4
                    let long: CGFloat = i % 2 == 0 ? 33 : 28
                    let tip = CGPoint(x: center.x + cos(a) * long, y: center.y + sin(a) * long)
                    let l = CGPoint(x: center.x + cos(a - 0.12) * 21, y: center.y + sin(a - 0.12) * 21)
                    let r = CGPoint(x: center.x + cos(a + 0.12) * 21, y: center.y + sin(a + 0.12) * 21)
                    c.move(to: l); c.addLine(to: tip); c.addLine(to: r); c.closePath()
                }
                c.fillPath()
            }
        }
    }
}

/// Fumetto bianco con quadrifoglio e nome del luogo.
final class PinBubbleView: MLNAnnotationView {
    private let bubble = UIView()
    private let icon = UIImageView()
    private let label = UILabel()
    private let tail = CAShapeLayer()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        scalesWithViewingDistance = false
        bubble.backgroundColor = .white
        bubble.layer.cornerRadius = 14
        bubble.layer.shadowColor = UIColor.black.cgColor
        bubble.layer.shadowOpacity = 0.35
        bubble.layer.shadowRadius = 8
        bubble.layer.shadowOffset = CGSize(width: 0, height: 3)
        addSubview(bubble)
        bubble.addSubview(icon)
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .black
        bubble.addSubview(label)
        tail.fillColor = UIColor.white.cgColor
        layer.insertSublayer(tail, at: 0)
    }

    func configure(title: String, accent: UIColor) {
        icon.image = MapIcons.clover(color: accent, size: 30)
        label.text = title
        let hasTitle = !title.isEmpty
        let height: CGFloat = 50
        let textWidth = hasTitle ? min(220, label.intrinsicContentSize.width) : 0
        let width: CGFloat = hasTitle ? 14 + 30 + 8 + textWidth + 16 : height
        let tailH: CGFloat = 10
        frame = CGRect(x: 0, y: 0, width: width, height: height + tailH)
        bubble.frame = CGRect(x: 0, y: 0, width: width, height: height)
        icon.frame = hasTitle ? CGRect(x: 14, y: 10, width: 30, height: 30) : CGRect(x: 10, y: 10, width: 30, height: 30)
        label.frame = CGRect(x: 52, y: 0, width: textWidth, height: height)
        label.isHidden = !hasTitle

        let p = UIBezierPath()
        p.move(to: CGPoint(x: width / 2 - 9, y: height - 1))
        p.addLine(to: CGPoint(x: width / 2, y: height + tailH))
        p.addLine(to: CGPoint(x: width / 2 + 9, y: height - 1))
        p.close()
        tail.path = p.cgPath
        centerOffset = CGVector(dx: 0, dy: -(height + tailH) / 2)
    }
}
