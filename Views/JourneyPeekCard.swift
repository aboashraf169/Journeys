import SwiftUI

/// Floating card shown on single-tap of an orb.
/// Displays last progress point + today's task status.
/// On first ever tap it also shows a one-time gesture guide row.
struct JourneyPeekCard: View {
    let journey: Journey
    let showGestureHint: Bool
    let onDismiss: () -> Void

    private var accent: Color {
        journey.isFinished
            ? Color(hue: 0.11, saturation: 0.30, brightness: 1.0)
            : Color(hue: journey.hue, saturation: 0.75, brightness: 1.0)
    }

    private var progressPercent: Int { Int(journey.progress * 100) }

    private var lastAchievement: String {
        if journey.completedDays == 0 { return "no days logged yet" }
        if journey.isFinished         { return "all \(journey.totalDays) days complete" }
        return "day \(journey.completedDays) completed"
    }

    private var taskSummary: String {
        if journey.isFinished         { return "journey finished" }
        if journey.currentTasks.isEmpty { return "no tasks set" }
        let done  = journey.currentTasks.filter(\.isCompleted).count
        let total = journey.currentTasks.count
        if done == total { return "all tasks done — ready to advance" }
        return "\(done) of \(total) tasks done today"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header row ───────────────────────────────────────────────
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(journey.name)
                        .font(.system(size: 17, weight: .light))
                        .foregroundColor(.white.opacity(0.90))

                    Text(lastAchievement)
                        .font(.system(size: 11, weight: .light, design: .monospaced))
                        .foregroundColor(accent.opacity(0.85))
                }

                Spacer()

                // Percent badge
                Text("\(progressPercent)%")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(accent.opacity(0.12))
                            .overlay(Capsule().strokeBorder(accent.opacity(0.30), lineWidth: 0.5))
                    )
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)

            // ── Progress bar ─────────────────────────────────────────────
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 3)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.6), accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(journey.progress), height: 3)
                        .animation(.easeOut(duration: 0.6), value: journey.progress)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 18)
            .padding(.top, 12)

            // ── Task status ──────────────────────────────────────────────
            HStack(spacing: 6) {
                Image(systemName: journey.allTasksDone ? "checkmark.circle.fill" : "circle.dotted")
                    .font(.system(size: 11))
                    .foregroundColor(journey.allTasksDone ? accent : .white.opacity(0.40))

                Text(taskSummary)
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundColor(journey.allTasksDone ? accent.opacity(0.85) : .white.opacity(0.45))
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)

            // ── One-time gesture guide (first tap only) ──────────────────
            if showGestureHint {
                Divider()
                    .background(Color.white.opacity(0.08))
                    .padding(.horizontal, 18)
                    .padding(.top, 12)

                HStack(spacing: 0) {
                    gestureHint(icon: "hand.tap.fill",    label: "double tap", desc: "open")
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 0.5, height: 28)
                    Spacer()
                    gestureHint(icon: "hand.point.up.left.fill", label: "hold", desc: "complete day")
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 0.5, height: 28)
                    Spacer()
                    gestureHint(icon: "arrow.up.and.down",       label: "drag", desc: "reposition")
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 4)
            }

            Spacer(minLength: 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
                )
                // Accent glow along top edge
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(accent.opacity(0.45))
                        .frame(width: 60, height: 2)
                        .blur(radius: 3)
                        .padding(.top, 1)
                }
        )
        .shadow(color: accent.opacity(0.18), radius: 24)
        .onTapGesture { onDismiss() }
    }

    private func gestureHint(icon: String, label: String, desc: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.45))
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.30))
            Text(desc)
                .font(.system(size: 9, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.50))
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            JourneyPeekCard(
                journey: Journey(name: "English", totalDays: 90,
                                 completedDays: 14, shape: .circle, hue: 0.58),
                showGestureHint: true,
                onDismiss: {}
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 38)
        }
    }
}
