import SwiftUI
import SceneKit
import simd

/// Globo 3D della "Selezione mappa".
/// Camera prospettica ricavata dal video originale:
/// zoom 3.18 · pitch 13° · FOV verticale 33.8° · centro a 22.9°N, 150 pt sotto il centro schermo (su 852 pt).
struct GlobeView: UIViewRepresentable {
    let theme: MapTheme
    /// altezza della vista in punti (serve per tenere costante la dimensione delle etichette)
    let height: CGFloat

    func makeCoordinator() -> GlobeCoordinator { GlobeCoordinator() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = .multisampling4X
        view.allowsCameraControl = false
        view.isUserInteractionEnabled = false
        view.preferredFramesPerSecond = 60
        view.scene = context.coordinator.scene
        view.pointOfView = context.coordinator.cameraNode
        view.delegate = context.coordinator
        view.isPlaying = true
        view.rendersContinuously = true
        context.coordinator.viewHeight = height
        context.coordinator.apply(theme: theme)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.viewHeight = height
        context.coordinator.apply(theme: theme)
    }
}

final class GlobeCoordinator: NSObject, SCNSceneRendererDelegate {
    // Parametri ricavati dal video (vedi sopra)
    static let targetLat: Double = 22.87
    static let pitchDeg: Double = 12.98
    static let fovDeg: Double = 33.76
    static let zoom: Double = 3.177
    static let screenRefHeight: Double = 852
    static let targetOffsetPt: Double = 150   // il punto guardato è 150 pt sotto il centro

    let scene = SCNScene()
    let cameraNode = SCNNode()
    var viewHeight: CGFloat = 852

    private let earth = SCNNode()
    private let labelsNode = SCNNode()
    private let markersNode = SCNNode()
    private var currentThemeID: String?

    private struct Billboard {
        let node: SCNNode
        let heightPt: Float     // altezza desiderata sullo schermo
        let priority: Int
        let sizePt: CGSize
    }
    private var billboards: [Billboard] = []
    private let lock = NSLock()
    private var frameCount = 0

    // camera
    private var camPos = SIMD3<Float>(0, 0, 3)
    private var camForward = SIMD3<Float>(0, 0, -1)

    override init() {
        super.init()
        scene.background.contents = UIColor.clear
        setupCamera()
        setupEarth()
        setupAtmosphere()

        // rotazione continua verso est (come nel video)
        let spin = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: -CGFloat.pi * 2, z: 0, duration: 26))
        earth.runAction(spin)
    }

    // MARK: Camera prospettica

    private func setupCamera() {
        let fov = GlobeCoordinator.fovDeg * .pi / 180
        let focalPt = (GlobeCoordinator.screenRefHeight / 2) / tan(fov / 2)
        let radiusPt = 512 * pow(2, GlobeCoordinator.zoom) / (2 * .pi)
        let dist = focalPt / radiusPt                  // distanza camera-punto guardato, in raggi terrestri
        let la = GlobeCoordinator.targetLat * .pi / 180
        let p = GlobeCoordinator.pitchDeg * .pi / 180

        let n = SIMD3<Double>(0, sin(la), cos(la))       // normale nel punto guardato (lon 0)
        let north = SIMD3<Double>(0, cos(la), -sin(la))
        let target = n
        let pos = target + dist * (n * cos(p) - north * sin(p))
        var f = simd_normalize(target - pos)
        var up = n * sin(p) + north * cos(p)
        // il punto guardato appare 150 pt sotto il centro: ruoto la camera verso l'alto
        let delta = atan(GlobeCoordinator.targetOffsetPt / focalPt)
        let f2 = f * cos(delta) + up * sin(delta)
        let up2 = up * cos(delta) - f * sin(delta)
        f = f2; up = up2

        let camera = SCNCamera()
        camera.projectionDirection = .vertical
        camera.fieldOfView = CGFloat(GlobeCoordinator.fovDeg)
        camera.zNear = 0.01
        camera.zFar = 20
        cameraNode.camera = camera
        cameraNode.simdPosition = SIMD3<Float>(Float(pos.x), Float(pos.y), Float(pos.z))
        let look = pos + f
        cameraNode.simdLook(at: SIMD3<Float>(Float(look.x), Float(look.y), Float(look.z)),
                            up: SIMD3<Float>(Float(up.x), Float(up.y), Float(up.z)),
                            localFront: SIMD3<Float>(0, 0, -1))
        scene.rootNode.addChildNode(cameraNode)
        camPos = cameraNode.simdPosition
        camForward = SIMD3<Float>(Float(f.x), Float(f.y), Float(f.z))
    }

    // MARK: Terra

    private func setupEarth() {
        let geometry = GlobeCoordinator.makeSphere(radius: 1, latSegments: 128, lonSegments: 256)
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = UIColor.darkGray
        material.diffuse.mipFilter = .linear
        material.diffuse.minificationFilter = .linear
        material.diffuse.magnificationFilter = .linear
        material.isDoubleSided = false
        material.shaderModifiers = [
            .fragment: """
            #pragma arguments
            float3 hazeColor;
            float3 glowColor;
            #pragma body
            float3 gm_n = normalize(_surface.normal);
            float3 gm_v = normalize(_surface.view);
            float gm_d = clamp(dot(gm_n, gm_v), 0.0, 1.0);
            float gm_rim = 1.0 - gm_d;
            // foschia atmosferica verso l'orizzonte (come la "fog" del globo originale)
            float gm_haze = pow(gm_rim, 3.5);
            float3 gm_c = mix(_output.color.rgb, hazeColor, clamp(gm_haze * 0.85, 0.0, 0.9));
            // linea luminosa sul bordo
            gm_c += glowColor * pow(gm_rim, 14.0) * 1.3;
            _output.color.rgb = gm_c;
            """
        ]
        geometry.materials = [material]
        earth.geometry = geometry
        earth.eulerAngles = SCNVector3(0, Float(-39.25 * .pi / 180.0), 0)
        scene.rootNode.addChildNode(earth)
        earth.addChildNode(labelsNode)
        earth.addChildNode(markersNode)
    }

    private func setupAtmosphere() {
        let halo = SCNSphere(radius: 1.05)
        halo.segmentCount = 128
        let haloMat = SCNMaterial()
        haloMat.lightingModel = .constant
        haloMat.diffuse.contents = UIColor.clear
        haloMat.cullMode = .front
        haloMat.blendMode = .add
        haloMat.writesToDepthBuffer = false
        haloMat.shaderModifiers = [
            .fragment: """
            #pragma arguments
            float3 glowColor;
            #pragma body
            float gm_d = abs(dot(normalize(_surface.normal), normalize(_surface.view)));
            // 0 sul bordo esterno dell'alone, ~0.31 sul bordo della Terra
            float gm_t = smoothstep(0.0, 0.31, gm_d);
            float3 gm_col = mix(glowColor, float3(1.0, 1.0, 1.0), pow(gm_t, 6.0));
            _output.color = float4(gm_col * pow(gm_t, 2.2) * 1.05, 1.0);
            """
        ]
        halo.materials = [haloMat]
        let haloNode = SCNNode(geometry: halo)
        haloNode.name = "halo"
        haloNode.renderingOrder = 5
        scene.rootNode.addChildNode(haloNode)
    }

    // MARK: Tema

    func apply(theme: MapTheme) {
        guard theme.id != currentThemeID else { return }
        currentThemeID = theme.id

        let material = earth.geometry?.firstMaterial
        material?.setValue(GlobeCoordinator.vec(theme.haze), forKey: "hazeColor")
        material?.setValue(GlobeCoordinator.vec(theme.glow), forKey: "glowColor")
        scene.rootNode.childNode(withName: "halo", recursively: false)?
            .geometry?.firstMaterial?.setValue(GlobeCoordinator.vec(theme.glow), forKey: "glowColor")

        if let cached = GlobeTextureProvider.shared.cached(theme) {
            material?.diffuse.contents = cached
        } else {
            material?.diffuse.contents = GlobeTextureProvider.fallback(for: theme)
            let id = theme.id
            GlobeTextureProvider.shared.texture(for: theme) { [weak self] image in
                guard let self = self, self.currentThemeID == id, let image = image else { return }
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.4
                material?.diffuse.contents = image
                SCNTransaction.commit()
            }
        }
        buildBillboards(theme)
    }

    private static func vec(_ c: UIColor) -> NSValue {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return NSValue(scnVector3: SCNVector3(Float(r), Float(g), Float(b)))
    }

    private func buildBillboards(_ theme: MapTheme) {
        lock.lock()
        defer { lock.unlock() }
        labelsNode.childNodes.forEach { $0.removeFromParentNode() }
        markersNode.childNodes.forEach { $0.removeFromParentNode() }
        billboards.removeAll()

        // icone del tema (priorità massima)
        for marker in theme.markers {
            guard let image = MapIcons.outlinedSymbol(marker.symbol, color: theme.iconColor,
                                                      halo: theme.iconHalo, pointSize: 40) else { continue }
            let node = makeBillboardNode(image: image)
            node.simdPosition = GlobeCoordinator.position(lat: marker.lat, lon: marker.lon, radius: 1.01)
            markersNode.addChildNode(node)
            let aspect = image.size.width / max(image.size.height, 1)
            billboards.append(Billboard(node: node, heightPt: 26, priority: 0,
                                        sizePt: CGSize(width: 26 * aspect, height: 26)))
        }

        // etichette
        for (i, label) in GlobeLabels.all.enumerated() {
            let text = theme.globeUppercase ? label.name.uppercased() : label.name
            guard let image = GlobeCoordinator.labelImage(text: text, isCity: label.isCity, theme: theme) else { continue }
            let node = makeBillboardNode(image: image)
            node.simdPosition = GlobeCoordinator.position(lat: label.lat, lon: label.lon, radius: 1.004)
            labelsNode.addChildNode(node)
            let h: CGFloat = label.isCity ? 11 : 12.5
            let aspect = image.size.width / max(image.size.height, 1)
            billboards.append(Billboard(node: node, heightPt: Float(h), priority: label.isCity ? 2000 + i : 1000 + i,
                                        sizePt: CGSize(width: h * aspect, height: h)))
        }
        billboards.sort { $0.priority < $1.priority }
    }

    private func makeBillboardNode(image: UIImage) -> SCNNode {
        let aspect = image.size.width / max(image.size.height, 1)
        let plane = SCNPlane(width: aspect, height: 1)
        let mat = SCNMaterial()
        mat.lightingModel = .constant
        mat.diffuse.contents = image
        mat.isDoubleSided = true
        mat.writesToDepthBuffer = false
        mat.readsFromDepthBuffer = false
        plane.materials = [mat]
        let node = SCNNode(geometry: plane)
        node.renderingOrder = 20
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .all
        node.constraints = [billboard]
        node.scale = SCNVector3(0.001, 0.001, 0.001)
        return node
    }

    static func labelImage(text: String, isCity: Bool, theme: MapTheme) -> UIImage? {
        let fontSize: CGFloat = 36
        let font = UIFont(name: theme.globeFont, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .heavy)
        let strokeAttrs: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: theme.globeLabelHalo,
            .strokeColor: theme.globeLabelHalo, .strokeWidth: 22
        ]
        let fillAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: theme.globeLabel]
        let textSize = (text as NSString).size(withAttributes: fillAttrs)
        let pad: CGFloat = 8
        let dot: CGFloat = isCity ? 22 : 0
        let size = CGSize(width: ceil(textSize.width + pad * 2 + dot), height: ceil(textSize.height + pad * 2))
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 1
        return UIGraphicsImageRenderer(size: size, format: fmt).image { ctx in
            if isCity {
                let r = CGRect(x: pad, y: size.height / 2 - 7, width: 14, height: 14)
                ctx.cgContext.setFillColor(theme.globeLabelHalo.withAlphaComponent(0.7).cgColor)
                ctx.cgContext.fillEllipse(in: r)
                ctx.cgContext.setFillColor(theme.globeLabel.cgColor)
                ctx.cgContext.fillEllipse(in: r.insetBy(dx: 3, dy: 3))
            }
            let origin = CGPoint(x: pad + dot, y: pad)
            (text as NSString).draw(at: origin, withAttributes: strokeAttrs)
            (text as NSString).draw(at: origin, withAttributes: fillAttrs)
        }
    }

    // MARK: Aggiornamento per frame: dimensione costante su schermo, visibilità e collisioni

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let viewHeight = self.viewHeight
        guard viewHeight > 0 else { return }
        lock.lock()
        defer { lock.unlock() }
        frameCount += 1
        let fov = Float(GlobeCoordinator.fovDeg * .pi / 180)
        let worldPerPtAtUnitDepth = 2 * tan(fov / 2) / Float(viewHeight)
        let doCollisions = frameCount % 4 == 0
        var placed: [CGRect] = []

        for b in billboards {
            let p = b.node.presentation.simdWorldPosition
            let toPoint = p - camPos
            let depth = simd_dot(toPoint, camForward)
            // lato visibile della sfera?
            let facing = -simd_dot(simd_normalize(toPoint), simd_normalize(p))
            guard depth > 0, facing > 0.02 else {
                if !b.node.isHidden { b.node.isHidden = true }
                continue
            }
            // dimensione costante sullo schermo (leggermente più piccola vicino all'orizzonte)
            let s = b.heightPt * worldPerPtAtUnitDepth * depth
            b.node.scale = SCNVector3(s, s, s)
            let fade = min(1, (facing - 0.02) / 0.12)

            if doCollisions {
                let sp = renderer.projectPoint(SCNVector3(p.x, p.y, p.z))
                let rect = CGRect(x: CGFloat(sp.x) - b.sizePt.width / 2, y: CGFloat(sp.y) - b.sizePt.height / 2,
                                  width: b.sizePt.width, height: b.sizePt.height).insetBy(dx: -3, dy: -2)
                if placed.contains(where: { $0.intersects(rect) }) {
                    b.node.isHidden = true
                    continue
                }
                placed.append(rect)
                b.node.isHidden = false
            }
            b.node.opacity = CGFloat(fade)
        }
    }

    // MARK: Geometria

    static func position(lat: Double, lon: Double, radius: Double) -> SIMD3<Float> {
        let la = lat * .pi / 180
        let lo = lon * .pi / 180
        return SIMD3<Float>(Float(radius * cos(la) * sin(lo)),
                            Float(radius * sin(la)),
                            Float(radius * cos(la) * cos(lo)))
    }

    /// Sfera con mappatura UV equirettangolare esplicita (u = longitudine, v = latitudine dall'alto).
    static func makeSphere(radius: Double, latSegments: Int, lonSegments: Int) -> SCNGeometry {
        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var uvs: [CGPoint] = []
        vertices.reserveCapacity((latSegments + 1) * (lonSegments + 1))

        for i in 0...latSegments {
            let v = Double(i) / Double(latSegments)
            let lat = (90.0 - 180.0 * v) * .pi / 180
            for j in 0...lonSegments {
                let u = Double(j) / Double(lonSegments)
                let lon = (-180.0 + 360.0 * u) * .pi / 180
                let n = SCNVector3(Float(cos(lat) * sin(lon)), Float(sin(lat)), Float(cos(lat) * cos(lon)))
                normals.append(n)
                vertices.append(SCNVector3(n.x * Float(radius), n.y * Float(radius), n.z * Float(radius)))
                uvs.append(CGPoint(x: u, y: v))
            }
        }

        var indices: [UInt32] = []
        let row = lonSegments + 1
        for i in 0..<latSegments {
            for j in 0..<lonSegments {
                let a = UInt32(i * row + j)
                let b = UInt32(i * row + j + 1)
                let c = UInt32((i + 1) * row + j)
                let d = UInt32((i + 1) * row + j + 1)
                indices += [a, c, b, b, c, d]
            }
        }

        return SCNGeometry(
            sources: [
                SCNGeometrySource(vertices: vertices),
                SCNGeometrySource(normals: normals),
                SCNGeometrySource(textureCoordinates: uvs)
            ],
            elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)]
        )
    }
}
