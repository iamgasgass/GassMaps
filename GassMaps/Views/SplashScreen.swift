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
                RadialGradient(colors: [Color(hex: 0x1E4BFF).opacity(0.85), Color(hex: 0x0A1A6B).opacity(0.5), .clear],
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

                VStack {
                    Spacer()
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(white: 0.12))
                        Capsule()
                            .fill(LinearGradient(colors: [Color(hex: 0x2457FF), Color(hex: 0x3D7BFF)],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(14, (geo.size.width - 40) * progress))
                    }
                    .frame(height: 13)
                    .padding(.horizontal, 20)
                    .padding(.bottom, geo.safeAreaInsets.bottom + 34)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            location.start()
            withAnimation(.easeInOut(duration: 2.4)) { appeared = true }
            withAnimation(.easeInOut(duration: 2.6)) { progress = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                state.finishSplash()
                GlobeTextureProvider.shared.preloadAll(Themes.all)
            }
        }
    }
}

struct LogoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: -12) {
            Text("GASS")
            Text("MAPS")
            HStack(alignment: .center, spacing: 2) {
                Text("IRL")
                RouteSquiggle()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    .frame(width: 70, height: 34)
                    .overlay(alignment: .trailing) {
                        ZStack {
                            Circle().strokeBorder(Color.white, lineWidth: 5).frame(width: 22, height: 22)
                        }
                        .offset(x: 10, y: -4)
                    }
            }
        }
        .font(.system(size: 52, weight: .black).width(.expanded))
        .foregroundStyle(.white)
        .shadow(color: Color(hex: 0x1E4BFF).opacity(0.8), radius: 18)
    }
}

struct RouteSquiggle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.maxY - 4))
        p.addCurve(to: CGPoint(x: rect.width * 0.45, y: rect.midY),
                   control1: CGPoint(x: rect.width * 0.2, y: rect.maxY + 2),
                   control2: CGPoint(x: rect.width * 0.25, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.width * 0.8, y: rect.maxY - 6),
                   control1: CGPoint(x: rect.width * 0.6, y: rect.maxY + 4),
                   control2: CGPoint(x: rect.width * 0.7, y: rect.maxY))
        return p
    }
}
