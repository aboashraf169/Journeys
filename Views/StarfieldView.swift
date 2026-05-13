import SwiftUI

struct StarfieldView: View {
    @StateObject private var store = JourneyStore()
    @Namespace  private var morphSpace

    @State private var canvasOffset: CGSize = .zero
    @State private var lastOffset:   CGSize = .zero
    @State private var selectedJourneyID: UUID? = nil
    @State private var showAdd   = false
    @State private var showHints = false

    // Orb individual drag
    @State private var draggingOrbID: UUID?   = nil
    @State private var orbDragStart:  CGPoint = .zero

    @AppStorage("hintsShown") private var hintsShown = false

    private var selectedJourney: Journey? {
        guard let id = selectedJourneyID else { return nil }
        return store.journeys.first { $0.id == id }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                BackgroundStarsView()
                orbCanvas(in: geo)

                // ── Timeline detail ──────────────────────────────────────
                if let journey = selectedJourney {
                    TimelineThreadView(
                        journey: journey,
                        namespace: morphSpace,
                        store: store,
                        onDismiss: collapse
                    )
                    .transition(.identity)
                    .zIndex(10)
                }

                // ── Gesture tutorial overlay ─────────────────────────────
                if showHints {
                    GestureHintView {
                        withAnimation { showHints = false }
                        hintsShown = true
                    }
                    .zIndex(20)
                }

                // ── Add button — bottom center ───────────────────────────
                addButton
                    .zIndex(8)
            }
        }
        .onAppear { if !hintsShown { showHints = true } }
        .sheet(isPresented: $showAdd) { AddJourneyView(store: store) }
    }

    // MARK: - Orb canvas

    @ViewBuilder
    private func orbCanvas(in geo: GeometryProxy) -> some View {
        let cx = geo.size.width  / 2
        let cy = geo.size.height / 2

        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .simultaneousGesture(draggingOrbID == nil ? panGesture : nil)

            ForEach(store.journeys.filter { $0.id != selectedJourneyID }) { journey in
                let ox = cx + journey.canvasX + canvasOffset.width
                let oy = cy + journey.canvasY + canvasOffset.height

                // ── Day counter ──
                dayCounter(journey: journey)
                    .position(x: ox, y: oy - journey.orbSize / 2 - 22)

                // ── Orb ──
                ProgressOrbView(
                    journey: journey,
                    namespace: morphSpace,
                    onTap:       { expand(journey) },
                    onDoubleTap: { expand(journey) },
                    onLongPress: { completeDay(journey) }
                )
                .position(x: ox, y: oy)
                .simultaneousGesture(orbDragGesture(for: journey))

                // ── Name label ──
                Text(journey.name)
                    .font(.system(size: 12, weight: .light, design: .monospaced))
                    .tracking(1.5)
                    .foregroundColor(nameColor(journey))
                    .position(x: ox, y: oy + journey.orbSize / 2 + 18)
            }
        }
        .opacity(selectedJourneyID != nil ? 0.15 : 1)
        .animation(.easeInOut(duration: 0.28), value: selectedJourneyID)
    }

    // MARK: - Day counter badge

    private func dayCounter(journey: Journey) -> some View {
        HStack(spacing: 4) {
            if journey.isFinished {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hue: 0.11, saturation: 0.3, brightness: 1.0))
                Text("complete")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hue: 0.11, saturation: 0.3, brightness: 1.0).opacity(0.9))
            } else {
                Text("day")
                    .font(.system(size: 10, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.50))
                Text("\(journey.currentDayNumber)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.95))
                Text("/ \(journey.totalDays)")
                    .font(.system(size: 10, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.50))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5))
        )
    }

    // MARK: - Add button (bottom center)

    private var addButton: some View {
        VStack {
            Spacer()
            AddOrbButton { showAdd = true }
                .padding(.bottom, 44)
        }
        .opacity(selectedJourneyID != nil ? 0 : 1)
        .animation(.easeInOut(duration: 0.2), value: selectedJourneyID)
    }

    // MARK: - Actions

    private func expand(_ journey: Journey) {
        withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
            selectedJourneyID = journey.id
        }
    }

    private func collapse() {
        withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
            selectedJourneyID = nil
        }
    }

    private func completeDay(_ journey: Journey) {
        guard journey.allTasksDone else {
            HapticFeedback.warning()
            return
        }
        let wasFinished = journey.isFinished
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            store.completeDay(id: journey.id)
        }
        let updated = store.journeys.first { $0.id == journey.id }
        if updated?.isFinished == true && !wasFinished {
            HapticFeedback.success()
        } else {
            HapticFeedback.medium()
        }
    }

    // MARK: - Helpers

    private func nameColor(_ journey: Journey) -> Color {
        if journey.isFinished { return Color(hue: 0.12, saturation: 0.3, brightness: 1.0).opacity(0.75) }
        return .white.opacity(journey.isFrozen ? 0.50 : 0.80)
    }

    private func orbDragGesture(for journey: Journey) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { v in
                if draggingOrbID != journey.id {
                    draggingOrbID = journey.id
                    orbDragStart  = CGPoint(x: journey.canvasX, y: journey.canvasY)
                }
                store.updateCanvasPosition(
                    id: journey.id,
                    x: orbDragStart.x + v.translation.width,
                    y: orbDragStart.y + v.translation.height
                )
            }
            .onEnded { _ in
                draggingOrbID = nil
                store.persistPositions()
            }
    }

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { v in
                canvasOffset = CGSize(
                    width:  lastOffset.width  + v.translation.width,
                    height: lastOffset.height + v.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = canvasOffset
                store.persistPositions()
            }
    }
}

#Preview { StarfieldView() }
