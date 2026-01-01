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

    /// Distance unit for display.
    var distanceUnit: DistanceUnit

    init(
        weeklyGoalMeters: Double? = nil,
        monthlyGoalMeters: Double? = nil,
        yearlyGoalMeters: Double? = nil,
        windowMode: WindowMode = .calendar,
        weekStart: WeekStart = .sunday,
        distanceUnit: DistanceUnit = .miles
    ) {
        self.weeklyGoalMeters = weeklyGoalMeters
        self.monthlyGoalMeters = monthlyGoalMeters
        self.yearlyGoalMeters = yearlyGoalMeters
        self.windowMode = windowMode
        self.weekStart = weekStart
        self.distanceUnit = distanceUnit
    }

    // MARK: - Convenience accessors in miles (for compatibility)

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

    // MARK: - Unit-aware accessors

    var weeklyGoalInUnit: Double? {
        get { weeklyGoalMeters.map { distanceUnit.fromMeters($0) } }
        set { weeklyGoalMeters = newValue.map { distanceUnit.toMeters($0) } }
    }

    var monthlyGoalInUnit: Double? {
        get { monthlyGoalMeters.map { distanceUnit.fromMeters($0) } }
        set { monthlyGoalMeters = newValue.map { distanceUnit.toMeters($0) } }
    }

    var yearlyGoalInUnit: Double? {
        get { yearlyGoalMeters.map { distanceUnit.fromMeters($0) } }
        set { yearlyGoalMeters = newValue.map { distanceUnit.toMeters($0) } }
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

/// Distance unit for display.
enum DistanceUnit: String, Codable, CaseIterable {
    case miles
    case kilometers

    var displayName: String {
        switch self {
        case .miles: return "Miles"
        case .kilometers: return "Kilometers"
        }
    }

    var abbreviation: String {
        switch self {
        case .miles: return "mi"
        case .kilometers: return "km"
        }
    }

    /// Meters per unit.
    var metersPerUnit: Double {
        switch self {
        case .miles: return 1609.344
        case .kilometers: return 1000.0
        }
    }

    /// Converts meters to this unit.
    func fromMeters(_ meters: Double) -> Double {
        meters / metersPerUnit
    }

    /// Converts this unit to meters.
    func toMeters(_ value: Double) -> Double {
        value * metersPerUnit
    }
}
