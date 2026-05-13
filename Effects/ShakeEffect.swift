import SwiftUI

/// Applies a horizontal sine-wave displacement. Drive `animatableData` from 0 → 1
/// with a repeating linear animation to produce a continuous shake.
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 5
    var frequency: CGFloat = 3     // oscillations per unit
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let dx = amount * sin(animatableData * .pi * frequency)
        return ProjectionTransform(CGAffineTransform(translationX: dx, y: 0))
    }
}
