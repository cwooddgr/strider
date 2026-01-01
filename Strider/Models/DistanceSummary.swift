import Foundation

/// Holds aggregated distance totals by workout type.
struct DistanceSummary: Equatable {
    /// Distance in meters per workout type.
    private(set) var metersByType: [WorkoutType: Double]

    /// Creates a summary with the given meters per type.
    init(metersByType: [WorkoutType: Double] = [:]) {
        self.metersByType = metersByType
    }

    /// Returns meters for a specific workout type.
    func meters(for type: WorkoutType) -> Double {
        metersByType[type] ?? 0
    }

    /// Returns miles for a specific workout type.
    func miles(for type: WorkoutType) -> Double {
        meters(for: type) / 1609.344
    }

    /// Total meters across all workout types.
    var totalMeters: Double {
        metersByType.values.reduce(0, +)
    }

    /// Total miles across all workout types.
    var totalMiles: Double {
        totalMeters / 1609.344
    }

    /// An empty summary with zero distance.
    static let empty = DistanceSummary()
}
