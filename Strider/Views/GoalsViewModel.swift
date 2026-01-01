import Foundation

/// Progress toward a single goal.
struct GoalProgress: Equatable {
    let currentMeters: Double
    let goalMeters: Double

    var progress: Double { goalMeters > 0 ? min(currentMeters / goalMeters, 1.0) : 0 }
    var isComplete: Bool { currentMeters >= goalMeters }

    /// Current distance in the specified unit.
    func current(in unit: DistanceUnit) -> Double {
        unit.fromMeters(currentMeters)
    }

    /// Goal distance in the specified unit.
    func goal(in unit: DistanceUnit) -> Double {
        unit.fromMeters(goalMeters)
    }

    /// Remaining distance in the specified unit.
    func remaining(in unit: DistanceUnit) -> Double {
        max(goal(in: unit) - current(in: unit), 0)
    }

    /// Display current rounded to 1 decimal place.
    func displayCurrent(in unit: DistanceUnit) -> Double {
        (current(in: unit) * 10).rounded() / 10
    }

    /// Display goal rounded to 1 decimal place.
    func displayGoal(in unit: DistanceUnit) -> Double {
        (goal(in: unit) * 10).rounded() / 10
    }

    /// Display remaining that adds up correctly with displayCurrent.
    func displayRemaining(in unit: DistanceUnit) -> Double {
        max(displayGoal(in: unit) - displayCurrent(in: unit), 0)
    }
}

/// View state for goals screen.
enum GoalsState: Equatable {
    case loading
    case loaded(weekly: GoalProgress?, monthly: GoalProgress?, yearly: GoalProgress?)
    case error(String)
}

/// ViewModel for the goals screen.
@MainActor
@Observable
final class GoalsViewModel {
    private(set) var state: GoalsState = .loading
    var settings: GoalSettings

    private let healthKitClient: HealthKitClient
    private let goalStore: GoalStore
    private let aggregator: DistanceAggregator

    init(
        healthKitClient: HealthKitClient,
        goalStore: GoalStore = UserDefaultsGoalStore(),
        aggregator: DistanceAggregator = DistanceAggregator()
    ) {
        self.healthKitClient = healthKitClient
        self.goalStore = goalStore
        self.aggregator = aggregator
        self.settings = goalStore.load()
    }

    /// Saves current settings and reloads progress.
    func saveSettings() {
        goalStore.save(settings)
        Task { await loadProgress() }
    }

    /// Loads goal progress from HealthKit.
    func loadProgress() async {
        state = .loading

        do {
            try await healthKitClient.requestAuthorization()

            let allTypes = Set(WorkoutType.allCases)
            let now = Date()

            // Fetch workouts for each time period
            let weeklyProgress = try await fetchProgress(
                for: settings.weeklyGoalMeters,
                dateRange: weekDateRange(from: now),
                types: allTypes
            )

            let monthlyProgress = try await fetchProgress(
                for: settings.monthlyGoalMeters,
                dateRange: monthDateRange(from: now),
                types: allTypes
            )

            let yearlyProgress = try await fetchProgress(
                for: settings.yearlyGoalMeters,
                dateRange: aggregator.ytdDateRange(from: now),
                types: allTypes
            )

            state = .loaded(weekly: weeklyProgress, monthly: monthlyProgress, yearly: yearlyProgress)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func fetchProgress(
        for goalMeters: Double?,
        dateRange: (start: Date, end: Date),
        types: Set<WorkoutType>
    ) async throws -> GoalProgress? {
        guard let goal = goalMeters else { return nil }

        let workouts = try await healthKitClient.fetchWorkouts(
            from: dateRange.start,
            to: dateRange.end,
            types: types
        )
        let summary = aggregator.summarize(workouts)

        return GoalProgress(currentMeters: summary.totalMeters, goalMeters: goal)
    }

    private func weekDateRange(from now: Date) -> (start: Date, end: Date) {
        if settings.windowMode == .rolling {
            return rollingDateRange(days: 7, from: now)
        } else {
            var calendar = Calendar.current
            calendar.firstWeekday = settings.weekStart.calendarWeekday
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return (start: start, end: now)
        }
    }

    private func monthDateRange(from now: Date) -> (start: Date, end: Date) {
        if settings.windowMode == .rolling {
            return rollingDateRange(days: 30, from: now)
        } else {
            return aggregator.currentMonthDateRange(from: now)
        }
    }

    private func rollingDateRange(days: Int, from now: Date) -> (start: Date, end: Date) {
        let start = Calendar.current.date(byAdding: .day, value: -days, to: now)!
        return (start: start, end: now)
    }
}
