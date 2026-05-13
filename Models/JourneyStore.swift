import Foundation

@MainActor
final class JourneyStore: ObservableObject {

    @Published var journeys: [Journey] = []

    private let persistenceKey = "journeys.v1"

    init() {
        load()
        if journeys.isEmpty { seed() }
    }

    // MARK: - Actions

    /// Advances a journey by one day. Only succeeds if all current tasks are completed.
    func completeDay(id: UUID) {
        guard let i = index(of: id),
              journeys[i].allTasksDone,
              !journeys[i].isFinished else { return }

        journeys[i].completedDays += 1

        if !journeys[i].isFinished {
            // Reset tasks for the next day (preserve titles, clear completion)
            journeys[i].currentTasks = journeys[i].currentTasks.map {
                DayTask(title: $0.title)
            }
        } else {
            journeys[i].currentTasks = []
        }

        persist()
    }

    func toggleTask(journeyID: UUID, taskID: UUID) {
        guard let ji = index(of: journeyID),
              let ti = journeys[ji].currentTasks.firstIndex(where: { $0.id == taskID })
        else { return }
        journeys[ji].currentTasks[ti].isCompleted.toggle()
        persist()
    }

    func add(_ journey: Journey) {
        journeys.append(journey)
        persist()
    }

    func remove(id: UUID) {
        journeys.removeAll { $0.id == id }
        persist()
    }

    /// Replaces the stored journey with the edited copy (preserves completedDays, tasks progress).
    func update(_ journey: Journey) {
        guard let i = index(of: journey.id) else { return }
        journeys[i] = journey
        persist()
    }

    /// Call frequently during drag — does not persist until dragDidEnd.
    func updateCanvasPosition(id: UUID, x: Double, y: Double) {
        guard let i = index(of: id) else { return }
        journeys[i].canvasX = x
        journeys[i].canvasY = y
    }

    func persistPositions() {
        persist()
    }

    // MARK: - Private

    private func index(of id: UUID) -> Int? {
        journeys.firstIndex { $0.id == id }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(journeys) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let decoded = try? JSONDecoder().decode([Journey].self, from: data)
        else { return }
        journeys = decoded
    }

    private func seed() {
        journeys = [
            Journey(
                name: "English",
                totalDays: 90,
                completedDays: 34,
                currentTasks: [
                    DayTask(title: "30 min listening"),
                    DayTask(title: "10 new words"),
                ],
                shape: .circle,
                hue: 0.58,
                canvasX: -115, canvasY: -90
            ),
            Journey(
                name: "Gym",
                totalDays: 120,
                completedDays: 61,
                currentTasks: [
                    DayTask(title: "Workout session"),
                    DayTask(title: "Track calories"),
                ],
                shape: .hexagon,
                hue: 0.07,
                canvasX: 125, canvasY: 55
            ),
            Journey(
                name: "Reading",
                totalDays: 60,
                completedDays: 12,
                currentTasks: [
                    DayTask(title: "Read 20 pages"),
                ],
                shape: .diamond,
                hue: 0.72,
                canvasX: -20, canvasY: 145
            ),
            Journey(
                name: "Meditation",
                totalDays: 30,
                completedDays: 22,
                currentTasks: [
                    DayTask(title: "10 min session"),
                    DayTask(title: "Journal entry"),
                ],
                shape: .circle,
                hue: 0.50,
                canvasX: 70, canvasY: -140
            ),
            Journey(
                name: "Coding",
                totalDays: 100,
                completedDays: 47,
                currentTasks: [
                    DayTask(title: "1 hour practice"),
                    DayTask(title: "Solve one problem"),
                ],
                shape: .triangle,
                hue: 0.35,
                canvasX: -165, canvasY: 55
            ),
            Journey(
                name: "Drawing",
                totalDays: 45,
                completedDays: 7,
                currentTasks: [
                    DayTask(title: "Sketch for 20 min"),
                ],
                shape: .diamond,
                hue: 0.92,
                canvasX: 160, canvasY: -60
            ),
            Journey(
                name: "Running",
                totalDays: 60,
                completedDays: 29,
                currentTasks: [
                    DayTask(title: "3 km run"),
                    DayTask(title: "Stretch 10 min"),
                ],
                shape: .hexagon,
                hue: 0.14,
                canvasX: -60, canvasY: -180
            ),
            Journey(
                name: "Sleep",
                totalDays: 21,
                completedDays: 18,
                currentTasks: [
                    DayTask(title: "In bed by 10:30 pm"),
                ],
                shape: .circle,
                hue: 0.64,
                canvasX: 55, canvasY: 185
            ),
            Journey(
                name: "Guitar",
                totalDays: 180,
                completedDays: 5,
                currentTasks: [
                    DayTask(title: "Practice chords 15 min"),
                    DayTask(title: "Learn one new riff"),
                ],
                shape: .triangle,
                hue: 0.82,
                canvasX: -220, canvasY: -30
            ),
        ]
        persist()
    }
}
