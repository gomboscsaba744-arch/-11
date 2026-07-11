import SwiftUI
#if os(watchOS)

@main
struct SimpleFitnessWatchApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchTrainingView()
            }
        }
    }
}
#endif
