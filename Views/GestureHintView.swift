import SwiftUI

/// Shown once on first launch. Explains every gesture in the app.
/// Dismissed by tapping anywhere.
struct GestureHintView: View {

    let onDismiss: () -> Void

    @State private var visible = false

    var body: some View {
        ZStack {
            // Dim backdrop
            Color.black.opacity(0.82)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                Spacer()
                hintsCard
                Spacer()
                tapToDismiss
                    .padding(.bottom, 44)
            }
        }
        .opacity(visible ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.35)) { visible = true }
        }
    }

    // MARK: - Hints card

    private var hintsCard: some View {
        VStack(alignment: .leading, spacing: 28) {

            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("how it works")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(2)

                Text("every journey is an orb.")
                    .font(.system(size: 20, weight: .ultraLight))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 4)

            Divider().background(Color.white.opacity(0.1))

            // Gestures
            hintRow(
                icon: "hand.tap.fill",
                gesture: "tap",
                description: "focus the orb — shows your current day"
            )
            hintRow(
                icon: "hand.draw.fill",
                gesture: "long press",
                description: "complete today's work and advance"
            )
            hintRow(
                icon: "hand.tap",
                gesture: "double tap",
                description: "open the day-by-day timeline"
            )

            Divider().background(Color.white.opacity(0.1))

            // Orb states
            VStack(alignment: .leading, spacing: 16) {
                stateRow(color: .white.opacity(0.25), label: "dim + blurred",  meaning: "frozen — tasks not done yet")
                stateRow(color: .cyan,                label: "pulsing",        meaning: "ready — all tasks complete")
                stateRow(color: .white,               label: "gold ring",      meaning: "finished — journey complete")
            }

            Divider().background(Color.white.opacity(0.1))

            // In timeline
            hintRow(
                icon: "checkmark.circle",
                gesture: "tap task",
                description: "check off today's task in the timeline"
            )
            hintRow(
                icon: "plus.circle",
                gesture: "bottom +",
                description: "add a new journey to the canvas"
            )
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }

    // MARK: - Row builders

    private func hintRow(icon: String, gesture: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.55))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(gesture)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))

                Text(description)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }

    private func stateRow(color: Color, label: String, meaning: String) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .shadow(color: color.opacity(0.8), radius: 4)

            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 90, alignment: .leading)

            Text(meaning)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(.white.opacity(0.45))
        }
    }

    // MARK: - Dismiss

    private var tapToDismiss: some View {
        Text("tap anywhere to begin")
            .font(.system(size: 11, weight: .thin, design: .monospaced))
            .foregroundColor(.white.opacity(0.35))
            .tracking(1)
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) { visible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onDismiss() }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        GestureHintView(onDismiss: {})
    }
}
