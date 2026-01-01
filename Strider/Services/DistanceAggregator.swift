import Foundation

/// Aggregates workout distances into summaries.
struct DistanceAggregator {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Groups workouts by type and sums their distances.
    func summarize(_ workouts: [Workout]) -> DistanceSummary {
        var metersByType: [WorkoutType: Double] = [:]

        for workout in workouts {
            metersByType[workout.type, default: 0] += workout.distanceMeters
        }

        return DistanceSummary(metersByType: metersByType)
    }

    /// Returns the date range for year-to-date (Jan 1 local time to now).
    func ytdDateRange(from now: Date = Date()) -> (start: Date, end: Date) {
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
        return (start: startOfYear, end: now)
    }

    /// Returns the date range for the current calendar week.
    func currentWeekDateRange(from now: Date = Date(), weekStartsOn: Weekday = .sunday) -> (start: Date, end: Date) {
        var cal = calendar
        cal.firstWeekday = weekStartsOn.rawValue

        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        return (start: startOfWeek, end: now)
    }

    /// Returns the date range for the current calendar month.
    func currentMonthDateRange(from now: Date = Date()) -> (start: Date, end: Date) {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        return (start: startOfMonth, end: now)
    }
}

/// Represents the first day of the week.
enum Weekday: Int {
    case sunday = 1
    case monday = 2
}
