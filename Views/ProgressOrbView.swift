import SwiftUI

// MARK: - Orb Geometry

struct OrbGeometry: Shape {
    let shape: OrbShape

    func path(in rect: CGRect) -> Path {
        switch shape {
        case .circle:   return Circle().path(in: rect)
        case .hexagon:  return hexagonPath(in: rect)
        case .triangle: return trianglePath(in: rect)
        case .diamond:  return diamondPath(in: rect)
        }
    }

    private func hexagonPath(in rect: CGRect) -> Path {
        Path { p in
            let cx = rect.midX, cy = rect.midY
            let r  = min(rect.width, rect.height) / 2
            for i in 0..<6 {
                let θ = CGFloat(i) * .pi / 3 - .pi / 6
                let pt = CGPoint(x: cx + r * cos(θ), y: cy + r * sin(θ))
                i == 0 ? p.move(to: pt) : p.addLine(to: pt)
            }
            p.closeSubpath()
        }
    }

    private func trianglePath(in rect: CGRect) -> Path {
        Path { p in
            p.move(to:    CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }

    private func diamondPath(in rect: CGRect) -> Path {
        Path { p in
            p.move(to:    CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            p.closeSubpath()
        }
    }
}

// MARK: - Size helper (used by StarfieldView for label offset)

extension Journey {
    /// Min 90 pt → grows to 150 pt at full progress
    var orbSize: CGFloat { 90 + CGFloat(progress) * 60 }
}

// MARK: - Progress Orb

struct ProgressOrbView: View {
    let journey: Journey
    let namespace: Namespace.ID
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onLongPress: () -> Void

    @State private var shakePhase: CGFloat = 0
    @State private var breathing: Bool = false
    @State private var finishedRotation: Double = 0

    // MARK: Derived colors

    private var primaryColor: Color {
        journey.isFinished
            ? Color(hue: 0.11, saturation: 0.30, brightness: 1.0)  // warm gold
            : Color(hue: journey.hue, saturation: 0.80, brightness: 1.0)
    }

    /// Glow halo strength — frozen is visible but clearly muted
    private var glowOpacity: Double {
        if journey.isFinished { return 0.70 }
        if journey.isFrozen   { return 0.45 }          // was 0.15 — too faint
        return 0.65 + journey.progress * 0.30
    }

    /// Overall orb opacity — frozen is clearly "paused", not invisible
    private var orbOpacity: Double {
        if journey.isFinished { return 1.0 }
        return journey.isFrozen ? 0.72 : 1.0            // was 0.45 — too transparent
    }

    var body: some View {
        ZStack {
            // ── Outer ambient glow (large, very soft) ──────────────────────
            OrbGeometry(shape: journey.shape)
                .fill(primaryColor.opacity(journey.isFrozen ? 0.06 : 0.14))
                .frame(width: journey.orbSize * 1.9, height: journey.orbSize * 1.9)
                .blur(radius: journey.orbSize * 0.55)

            // ── Finished journey: slow-rotating ring ───────────────────────
            if journey.isFinished {
                OrbGeometry(shape: journey.shape)
                    .stroke(primaryColor.opacity(0.55), lineWidth: 1.5)
                    .frame(width: journey.orbSize + 18, height: journey.orbSize + 18)
                    .rotationEffect(.degrees(finishedRotation))
                    .onAppear {
                        withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                            finishedRotation = 360
                        }
                    }
            }

            // ── Progress arc (trim around orb boundary) ─────────────────────
            if journey.progress > 0 && !journey.isFinished {
                Circle()
                    .trim(from: 0, to: CGFloat(journey.progress))
                    .stroke(
                        primaryColor.opacity(journey.isFrozen ? 0.35 : 0.70),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .frame(width: journey.orbSize + 10, height: journey.orbSize + 10)
                    .rotationEffect(.degrees(-90))
            }

            // ── Mid glow ring ───────────────────────────────────────────────
            OrbGeometry(shape: journey.shape)
                .fill(primaryColor.opacity(journey.isFrozen ? 0.18 : 0.40))
                .frame(width: journey.orbSize * 1.15, height: journey.orbSize * 1.15)
                .blur(radius: 12)

            // ── Core shape ──────────────────────────────────────────────────
            OrbGeometry(shape: journey.shape)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(journey.isFrozen ? 0.55 : 0.85),   // bright centre
                            primaryColor.opacity(journey.isFrozen ? 0.70 : 0.95),  // colour band
                            primaryColor.opacity(journey.isFrozen ? 0.30 : 0.60),  // edge
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: journey.orbSize / 2
                    )
                )
                .frame(width: journey.orbSize, height: journey.orbSize)
                // Hard edge shadow layers — define the orb in dark space
                .shadow(color: primaryColor.opacity(glowOpacity * 0.9), radius: 14)
                .shadow(color: primaryColor.opacity(glowOpacity * 0.6), radius: 30)
                .shadow(color: primaryColor.opacity(glowOpacity * 0.3), radius: 55)
        }
        // ── State transforms ────────────────────────────────────────────────
        .opacity(orbOpacity)
        // Frozen: very subtle blur only — still clearly readable
        .blur(radius: journey.isFrozen ? 0.4 : 0)      // was 1.5 — too blurry
        // Ready (all tasks done): gentle breathing pulse
        .scaleEffect(
            journey.allTasksDone && !journey.isFinished
                ? (breathing ? 1.08 : 0.94)
                : 1.0
        )
        .modifier(ShakeEffect(animatableData: shakePhase))
        // ── Matched geometry (expand → timeline) ────────────────────────────
        .matchedGeometryEffect(id: journey.id, in: namespace)
        // ── Gestures ────────────────────────────────────────────────────────
        .gesture(
            TapGesture(count: 2).onEnded {
                HapticFeedback.light(); onDoubleTap()
            }
            .exclusively(before:
                TapGesture(count: 1).onEnded {
                    HapticFeedback.light(); onTap()
                }
            )
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.55).onEnded { _ in onLongPress() }
        )
        .onAppear(perform: syncAnimations)
        .onChange(of: journey.isFrozen)     { _ in syncAnimations() }
        .onChange(of: journey.allTasksDone) { _ in syncAnimations() }
        .onChange(of: journey.isFinished)   { _ in syncAnimations() }
    }

    // MARK: Animation sync

    private func syncAnimations() {
        if journey.isFrozen && !journey.isFinished {
            withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                shakePhase = 1
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) { shakePhase = 0 }
        }

        if journey.allTasksDone && !journey.isFinished {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                breathing = true
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) { breathing = false }
        }
    }
}

// MARK: - Previews

#Preview("Frozen orb") {
    let j = Journey(name: "English", totalDays: 90, shape: .circle, hue: 0.58)
    return ProgressOrbView(
        journey: j, namespace: Namespace().wrappedValue,
        onTap: {}, onDoubleTap: {}, onLongPress: {}
    )
    .frame(width: 300, height: 300)
    .background(Color.black)
}

#Preview("Ready orb") {
    var j = Journey(name: "Gym", totalDays: 30, completedDays: 15, shape: .hexagon, hue: 0.12)
    j.currentTasks = j.currentTasks.map { DayTask(id: $0.id, title: $0.title, isCompleted: true) }
    return ProgressOrbView(
        journey: j, namespace: Namespace().wrappedValue,
        onTap: {}, onDoubleTap: {}, onLongPress: {}
    )
    .frame(width: 300, height: 300)
    .background(Color.black)
}

#Preview("Finished orb") {
    var j = Journey(name: "Reading", totalDays: 30, completedDays: 30, shape: .diamond, hue: 0.75)
    j.currentTasks = []
    return ProgressOrbView(
        journey: j, namespace: Namespace().wrappedValue,
        onTap: {}, onDoubleTap: {}, onLongPress: {}
    )
    .frame(width: 300, height: 300)
    .background(Color.black)
}
