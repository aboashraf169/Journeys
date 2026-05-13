import SwiftUI

/// Floating action button — pale frosted core with orbiting colour rings.
struct AddOrbButton: View {
    let action: () -> Void

    @State private var hue:       Double = 0.55
    @State private var breathing: Bool   = false
    @State private var pressed:   Bool   = false
    @State private var ripple:    Bool   = false
    @State private var ring1:     Double = 0
    @State private var ring2:     Double = 0

    private var c1: Color { Color(hue: hue,        saturation: 0.80, brightness: 1.0) }
    private var c2: Color { Color(hue: hue + 0.20, saturation: 0.75, brightness: 1.0) }
    private var c3: Color { Color(hue: hue + 0.40, saturation: 0.70, brightness: 1.0) }
    private var c4: Color { Color(hue: hue + 0.60, saturation: 0.78, brightness: 1.0) }

    var body: some View {
        Button {
            HapticFeedback.medium()
            triggerRipple()
            action()
        } label: {
            ZStack {

                // ── Soft colour nebula (far background) ───────────────────
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [c1.opacity(0.22), c2.opacity(0.12), .clear],
                            center: .center, startRadius: 8, endRadius: 78
                        )
                    )
                    .frame(width: 156, height: 156)
                    .blur(radius: 24)

                // ── Ripple ring ───────────────────────────────────────────
                Circle()
                    .strokeBorder(c1.opacity(ripple ? 0 : 0.50), lineWidth: 1)
                    .frame(width: ripple ? 120 : 68, height: ripple ? 120 : 68)
                    .animation(.easeOut(duration: 0.70), value: ripple)

                // ── Outer rotating colour ring ────────────────────────────
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [c1, c2, c3, c4, c1],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .frame(width: 82, height: 82)
                    .rotationEffect(.degrees(ring1))
                    .opacity(0.75)

                // ── Inner counter-rotating colour ring ───────────────────
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [c3, c2, c4, c1, c3],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 1.0, dash: [3, 6])
                    )
                    .frame(width: 68, height: 68)
                    .rotationEffect(.degrees(ring2))
                    .opacity(0.55)

                // ── Coloured glow behind core ─────────────────────────────
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [c1.opacity(0.30), c2.opacity(0.15), .clear],
                            center: .center, startRadius: 0, endRadius: 32
                        )
                    )
                    .frame(width: 64, height: 64)
                    .blur(radius: 10)

                // ── Core — pale frosted white ─────────────────────────────
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.98),
                                Color.white.opacity(0.88),
                                Color.white.opacity(0.55),
                                Color.white.opacity(0.15),
                            ],
                            center: .init(x: 0.40, y: 0.36),
                            startRadius: 0,
                            endRadius: 28
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: c1.opacity(0.55), radius: 12)
                    .shadow(color: c2.opacity(0.35), radius: 26)
                    .shadow(color: c3.opacity(0.20), radius: 46)

                // ── Specular dot ──────────────────────────────────────────
                Ellipse()
                    .fill(Color.white)
                    .frame(width: 14, height: 8)
                    .blur(radius: 3)
                    .offset(x: -9, y: -11)
                    .opacity(0.75)

                // ── Plus — dark so it pops on white ──────────────────────
                Image(systemName: "plus")
                    .font(.system(size: 19, weight: .ultraLight))
                    .foregroundColor(Color.black.opacity(0.45))
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(breathing ? 1.06 : 0.95)
        .scaleEffect(pressed ? 0.87 : 1.0)
        .animation(.spring(response: 0.20, dampingFraction: 0.52), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true  }
                .onEnded   { _ in pressed = false }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                breathing = true
            }
            withAnimation(.linear(duration: 26).repeatForever(autoreverses: false)) {
                hue  += 1.0
            }
            withAnimation(.linear(duration: 11).repeatForever(autoreverses: false)) {
                ring1 = 360
            }
            withAnimation(.linear(duration: 17).repeatForever(autoreverses: false)) {
                ring2 = -360
            }
        }
    }

    private func triggerRipple() {
        ripple = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            ripple = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                ripple = false
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AddOrbButton { }
    }
}
