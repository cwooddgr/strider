import SwiftUI

struct SettingsView: View {
    @State private var settings: GoalSettings
    private let goalStore: GoalStore

    init(goalStore: GoalStore = iCloudGoalStore.shared) {
        self.goalStore = goalStore
        _settings = State(wrappedValue: goalStore.load())
    }

    var body: some View {
        List {
            Section {
                Picker("Units", selection: $settings.distanceUnit) {
                    ForEach(DistanceUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .onChange(of: settings.distanceUnit) {
                    saveSettings()
                }

                Picker("Appearance", selection: $settings.appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .onChange(of: settings.appearanceMode) {
                    saveSettings()
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .onReceive(NotificationCenter.default.publisher(for: .goalSettingsDidChangeExternally)) { notification in
            if let newSettings = notification.userInfo?["settings"] as? GoalSettings {
                settings = newSettings
            }
        }
    }

    private func saveSettings() {
        goalStore.save(settings)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
