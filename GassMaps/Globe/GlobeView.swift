import SwiftUI
import SceneKit

struct GlobeView: UIViewRepresentable {
    let theme: MapTheme
    /// dimensione della vista in punti
    let size: CGSize
    /// raggio del globo in punti
    let radius: CGFloat
    /// distanza in punti dal bordo superiore della vista alla sommità del globo
    let top: CGFloat

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
        view.isPlaying = true
        view.rendersContinuously = true
        context.coordinator.apply(theme: theme)
        context.coordinator.layout(size: size, radius: radius, top: top)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.apply(theme: theme)
        context.coordinator.layout(size: size, radius: radius, top: top)
    }
}

final class GlobeCoordinator {
    let scene = SCNScene()
    private let earth = SCNNode()
    private let markersNode = SCNNode()
    private let cameraNode = SCNNode()
    private var currentThemeID: String?

    init() {
        scene.background.contents = UIColor.clear

        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 1
        camera.zNear = 0.1
        camera.zFar = 20
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 5)
        scene.rootNode.addChildNode(cameraNode)

        // Terra
        let geometry = GlobeCoordinator.makeSphere(radius: 1, latSegments: 90, lonSegments: 180)
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = UIColor.darkGray
        material.diffuse.mipFilter = .linear
        material.isDoubleSided = false
        material.shaderModifiers = [
            .fragment: """
            float3 gm_n = normalize(_surface.normal);
            float3 gm_v = normalize(_surface.view);
            float gm_rim = 1.0 - max(dot(gm_n, gm_v), 0.0);
            _output.color.rgb = _output.color.rgb * (1.0 - 0.25 * pow(gm_rim, 2.0)) + float3(0.45, 0.65, 1.0) * pow(gm_rim, 5.0) * 0.9;
            """
        ]
        geometry.materials = [material]
        earth.geometry = geometry
        earth.eulerAngles = SCNVector3(0, Float(-20.0 * .pi / 180.0), 0)
        scene.rootNode.addChildNode(earth)
        earth.addChildNode(markersNode)

        // Atmosfera
        let halo = SCNSphere(radius: 1.035)
        halo.segmentCount = 96
        let haloMat = SCNMaterial()
        haloMat.lightingModel = .constant
        haloMat.diffuse.contents = UIColor.clear
        haloMat.cullMode = .front
        haloMat.blendMode = .add
        haloMat.writesToDepthBuffer = false
        haloMat.shaderModifiers = [
            .fragment: """
            float gm_d = abs(dot(normalize(_surface.normal), normalize(_surface.view)));
            float gm_a = smoothstep(0.0, 0.26, gm_d);
            _output.color = float4(0.42, 0.66, 1.0, 1.0) * gm_a * 0.95;
            """
        ]
        halo.materials = [haloMat]
        let haloNode = SCNNode(geometry: halo)
        haloNode.renderingOrder = 10
        scene.rootNode.addChildNode(haloNode)

        // rotazione continua (verso est)
        let spin = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: -CGFloat.pi * 2, z: 0, duration: 150))
        earth.runAction(spin)
    }

    /// Proiezione ortografica: il globo (raggio 1) appare con raggio `radius` punti,
    /// con la sommità a `top` punti dal bordo superiore della vista.
    func layout(size: CGSize, radius: CGFloat, top: CGFloat) {
        guard size.height > 0, radius > 0 else { return }
        let k = 1.0 / Double(radius)                      // unità mondo per punto
        cameraNode.camera?.orthographicScale = Double(size.height) / 2 * k
        let camY = (Double(top + radius) - Double(size.height) / 2) * k
        cameraNode.position = SCNVector3(0, Float(camY), 5)
    }

    func apply(theme: MapTheme) {
        guard theme.id != currentThemeID else { return }
        currentThemeID = theme.id
        let material = earth.geometry?.firstMaterial
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
        buildMarkers(theme)
    }

    private func buildMarkers(_ theme: MapTheme) {
        markersNode.childNodes.forEach { $0.removeFromParentNode() }
        for marker in theme.markers {
            guard let image = MapIcons.outlinedSymbol(marker.symbol, color: theme.iconColor,
                                                      halo: theme.iconHalo, pointSize: 40) else { continue }
            let aspect = image.size.width / max(image.size.height, 1)
            let h: CGFloat = 0.075
            let plane = SCNPlane(width: h * aspect, height: h)
            let mat = SCNMaterial()
            mat.lightingModel = .constant
            mat.diffuse.contents = image
            mat.isDoubleSided = true
            mat.writesToDepthBuffer = false
            plane.materials = [mat]
            let node = SCNNode(geometry: plane)
            node.position = GlobeCoordinator.position(lat: marker.lat, lon: marker.lon, radius: 1.02)
            let billboard = SCNBillboardConstraint()
            billboard.freeAxes = .all
            node.constraints = [billboard]
            markersNode.addChildNode(node)
        }
    }

    static func position(lat: Double, lon: Double, radius: Double) -> SCNVector3 {
        let la = lat * .pi / 180
        let lo = lon * .pi / 180
        return SCNVector3(Float(radius * cos(la) * sin(lo)),
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

        let geometry = SCNGeometry(
            sources: [
                SCNGeometrySource(vertices: vertices),
                SCNGeometrySource(normals: normals),
                SCNGeometrySource(textureCoordinates: uvs)
            ],
            elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)]
        )
        return geometry
    }
}
