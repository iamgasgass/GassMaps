import SwiftUI

/// Pulsante circolare "vetro scuro" usato su mappa e intestazioni.
struct GlassCircle<Content: View>: View {
    var size: CGFloat = 44
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Circle().fill(.ultraThinMaterial)
            Circle().fill(Color.black.opacity(0.45))
            Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            content
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
    }
}

struct BackCircleButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            GlassCircle(size: 44) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(PressableStyle())
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Icona "impostazioni" a ciambella (come nell'originale).
struct DonutIcon: View {
    var body: some View {
        Circle()
            .strokeBorder(Color.white, lineWidth: 5.5)
            .frame(width: 19, height: 19)
    }
}

/// Segnaposto blu a goccia del pulsante centrale.
struct BluePinIcon: View {
    var body: some View {
        ZStack {
            Image(systemName: "drop.fill")
                .font(.system(size: 26, weight: .regular))
                .rotationEffect(.degrees(180))
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: 0x4FA3FF), Color(hex: 0x1D6BFF)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: Color(hex: 0x1D6BFF).opacity(0.8), radius: 6)
            Circle()
                .fill(Color(hex: 0x0A1E3D))
                .frame(width: 8, height: 8)
                .offset(y: -3)
        }
    }
}

/// Quadrifoglio in SwiftUI (stesso disegno dell'icona mappa)
struct CloverIcon: View {
    var color: Color = Color(hex: 0x7B2CF0)
    var size: CGFloat = 22

    var body: some View {
        let petal = size * 0.36
        let off = petal * 0.62
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                let dx: CGFloat = i == 2 ? -off : (i == 3 ? off : 0)
                let dy: CGFloat = i == 0 ? -off : (i == 1 ? off : 0)
                Circle().fill(color).frame(width: petal, height: petal).offset(x: dx, y: dy)
            }
            Circle().fill(color).frame(width: petal * 1.1, height: petal * 1.1)
            Circle().fill(Color.white.opacity(0.9)).frame(width: petal * 0.4, height: petal * 0.4)
        }
        .frame(width: size, height: size)
    }
}

/// Pannello inferiore nero con maniglia, trascinabile per chiudere.
struct BottomPanel<Content: View>: View {
    var onDismiss: (() -> Void)?
    @ViewBuilder var content: Content
    @State private var drag: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.28))
                .frame(width: 42, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 16)
            content
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous)
                .fill(Color.black)
                .ignoresSafeArea(edges: .bottom)
        )
        .offset(y: max(drag, 0))
        .gesture(
            DragGesture()
                .onChanged { drag = $0.translation.height }
                .onEnded { value in
                    if value.translation.height > 110, let onDismiss = onDismiss {
                        onDismiss()
                    }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { drag = 0 }
                }
        )
    }
}

/// Riquadro tratteggiato per gli stati vuoti.
struct DashedEmptyCard: View {
    var icon: String
    var title: String
    var subtitle: String

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(Color(white: 0.11)).frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 10)
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(white: 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.13), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        )
    }
}

/// Pulsante capsula bianco (Continua / Ottieni indicazioni / Inizia ora)
struct WhiteCapsuleButton: View {
    var title: String
    var icon: String?
    var height: CGFloat = 54
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title).font(.system(size: 16, weight: .semibold))
                if let icon = icon {
                    Image(systemName: icon).font(.system(size: 15, weight: .bold))
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                Capsule().fill(
                    LinearGradient(colors: [.white, Color(white: 0.86)], startPoint: .top, endPoint: .bottom)
                )
            )
            .shadow(color: .white.opacity(0.12), radius: 8)
        }
        .buttonStyle(PressableStyle())
    }
}
