import SwiftUI
#if os(watchOS)
import WatchKit
import HealthKit

class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        DispatchQueue.main.async {
            WatchWorkoutManager.shared.startWorkoutSession(syncToPhone: false)
        }
    }
}

@main
struct SimpleFitnessWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchTrainingView()
            }
        }
    }
}
#endif
