import Foundation

enum OrbShape: String, Codable, CaseIterable {
    case circle, hexagon, triangle, diamond
}

struct DayTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

struct Journey: Identifiable, Codable {
    let id: UUID
    var name: String
    var totalDays: Int
    var completedDays: Int
    var currentTasks: [DayTask]
    var shape: OrbShape
    var hue: Double       // 0.0 – 1.0
    var canvasX: Double   // position in infinite canvas, relative to center
    var canvasY: Double

    // MARK: - Derived state (no redundant flags)

    var progress: Double {
        guard totalDays > 0 else { return 0 }
        return min(Double(completedDays) / Double(totalDays), 1.0)
    }

    var allTasksDone: Bool {
        !currentTasks.isEmpty && currentTasks.allSatisfy(\.isCompleted)
    }

    /// Frozen: tasks for today are not yet completed. The journey is alive but waiting.
    var isFrozen: Bool {
        !allTasksDone && !isFinished
    }

    var isFinished: Bool {
        completedDays >= totalDays
    }

    var currentDayNumber: Int {
        min(completedDays + 1, totalDays)
    }

    init(
        id: UUID = UUID(),
        name: String,
        totalDays: Int,
        completedDays: Int = 0,
        currentTasks: [DayTask]? = nil,
        shape: OrbShape = .circle,
        hue: Double = Double.random(in: 0...1),
        canvasX: Double = Double.random(in: -220...220),
        canvasY: Double = Double.random(in: -160...160)
    ) {
        self.id = id
        self.name = name
        self.totalDays = totalDays
        self.completedDays = completedDays
        self.currentTasks = currentTasks ?? [DayTask(title: name)]
        self.shape = shape
        self.hue = hue
        self.canvasX = canvasX
        self.canvasY = canvasY
    }
}
