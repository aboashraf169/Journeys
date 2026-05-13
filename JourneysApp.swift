import SwiftUI

@main
struct JourneysApp: App {
    var body: some Scene {
        WindowGroup {
            StarfieldView()
                // Force dark mode at the highest level — applies to every sheet,
//                 confirmation dialog, and system UI the app presents.
                .preferredColorScheme(.dark)
        }
    }
}
