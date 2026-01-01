import SwiftUI

@main
struct StriderApp: App {
    private let healthKitClient: HealthKitClient = LiveHealthKitClient()
    private let goalStore: GoalStore = UserDefaultsGoalStore()

    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    private var colorScheme: ColorScheme? {
        switch AppearanceMode(rawValue: appearanceMode) ?? .system {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

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
            .preferredColorScheme(colorScheme)
        }
    }
}
