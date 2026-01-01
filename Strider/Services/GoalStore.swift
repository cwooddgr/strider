import Foundation

/// Protocol for goal settings persistence.
protocol GoalStore: Sendable {
    /// Loads the current goal settings.
    func load() -> GoalSettings

    /// Saves the goal settings.
    func save(_ settings: GoalSettings)
}

/// UserDefaults-based implementation of GoalStore.
final class UserDefaultsGoalStore: GoalStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "com.strider.goalSettings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> GoalSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(GoalSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    func save(_ settings: GoalSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
        // Sync appearance mode for @AppStorage observation
        defaults.set(settings.appearanceMode.rawValue, forKey: "appearanceMode")
    }
}
