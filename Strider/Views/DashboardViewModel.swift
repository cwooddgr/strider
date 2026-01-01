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

    private let healthKitClient: HealthKitClient
    private let aggregator: DistanceAggregator

    init(healthKitClient: HealthKitClient, aggregator: DistanceAggregator = DistanceAggregator()) {
        self.healthKitClient = healthKitClient
        self.aggregator = aggregator
    }

    /// Loads YTD workout data from HealthKit.
    func load() async {
        state = .loading

        do {
            try await healthKitClient.requestAuthorization()

            let (start, end) = aggregator.ytdDateRange()
            let allTypes = Set(WorkoutType.allCases)

            let workouts = try await healthKitClient.fetchWorkouts(from: start, to: end, types: allTypes)
            let summary = aggregator.summarize(workouts)

            state = .loaded(summary)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
