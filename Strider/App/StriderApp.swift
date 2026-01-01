import SwiftUI

@main
struct StriderApp: App {
    private let healthKitClient: HealthKitClient = LiveHealthKitClient()

    var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView(healthKitClient: healthKitClient)
                    .tabItem {
                        Label("Dashboard", systemImage: "figure.walk")
                    }

                NavigationStack {
                    GoalsView(healthKitClient: healthKitClient)
                }
                .tabItem {
                    Label("Goals", systemImage: "target")
                }

                NavigationStack {
                    DetailsView(healthKitClient: healthKitClient)
                }
                .tabItem {
                    Label("Details", systemImage: "list.bullet")
                }
            }
        }
    }
}
