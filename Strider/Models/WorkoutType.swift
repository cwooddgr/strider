import HealthKit

/// Represents the on-foot workout types tracked by Strider.
enum WorkoutType: String, CaseIterable, Hashable {
    case walk
    case hike
    case run

    /// The HKWorkoutActivityTypes that map to this workout type.
    var healthKitActivityTypes: [HKWorkoutActivityType] {
        switch self {
        case .walk:
            return [.walking]
        case .hike:
            return [.hiking]
        case .run:
            return [.running]
        }
    }

    /// Creates a WorkoutType from an HKWorkoutActivityType, if applicable.
    /// Returns nil for activity types not tracked by Strider.
    init?(healthKitType: HKWorkoutActivityType) {
        switch healthKitType {
        case .walking:
            self = .walk
        case .hiking:
            self = .hike
        case .running:
            self = .run
        default:
            return nil
        }
    }

    var displayName: String {
        switch self {
        case .walk: return "Walk"
        case .hike: return "Hike"
        case .run: return "Run"
        }
    }
}
