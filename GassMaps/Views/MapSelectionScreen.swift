import SwiftUI

struct MapSelectionScreen: View {
    @EnvironmentObject var state: AppState
    @State private var index: Int = Themes.defaultIndex
    @State private var globeTheme: MapTheme = Themes.all[Themes.defaultIndex]
    @State private var globeOffset: CGFloat = 0
    @State private var transitioning = false
    @State private var didAppear = false

    private var theme: MapTheme { Themes.all[index] }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let fullH = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
            ZStack(alignment: .top) {
                LinearGradient(colors: [theme.backgroundTop, theme.backgroundBottom],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: index)

                StarField()
                    .ignoresSafeArea()
                    .opacity(theme.id == "pixel" ? 0.35 : 1)

                GlobeView(theme: globeTheme,
                          size: CGSize(width: w, height: fullH),
                          radius: w * 1.5,
                          top: geo.safeAreaInsets.top + 112)
                    .frame(width: w, height: fullH)
                    .offset(y: globeOffset)
                    .ignoresSafeArea()
                    .opacity(didAppear ? 1 : 0)
                    .allowsHitTesting(false)

                // sfumatura inferiore dietro ai controlli
                VStack {
                    Spacer()
                    LinearGradient(colors: [.clear, theme.backgroundBottom.opacity(0.55), theme.backgroundBottom.opacity(0.9)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 300)
                        .blur(radius: 8)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        BackCircleButton { state.showMapSelection = false }
                        Text("Selezione mappa 🎨")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Spacer()

                    HStack {
                        arrowButton("arrow.left") { move(-1) }
                        Spacer()
                        Text(theme.name)
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.4), radius: 6)
                            .id(theme.id)
                            .transition(.opacity)
                        Spacer()
                        arrowButton("arrow.right") { move(1) }
                    }
                    .padding(.horizontal, 16)

                    PageDots(count: Themes.all.count, index: index)
                        .padding(.top, 22)
                        .padding(.bottom, 22)

                    Button {
                        state.themeIndex = index
                        state.showMapSelection = false
                    } label: {
                        HStack(spacing: 8) {
                            Text("Continua").font(.system(size: 17, weight: .semibold))
                            Image(systemName: "arrow.right.circle.fill").font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            Capsule().fill(LinearGradient(colors: [.white, Color(white: 0.85)],
                                                          startPoint: .top, endPoint: .bottom))
                        )
                        .colorMultiply(theme.buttonTint)
                    }
                    .buttonStyle(PressableStyle())
                    .opacity(transitioning ? 0.45 : 1)
                    .disabled(transitioning)
                    .padding(.horizontal, 20)
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, 12) + 4)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        if value.translation.width < -60 { move(1) }
                        else if value.translation.width > 60 { move(-1) }
                    }
            )
        }
        .onAppear {
            index = state.themeIndex
            globeTheme = state.theme
            withAnimation(.easeOut(duration: 0.5)) { didAppear = true }
        }
    }

    private func arrowButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            GlassCircle(size: 46) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(PressableStyle())
        .opacity(transitioning ? 0.4 : 1)
        .disabled(transitioning)
    }

    private func move(_ delta: Int) {
        guard !transitioning else { return }
        let count = Themes.all.count
        let next = (index + delta + count) % count
        transitioning = true
        withAnimation(.easeIn(duration: 0.32)) {
            globeOffset = 900
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            index = next
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            globeTheme = Themes.all[next]
            withAnimation(.spring(response: 0.6, dampingFraction: 0.86)) {
                globeOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                transitioning = false
            }
        }
    }
}

struct PageDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(Color.white.opacity(i == index ? 1 : 0.4))
                    .frame(width: i == index ? 22 : 6, height: 6)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: index)
    }
}

struct StarField: View {
    private struct Star { let x: CGFloat; let y: CGFloat; let r: CGFloat; let a: Double }

    private let stars: [Star] = {
        var gen = SeededGenerator(seed: 42)
        return (0..<170).map { _ in
            Star(x: CGFloat.random(in: 0...1, using: &gen),
                 y: CGFloat.random(in: 0...1, using: &gen),
                 r: CGFloat.random(in: 0.4...1.3, using: &gen),
                 a: Double.random(in: 0.25...0.9, using: &gen))
        }
    }()

    var body: some View {
        Canvas { ctx, size in
            for s in stars {
                let rect = CGRect(x: s.x * size.width, y: s.y * size.height, width: s.r * 2, height: s.r * 2)
                ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(s.a)))
            }
        }
        .allowsHitTesting(false)
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
