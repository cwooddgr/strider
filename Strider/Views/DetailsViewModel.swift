import Foundation

/// View state for the details screen.
enum DetailsState: Equatable {
    case loading
    case loaded([Workout])
    case error(String)
}

/// ViewModel for the details screen showing recent workouts.
@MainActor
@Observable
final class DetailsViewModel {
    private(set) var state: DetailsState = .loading
    private(set) var lastRefreshed: Date?

    private let healthKitClient: HealthKitClient
    private let calendar = Calendar.current

    init(healthKitClient: HealthKitClient) {
        self.healthKitClient = healthKitClient
    }

    /// Loads recent workouts from the last 30 days.
    func load() async {
        state = .loading

        do {
            try await healthKitClient.requestAuthorization()

            let now = Date()
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!

            let workouts = try await healthKitClient.fetchWorkouts(
                from: thirtyDaysAgo,
                to: now,
                types: Set(WorkoutType.allCases)
            )

            // Sort by date, most recent first
            let sorted = workouts.sorted { $0.startDate > $1.startDate }

            lastRefreshed = Date()
            state = .loaded(sorted)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// Groups workouts by day for display.
    func workoutsByDay(_ workouts: [Workout]) -> [(date: Date, workouts: [Workout])] {
        let grouped = Dictionary(grouping: workouts) { workout in
            calendar.startOfDay(for: workout.startDate)
        }

        return grouped.sorted { $0.key > $1.key }
            .map { (date: $0.key, workouts: $0.value.sorted { $0.startDate > $1.startDate }) }
    }

    /// Formats a date as a section header (Today, Yesterday, or date).
    func sectionHeader(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }

    /// Formats a workout time.
    func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Relative time string for last refresh.
    var lastRefreshedString: String? {
        guard let lastRefreshed else { return nil }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastRefreshed, relativeTo: Date())
    }
}
