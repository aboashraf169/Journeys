import SwiftUI

private struct Star {
    let x: CGFloat       // normalized 0–1
    let y: CGFloat
    let radius: CGFloat
    let opacity: Double
}

/// Pre-generated once at module load — stable across renders.
private let stars: [Star] = (0..<220).map { _ in
    Star(
        x: .random(in: 0...1),
        y: .random(in: 0...1),
        radius: .random(in: 0.4...1.6),
        opacity: .random(in: 0.08...0.55)
    )
}

struct BackgroundStarsView: View {
    var body: some View {
        Canvas { ctx, size in
            for star in stars {
                let rect = CGRect(
                    x: star.x * size.width  - star.radius,
                    y: star.y * size.height - star.radius,
                    width:  star.radius * 2,
                    height: star.radius * 2
                )
                ctx.fill(
                    Circle().path(in: rect),
                    with: .color(.white.opacity(star.opacity))
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
