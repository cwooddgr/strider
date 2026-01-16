import Foundation

/// View state for the dashboard.
enum DashboardState: Equatable {
    case loading
    case loaded(DistanceSummary)
    case error(String)
}

/// ViewModel for the main dashboard, managing workout data fetching and aggregation.
@MainActor
@Observable
final class DashboardViewModel {
    private(set) var state: DashboardState = .loading
    private(set) var availableYears: [Int] = []
    var selectedYear: Int {
        didSet {
            if oldValue != selectedYear {
                Task { await loadWorkouts() }
            }
        }
    }

    private let healthKitClient: HealthKitClient
    private let aggregator: DistanceAggregator
    private let goalStore: GoalStore

    /// Returns true if the selected year is the current year (showing YTD data).
    var isCurrentYear: Bool {
        selectedYear == Calendar.current.component(.year, from: Date())
    }

    /// The current distance unit from settings.
    private(set) var distanceUnit: DistanceUnit

    init(
        healthKitClient: HealthKitClient,
        aggregator: DistanceAggregator = DistanceAggregator(),
        goalStore: GoalStore = iCloudGoalStore.shared
    ) {
        self.healthKitClient = healthKitClient
        self.aggregator = aggregator
        self.goalStore = goalStore
        self.selectedYear = Calendar.current.component(.year, from: Date())
        self.distanceUnit = goalStore.load().distanceUnit
        observeExternalChanges()
    }

    // MARK: - Settings Changes

    private func observeExternalChanges() {
        // Listen for both local and external (iCloud) settings changes
        for name in [Notification.Name.goalSettingsDidChange, .goalSettingsDidChangeExternally] {
            NotificationCenter.default.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self,
                      let newSettings = notification.userInfo?["settings"] as? GoalSettings else {
                    return
                }
                self.distanceUnit = newSettings.distanceUnit
            }
        }
    }

    /// Loads available years and workout data from HealthKit.
    func load() async {
        state = .loading

        do {
            try await healthKitClient.requestAuthorization()

            let allTypes = Set(WorkoutType.allCases)
            let years = try await healthKitClient.fetchAvailableYears(types: allTypes)

            // Ensure current year is always available, even if no workouts yet
            let currentYear = Calendar.current.component(.year, from: Date())
            if !years.contains(currentYear) {
                availableYears = [currentYear] + years
            } else {
                availableYears = years
            }

            // If selected year isn't in available years, reset to current year
            if !availableYears.contains(selectedYear) {
                selectedYear = currentYear
            }

            await loadWorkouts()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// Loads workout data for the selected year.
    private func loadWorkouts() async {
        state = .loading

        do {
            let (start, end) = aggregator.dateRange(for: selectedYear)
            let allTypes = Set(WorkoutType.allCases)

            let workouts = try await healthKitClient.fetchWorkouts(from: start, to: end, types: allTypes)
            let summary = aggregator.summarize(workouts)

            state = .loaded(summary)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
