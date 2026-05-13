import UIKit

/// Thin wrapper around UIKit feedback generators.
/// Call from any SwiftUI action — no setup required.
enum HapticFeedback {

    /// Soft nudge — task checkbox toggle, focus tap
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Medium click — day completion, orb advance
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Positive signal — journey finished
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Warning signal — tried to advance when tasks incomplete
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
