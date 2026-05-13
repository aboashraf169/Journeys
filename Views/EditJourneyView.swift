import SwiftUI

struct EditJourneyView: View {
    @ObservedObject var store: JourneyStore
    let journey: Journey
    @Environment(\.dismiss) private var dismiss

    @State private var name:          String
    @State private var totalDays:     Int
    @State private var selectedShape: OrbShape
    @State private var hue:           Double
    @State private var taskTitles:    [String]

    init(store: JourneyStore, journey: Journey) {
        self.store   = store
        self.journey = journey
        _name          = State(initialValue: journey.name)
        _totalDays     = State(initialValue: journey.totalDays)
        _selectedShape = State(initialValue: journey.shape)
        _hue           = State(initialValue: journey.hue)
        _taskTitles    = State(initialValue:
            journey.currentTasks.isEmpty ? [""] : journey.currentTasks.map(\.title)
        )
    }

    private var accentColor: Color {
        Color(hue: hue, saturation: 0.75, brightness: 1.0)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 34) {
                    nameField
                    daysField
                    shapeField
                    colorField
                    tasksField
                    saveButton
                }
                .padding(.horizontal, 28)
                .padding(.top, 50)
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Fields

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("name")
            TextField("journey name", text: $name)
                .font(.system(size: 22, weight: .ultraLight))
                .foregroundColor(.white)
                .tint(accentColor)
        }
    }

    private var daysField: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("duration")
            HStack(spacing: 24) {
                stepButton("−") {
                    HapticFeedback.light()
                    // Cannot shrink below days already completed
                    totalDays = max(max(7, journey.completedDays + 1), totalDays - 1)
                }

                Text("\(totalDays) days")
                    .font(.system(size: 18, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.90))
                    .frame(minWidth: 88, alignment: .center)
                    .contentTransition(.numericText())

                stepButton("+") {
                    HapticFeedback.light()
                    totalDays = min(365, totalDays + 1)
                }
            }

            if journey.completedDays > 0 {
                Text("\(journey.completedDays) days already completed — minimum locked")
                    .font(.system(size: 10, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
    }

    private var shapeField: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("form")
            HStack(spacing: 20) {
                ForEach(OrbShape.allCases, id: \.self) { shape in
                    shapeOption(shape)
                }
            }
        }
    }

    private var colorField: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("light")
            Slider(value: $hue, in: 0...1)
                .tint(accentColor)
        }
    }

    private var tasksField: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionLabel("daily tasks")
                Spacer()
                Button {
                    HapticFeedback.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        taskTitles.append("")
                    }
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(accentColor.opacity(0.95))
                }
                .buttonStyle(.plain)
            }

            ForEach(taskTitles.indices, id: \.self) { i in
                HStack(spacing: 12) {
                    Circle()
                        .strokeBorder(accentColor.opacity(0.75), lineWidth: 1.5)
                        .frame(width: 16, height: 16)

                    TextField("task \(i + 1)", text: $taskTitles[i])
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(.white.opacity(0.90))
                        .tint(accentColor)

                    if taskTitles.count > 1 {
                        Button {
                            HapticFeedback.light()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                taskTitles.remove(at: i)
                            }
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 15, weight: .light))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            HStack {
                Spacer()
                Text("save")
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(name.isEmpty ? .white.opacity(0.35) : .white)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(name.isEmpty ? Color.white.opacity(0.06) : accentColor.opacity(0.55))
            )
        }
        .buttonStyle(.plain)
        .disabled(name.isEmpty)
        .padding(.top, 8)
    }

    // MARK: - Component builders

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundColor(.white.opacity(0.70))
            .tracking(2)
    }

    private func stepButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 22, weight: .light))
                .foregroundColor(.white.opacity(0.85))
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.12))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func shapeOption(_ shape: OrbShape) -> some View {
        let selected = selectedShape == shape
        return OrbGeometry(shape: shape)
            .fill(selected ? accentColor.opacity(0.85) : Color.white.opacity(0.30))
            .frame(width: 42, height: 42)
            .shadow(color: selected ? accentColor.opacity(0.65) : .clear, radius: 10)
            .onTapGesture {
                HapticFeedback.light()
                withAnimation(.easeInOut(duration: 0.15)) { selectedShape = shape }
            }
    }

    // MARK: - Save

    private func save() {
        guard !name.isEmpty else { return }
        HapticFeedback.medium()

        let newTasks = taskTitles
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { DayTask(title: $0) }

        var edited = journey
        edited.name      = name
        edited.totalDays = totalDays
        edited.shape     = selectedShape
        edited.hue       = hue
        // Only replace task list if it genuinely changed — keeps current completion state
        // if the user just reordered or renamed tasks we reset (acceptable tradeoff)
        if newTasks.map(\.title) != journey.currentTasks.map(\.title) {
            edited.currentTasks = newTasks.isEmpty ? [DayTask(title: name)] : newTasks
        }

        store.update(edited)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    EditJourneyView(
        store: JourneyStore(),
        journey: Journey(name: "English", totalDays: 90, shape: .circle, hue: 0.58)
    )
}
