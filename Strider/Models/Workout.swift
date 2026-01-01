import Foundation
import HealthKit

/// A simplified workout model containing only the data Strider needs.
struct Workout: Identifiable, Equatable {
    let id: UUID
    let type: WorkoutType
    let distanceMeters: Double
    let startDate: Date

    /// Distance in miles (1 mile = 1609.344 meters).
    var distanceMiles: Double {
        distanceMeters / 1609.344
    }

    /// Distance in the specified unit.
    func distance(in unit: DistanceUnit) -> Double {
        unit.fromMeters(distanceMeters)
    }

    /// Creates a Workout from an HKWorkout.
    /// Returns nil if the workout type isn't tracked or has no distance.
    init?(healthKitWorkout: HKWorkout) {
        guard let type = WorkoutType(healthKitType: healthKitWorkout.workoutActivityType) else {
            return nil
        }

        guard let distance = healthKitWorkout.totalDistance else {
            return nil
        }

        self.id = healthKitWorkout.uuid
        self.type = type
        self.distanceMeters = distance.doubleValue(for: .meter())
        self.startDate = healthKitWorkout.startDate
    }

    /// Direct initializer for testing and previews.
    init(id: UUID = UUID(), type: WorkoutType, distanceMeters: Double, startDate: Date) {
        self.id = id
        self.type = type
        self.distanceMeters = distanceMeters
        self.startDate = startDate
    }
}
