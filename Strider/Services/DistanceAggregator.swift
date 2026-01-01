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

    /// Returns the date range for a specific year.
    /// If the year is the current year, returns YTD (Jan 1 to now).
    /// Otherwise returns the full year (Jan 1 to Dec 31).
    func dateRange(for year: Int, now: Date = Date()) -> (start: Date, end: Date) {
        let currentYear = calendar.component(.year, from: now)

        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = 1
        startComponents.day = 1
        let startOfYear = calendar.date(from: startComponents)!

        if year == currentYear {
            return (start: startOfYear, end: now)
        } else {
            var endComponents = DateComponents()
            endComponents.year = year
            endComponents.month = 12
            endComponents.day = 31
            endComponents.hour = 23
            endComponents.minute = 59
            endComponents.second = 59
            let endOfYear = calendar.date(from: endComponents)!
            return (start: startOfYear, end: endOfYear)
        }
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
