# Journeys

> Track your daily habits like stars in your own universe.

---

## For Everyone

Imagine every goal you set turning into a glowing planet in a space that belongs only to you.

**Journeys** is a simple app that helps you build daily habits and stick with them. Whether you want to learn a language, work out, read every day, or sleep earlier — each goal becomes a "journey" that grows and glows brighter as you make progress.

### How it works

- **Add a journey** — choose a name, duration, shape, and colour for your orb
- **Log your day** — complete your daily tasks, then long-press the orb to advance to the next day
- **Watch your progress** — your orb grows larger and more radiant with every completed day
- **Your space, your rules** — drag orbs freely across an infinite canvas

### Why Journeys?

Because staying consistent is hard, and overcomplicated apps make it harder. Everything here is visual and calm — you see your progress at a glance, no cluttered lists or annoying notifications.

---

## For Developers

### Overview

A native iOS app built entirely with **SwiftUI**, using an infinite canvas to display the user's journeys as glowing orbs in a dark space aesthetic.

### Tech Stack

| Technology | Usage |
|---|---|
| SwiftUI | Entire UI layer |
| matchedGeometryEffect | Orb → detail view transition |
| UserDefaults + JSONEncoder | Local persistence |
| ObservableObject / @Published | State management |
| XcodeGen (project.yml) | Project file management |

### Project Structure

```
Journeys/
├── Models/
│   ├── Journey.swift              # Journey model + DayTask + OrbShape
│   └── JourneyStore.swift         # ObservableObject — CRUD + persistence
├── Views/
│   ├── StarfieldView.swift        # Main screen — infinite canvas
│   ├── ProgressOrbView.swift      # Orb rendering + gestures
│   ├── TimelineThreadView.swift   # Journey detail view
│   ├── AddJourneyView.swift       # Create new journey
│   ├── EditJourneyView.swift      # Edit existing journey
│   ├── AddOrbButton.swift         # Animated FAB
│   ├── BackgroundStarsView.swift
│   ├── GestureHintView.swift
│   └── JourneyPeekCard.swift
├── Effects/
│   ├── HapticFeedback.swift
│   └── ShakeEffect.swift
└── Assets.xcassets
```

### Journey Logic

Each `Journey` contains:
- `totalDays` / `completedDays` → derived `progress: Double`
- `currentTasks: [DayTask]` — reset each day with the same titles
- `isFrozen` → tasks not yet completed for today
- `allTasksDone` → ready to advance via long press

Advancing a day requires all tasks to be completed, then `currentTasks` is recreated with the same titles and `isCompleted = false`.

### Gesture Map

| Gesture | Action |
|---|---|
| Single tap | Open journey detail |
| Long press | Complete the day (only if all tasks done) |
| Drag on orb | Reposition orb on the canvas |
| Drag on background | Pan the entire canvas |

### Requirements

- Xcode 16+
- iOS 17+
- XcodeGen (optional — to regenerate `.xcodeproj`)

```bash
xcodegen generate --spec Journeys/Config/project.yml
```

---

## Screenshots

<table>
  <tr>
    <td align="center"><b>Canvas — Your Universe</b></td>
    <td align="center"><b>Canvas — More Journeys</b></td>
    <td align="center"><b>Canvas — Full View</b></td>
  </tr>
  <tr>
    <td><img src="Screenshot/Screenshot 2026-05-14 at 12.45.51 AM.png" width="220"/></td>
    <td><img src="Screenshot/Screenshot 2026-05-14 at 12.46.01 AM.png" width="220"/></td>
    <td><img src="Screenshot/Screenshot 2026-05-14 at 12.46.12 AM.png" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><b>Journey Detail & Tasks</b></td>
    <td align="center"><b>Add New Journey</b></td>
    <td></td>
  </tr>
  <tr>
    <td><img src="Screenshot/Screenshot 2026-05-14 at 12.45.40 AM.png" width="220"/></td>
    <td><img src="Screenshot/Screenshot 2026-05-14 at 12.45.31 AM.png" width="220"/></td>
    <td></td>
  </tr>
</table>

---

## License

MIT License — use the code however you like.
