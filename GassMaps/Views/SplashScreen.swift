import SwiftUI

struct SplashScreen: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var location: LocationManager
    @State private var progress: CGFloat = 0
    @State private var appeared = false

    private struct FloatingIcon: Identifiable {
        let id = UUID()
        let symbol: String
        let x: CGFloat   // 0...1
        let y: CGFloat   // 0...1
        let size: CGFloat
        let rotation: Double
        let colors: [Color]
    }

    private let icons: [FloatingIcon] = [
        FloatingIcon(symbol: "magnet", x: 0.10, y: 0.12, size: 64, rotation: -30, colors: [Color(white: 0.35), Color(white: 0.15)]),
        FloatingIcon(symbol: "wineglass.fill", x: 0.34, y: 0.10, size: 62, rotation: 10, colors: [Color(hex: 0x5BD15B), Color(hex: 0x1F7A2A)]),
        FloatingIcon(symbol: "suit.diamond.fill", x: 0.60, y: 0.11, size: 70, rotation: 0, colors: [Color(white: 0.45), Color(white: 0.15)]),
        FloatingIcon(symbol: "house.fill", x: 0.90, y: 0.17, size: 70, rotation: 20, colors: [Color(hex: 0x55C24A), Color(hex: 0x1E6A1A)]),
        FloatingIcon(symbol: "dollarsign.square.fill", x: 0.17, y: 0.33, size: 74, rotation: -12, colors: [Color(hex: 0x3BCB6A), Color(hex: 0x146B34)]),
        FloatingIcon(symbol: "suit.spade.fill", x: 0.47, y: 0.30, size: 70, rotation: 0, colors: [Color(hex: 0x7EA0FF), Color(hex: 0x2A3E8F)]),
        FloatingIcon(symbol: "flame.fill", x: 0.81, y: 0.35, size: 70, rotation: 70, colors: [Color(hex: 0xFFE38A), Color(hex: 0xC9A640)]),
        FloatingIcon(symbol: "birthday.cake.fill", x: 0.26, y: 0.59, size: 70, rotation: -15, colors: [Color(hex: 0xFFB7C5), Color(hex: 0x9E4E7A)]),
        FloatingIcon(symbol: "bed.double.fill", x: 0.68, y: 0.57, size: 74, rotation: -10, colors: [Color(hex: 0xC2378F), Color(hex: 0x5B1A70)]),
        FloatingIcon(symbol: "gamecontroller.fill", x: 0.10, y: 0.73, size: 64, rotation: 20, colors: [Color(white: 0.4), Color(white: 0.15)]),
        FloatingIcon(symbol: "car.fill", x: 0.46, y: 0.72, size: 72, rotation: -20, colors: [Color(hex: 0x8AA2FF), Color(hex: 0x2A3A80)]),
        FloatingIcon(symbol: "crown.fill", x: 0.88, y: 0.69, size: 72, rotation: 15, colors: [Color(white: 0.45), Color(white: 0.15)]),
        FloatingIcon(symbol: "star.fill", x: 0.22, y: 0.86, size: 56, rotation: 0, colors: [Color(white: 0.35), Color(white: 0.1)]),
        FloatingIcon(symbol: "die.face.5.fill", x: 0.55, y: 0.87, size: 56, rotation: 20, colors: [Color(white: 0.35), Color(white: 0.1)]),
        FloatingIcon(symbol: "bolt.fill", x: 0.82, y: 0.88, size: 56, rotation: -20, colors: [Color(white: 0.35), Color(white: 0.1)])
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                RadialGradient(colors: [Color(hex: 0x26262A), Color(hex: 0x141416), Color(hex: 0x09090A), .black],
                               center: UnitPoint(x: 0.5, y: 0.47), startRadius: 10, endRadius: geo.size.width * 0.95)

                ForEach(icons) { icon in
                    Image(systemName: icon.symbol)
                        .font(.system(size: icon.size, weight: .black))
                        .foregroundStyle(LinearGradient(colors: icon.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: .white.opacity(0.25), radius: 1, x: -1, y: -1)
                        .shadow(color: .black.opacity(0.7), radius: 6, x: 3, y: 5)
                        .opacity(0.88)
                        .rotationEffect(.degrees(icon.rotation))
                        .position(x: icon.x * geo.size.width, y: icon.y * geo.size.height)
                        .scaleEffect(appeared ? 1 : 0.92)
                }

                // dissolvenza verso il basso
                LinearGradient(colors: [.clear, .clear, .black.opacity(0.85), .black],
                               startPoint: .top, endPoint: .bottom)

                LogoView()
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.46)

                // barra di caricamento — misure prese dal video (393×852 pt):
                // traccia x 24…369, alta 21 pt, #181818, a 51 pt dal fondo; riempimento lucido alto 15 pt
                VStack {
                    Spacer()
                    LoadingBar(progress: progress)
                        .frame(height: 21)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 51)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            location.start()
            withAnimation(.easeInOut(duration: 2.4)) { appeared = true }
            withAnimation(.easeOut(duration: 1.1)) { progress = 0.62 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
                withAnimation(.easeInOut(duration: 0.7)) { progress = 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                state.finishSplash()
                GlobeTextureProvider.shared.preloadAll(Themes.all)
                // icone di tutti i temi pronte in anticipo: cambio tema immediato
                MapIcons.prewarm(state.theme)
                Themes.all.forEach { MapIcons.prewarm($0) }
            }
        }
    }
}

/// Scritta "GassMaps" nel font di GTA San Andreas (Pricedown): riempimento bianco, contorno nero spesso.
struct LogoView: View {
    var size: CGFloat = 66

    var body: some View {
        let text = Text("GassMaps").font(FontRegistry.gta(size: size))
        ZStack {
            // contorno nero (16 copie spostate) + ombra
            ForEach(0..<16, id: \.self) { i in
                let a = CGFloat(i) / 16 * 2 * .pi
                text.foregroundStyle(.black)
                    .offset(x: cos(a) * size * 0.06, y: sin(a) * size * 0.06)
            }
            text.foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.8), radius: 0, x: size * 0.04, y: size * 0.06)
        .shadow(color: .black.opacity(0.6), radius: 14)
        .fixedSize()
    }
}

/// Barra di caricamento identica al video: traccia scura e riempimento blu "a tubo" lucido.
struct LoadingBar: View {
    var progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: 0x181818))
                Capsule()
                    .fill(
                        LinearGradient(stops: [
                            .init(color: Color(hex: 0x68BBFE), location: 0.0),
                            .init(color: Color(hex: 0x359CFF), location: 0.18),
                            .init(color: Color(hex: 0x1784FF), location: 0.34),
                            .init(color: Color(hex: 0x0970FF), location: 0.5),
                            .init(color: Color(hex: 0x0B64FF), location: 0.64),
                            .init(color: Color(hex: 0x1A5DFF), location: 0.76),
                            .init(color: Color(hex: 0x3564FE), location: 0.88),
                            .init(color: Color(hex: 0x6983ED), location: 1.0)
                        ], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: max(15, (geo.size.width - 6) * progress), height: geo.size.height - 6)
                    .padding(.leading, 3)
                    .shadow(color: Color(hex: 0x0970FF).opacity(0.55), radius: 5)
            }
        }
    }
}
