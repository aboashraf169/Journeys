import SwiftUI

struct TimelineThreadView: View {
    let journey: Journey
    let namespace: Namespace.ID
    let store: JourneyStore
    let onDismiss: () -> Void

    @State private var dismissOffset: CGFloat = 0
    @State private var timelineWidth: CGFloat = 300   // measured on appear; no UIScreen
    @State private var showDeleteConfirm = false
    @State private var showEdit = false

    private var primaryColor: Color {
        journey.isFinished
            ? Color(hue: 0.12, saturation: 0.35, brightness: 1.0)
            : Color(hue: journey.hue, saturation: 0.75, brightness: 1.0)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                timeline
                if !journey.isFinished { taskPanel }
                footerActions
            }
        }
        .matchedGeometryEffect(id: journey.id, in: namespace)
        .offset(y: dismissOffset)
        .gesture(swipeDismiss)
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showEdit) {
            EditJourneyView(store: store, journey: journey)
        }
        .confirmationDialog("Remove journey?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Remove \"\(journey.name)\"", role: .destructive) {
                store.remove(id: journey.id)
                onDismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text(journey.name)
                    .font(.system(size: 16, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.7))

                Group {
                    if journey.isFinished {
                        Text("complete")
                            .foregroundColor(primaryColor.opacity(0.6))
                    } else {
                        Text("day \(journey.currentDayNumber) of \(journey.totalDays)")
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
                .font(.system(size: 11, weight: .thin, design: .monospaced))
            }

            Spacer()

            HStack(spacing: 10) {
                // Edit button
                Button { showEdit = true } label: {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(.white.opacity(0.3))
                        )
                }
                .buttonStyle(.plain)

                // Close button
                Button(action: onDismiss) {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(.white.opacity(0.3))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 58)
        .padding(.bottom, 22)
    }

    // MARK: - Timeline thread

    private var timeline: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    threadPath
                    dayNodes
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                // Measure width once — avoids deprecated UIScreen.main
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear { timelineWidth = geo.size.width - 56 }
                    }
                )
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        proxy.scrollTo(journey.currentDayNumber, anchor: .center)
                    }
                }
            }
        }
    }

    // Sine-wave connector path
    private var threadPath: some View {
        Canvas { ctx, size in
            guard journey.totalDays > 1 else { return }
            var path = Path()
            for day in 1...journey.totalDays {
                let pt = nodeCenter(day: day, width: size.width)
                day == 1 ? path.move(to: pt) : path.addLine(to: pt)
            }
            ctx.stroke(path, with: .color(.white.opacity(0.07)), lineWidth: 1)
        }
        .frame(height: CGFloat(journey.totalDays) * nodeSpacing + 40)
    }

    private var dayNodes: some View {
        ForEach(1...max(1, journey.totalDays), id: \.self) { day in
            DayNodeView(
                day: day,
                isCompleted: day <= journey.completedDays,
                isCurrent:   day == journey.currentDayNumber && !journey.isFinished,
                color: primaryColor
            )
            .position(nodeCenter(day: day, width: timelineWidth))
            .id(day)
        }
        .frame(height: CGFloat(journey.totalDays) * nodeSpacing + 40)
    }

    // MARK: - Task Panel

    private var taskPanel: some View {
        VStack(spacing: 0) {
            Divider().background(Color.white.opacity(0.12))

            VStack(spacing: 16) {
                // Task label header
                HStack {
                    Text("today's tasks")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2)
                    Spacer()
                    Text(journey.allTasksDone ? "✓ done" : "\(journey.currentTasks.filter(\.isCompleted).count)/\(journey.currentTasks.count)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(journey.allTasksDone ? primaryColor : .white.opacity(0.35))
                }

                ForEach(journey.currentTasks) { task in
                    taskRow(task)
                }

                // Complete Day button — always visible; dims when tasks not done
                completeDayButton
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .animation(.easeInOut(duration: 0.22), value: journey.allTasksDone)
        }
        .background(Color.white.opacity(0.03))
    }

    private func taskRow(_ task: DayTask) -> some View {
        Button {
            HapticFeedback.light()
            store.toggleTask(journeyID: journey.id, taskID: task.id)
        } label: {
            HStack(spacing: 14) {
                // Checkbox — clear ring + fill when done
                ZStack {
                    Circle()
                        .strokeBorder(
                            task.isCompleted ? primaryColor : .white.opacity(0.4),
                            lineWidth: 1.5
                        )
                    if task.isCompleted {
                        Circle().fill(primaryColor.opacity(0.3))
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(primaryColor)
                    }
                }
                .frame(width: 26, height: 26)
                .animation(.easeInOut(duration: 0.18), value: task.isCompleted)

                Text(task.title)
                    .font(.system(size: 19, weight: .light))
                    .foregroundColor(.white.opacity(task.isCompleted ? 0.35 : 0.90))
                    .strikethrough(task.isCompleted, color: .white.opacity(0.20))

                Spacer()

                // Tap hint
                if !task.isCompleted {
                    Text("tap")
                        .font(.system(size: 9, weight: .thin, design: .monospaced))
                        .foregroundColor(.white.opacity(0.25))
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(task.isCompleted ? 0.02 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.white.opacity(task.isCompleted ? 0 : 0.1), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var completeDayButton: some View {
        let ready = journey.allTasksDone && !journey.isFinished

        return Button {
            guard ready else { HapticFeedback.warning(); return }
            HapticFeedback.medium()
            store.completeDay(id: journey.id)
            if store.journeys.first(where: { $0.id == journey.id })?.isFinished == true {
                HapticFeedback.success()
            }
            onDismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: ready ? "checkmark.circle.fill" : "circle.dashed")
                    .font(.system(size: 15))
                Text(ready ? "complete day \(journey.currentDayNumber)" : "finish tasks first")
                    .font(.system(size: 13, weight: ready ? .medium : .light, design: .monospaced))
            }
            .foregroundColor(ready ? primaryColor : .white.opacity(0.3))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ready ? primaryColor.opacity(0.12) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                ready ? primaryColor.opacity(0.4) : Color.white.opacity(0.1),
                                lineWidth: ready ? 1 : 0.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.25), value: ready)
    }

    // MARK: - Footer (delete)

    private var footerActions: some View {
        Button {
            HapticFeedback.light()
            showDeleteConfirm = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                Text("remove journey")
                    .font(.system(size: 11, weight: .light, design: .monospaced))
            }
            .foregroundColor(.white.opacity(0.25))
            .tracking(0.5)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 16)
    }

    // MARK: - Dismiss gesture

    private var swipeDismiss: some Gesture {
        DragGesture()
            .onChanged { v in
                if v.translation.height > 0 {
                    dismissOffset = v.translation.height
                }
            }
            .onEnded { v in
                if v.translation.height > 90 {
                    onDismiss()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        dismissOffset = 0
                    }
                }
            }
    }

    // MARK: - Layout helpers

    private let nodeSpacing: CGFloat = 38

    private func nodeCenter(day: Int, width: CGFloat) -> CGPoint {
        let t = CGFloat(day - 1)
        let usableWidth = max(width, 1)
        let x = usableWidth / 2 + sin(t * 0.42) * (usableWidth * 0.22)
        let y = t * nodeSpacing + 20
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Day Node

private struct DayNodeView: View {
    let day: Int
    let isCompleted: Bool
    let isCurrent: Bool
    let color: Color

    @State private var pulse = false

    var body: some View {
        ZStack {
            if isCurrent {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 22, height: 22)
                    .scaleEffect(pulse ? 1.5 : 1.0)
                    .opacity(pulse ? 0 : 0.7)
            }

            Circle()
                .fill(nodeColor)
                .frame(width: nodeSize, height: nodeSize)
                .shadow(color: (isCompleted || isCurrent) ? color.opacity(0.5) : .clear, radius: 4)
        }
        .onAppear {
            guard isCurrent else { return }
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }

    private var nodeSize: CGFloat { isCurrent ? 10 : (isCompleted ? 7 : 5) }
    private var nodeColor: Color  { isCompleted || isCurrent ? color : .white.opacity(0.12) }
}

// MARK: - Preview

#Preview {
    let store = JourneyStore()
    return TimelineThreadView(
        journey: store.journeys.first ?? Journey(name: "English", totalDays: 90),
        namespace: Namespace().wrappedValue,
        store: store,
        onDismiss: {}
    )
}
