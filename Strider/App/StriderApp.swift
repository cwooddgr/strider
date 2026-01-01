import SwiftUI

@main
struct StriderApp: App {
    private let healthKitClient: HealthKitClient = LiveHealthKitClient()

    var body: some Scene {
        WindowGroup {
            DashboardView(healthKitClient: healthKitClient)
        }
    }
}
