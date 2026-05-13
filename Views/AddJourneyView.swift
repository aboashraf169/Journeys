import SwiftUI

struct AddJourneyView: View {
    @ObservedObject var store: JourneyStore
    @Environment(\.dismiss) private var dismiss

    @State private var name:          String   = ""
    @State private var totalDays:     Int      = 30
    @State private var selectedShape: OrbShape = .circle
    @State private var hue:           Double   = Double.random(in: 0...1)
    @State private var taskTitles:    [String] = [""]   // at least one task slot

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
                    createButton
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
            TextField("e.g. Learn English", text: $name)
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
                    totalDays = max(7, totalDays - 1)
                }

                Text("\(totalDays) days")
                    .font(.system(size: 18, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.90))      // كان 0.65
                    .frame(minWidth: 88, alignment: .center)
                    .contentTransition(.numericText())

                stepButton("+") {
                    HapticFeedback.light()
                    totalDays = min(365, totalDays + 1)
                }
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
                        .foregroundColor(accentColor.opacity(0.95))     // كان 0.6
                }
                .buttonStyle(.plain)
            }

            ForEach(taskTitles.indices, id: \.self) { i in
                HStack(spacing: 12) {
                    Circle()
                        .strokeBorder(accentColor.opacity(0.75), lineWidth: 1.5)   // كان 0.3
                        .frame(width: 16, height: 16)

                    TextField("task \(i + 1)", text: $taskTitles[i])
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(.white.opacity(0.90))      // كان 0.65
                        .tint(accentColor)

                    if taskTitles.count > 1 {
                        Button {
                            HapticFeedback.light()
                            _ = withAnimation(.easeInOut(duration: 0.2)) {
                                taskTitles.remove(at: i)
                            }
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 15, weight: .light))
                                .foregroundColor(.white.opacity(0.55))  // كان 0.2
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var createButton: some View {
        Button(action: create) {
            HStack {
                Spacer()
                Text("begin")
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(name.isEmpty ? .white.opacity(0.35) : .white)  // كان 0.18
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
            .foregroundColor(.white.opacity(0.70))          // كان 0.22 — الآن رمادي فاتح واضح
            .tracking(2)
    }

    private func stepButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 22, weight: .light))
                .foregroundColor(.white.opacity(0.85))      // كان 0.5
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.12))      // كان 0.05
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func shapeOption(_ shape: OrbShape) -> some View {
        let selected = selectedShape == shape
        return OrbGeometry(shape: shape)
            .fill(selected ? accentColor.opacity(0.85) : Color.white.opacity(0.30))   // كان 0.12
            .frame(width: 42, height: 42)
            .shadow(color: selected ? accentColor.opacity(0.65) : .clear, radius: 10)
            .onTapGesture {
                HapticFeedback.light()
                withAnimation(.easeInOut(duration: 0.15)) { selectedShape = shape }
            }
    }

    // MARK: - Create

    private func create() {
        guard !name.isEmpty else { return }
        HapticFeedback.medium()

        let tasks = taskTitles
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { DayTask(title: $0) }

        let journey = Journey(
            name: name,
            totalDays: totalDays,
            currentTasks: tasks.isEmpty ? [DayTask(title: name)] : tasks,
            shape: selectedShape,
            hue: hue
        )
        store.add(journey)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddJourneyView(store: JourneyStore())
}
