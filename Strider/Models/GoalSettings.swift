import Foundation

/// User's distance goal settings.
struct GoalSettings: Codable, Equatable {
    /// Weekly distance goal in meters, or nil if not set.
    var weeklyGoalMeters: Double?

    /// Monthly distance goal in meters, or nil if not set.
    var monthlyGoalMeters: Double?

    /// Yearly distance goal in meters, or nil if not set.
    var yearlyGoalMeters: Double?

    /// Whether to use calendar-aligned or rolling windows.
    var windowMode: WindowMode

    /// Which day the week starts on.
    var weekStart: WeekStart

    init(
        weeklyGoalMeters: Double? = nil,
        monthlyGoalMeters: Double? = nil,
        yearlyGoalMeters: Double? = nil,
        windowMode: WindowMode = .calendar,
        weekStart: WeekStart = .sunday
    ) {
        self.weeklyGoalMeters = weeklyGoalMeters
        self.monthlyGoalMeters = monthlyGoalMeters
        self.yearlyGoalMeters = yearlyGoalMeters
        self.windowMode = windowMode
        self.weekStart = weekStart
    }

    // MARK: - Convenience accessors in miles

    var weeklyGoalMiles: Double? {
        get { weeklyGoalMeters.map { $0 / 1609.344 } }
        set { weeklyGoalMeters = newValue.map { $0 * 1609.344 } }
    }

    var monthlyGoalMiles: Double? {
        get { monthlyGoalMeters.map { $0 / 1609.344 } }
        set { monthlyGoalMeters = newValue.map { $0 * 1609.344 } }
    }

    var yearlyGoalMiles: Double? {
        get { yearlyGoalMeters.map { $0 / 1609.344 } }
        set { yearlyGoalMeters = newValue.map { $0 * 1609.344 } }
    }

    /// Default settings with no goals set.
    static let `default` = GoalSettings()
}

/// Window mode for calculating goal progress.
enum WindowMode: String, Codable, CaseIterable {
    case calendar
    case rolling

    var displayName: String {
        switch self {
        case .calendar: return "Calendar"
        case .rolling: return "Rolling"
        }
    }

    var description: String {
        switch self {
        case .calendar: return "Week/month boundaries align with calendar"
        case .rolling: return "Last 7/30 days from today"
        }
    }
}

/// First day of the week setting.
enum WeekStart: String, Codable, CaseIterable {
    case sunday
    case monday

    var displayName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        }
    }

    var calendarWeekday: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        }
    }
}
