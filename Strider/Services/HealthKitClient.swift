import Foundation
import HealthKit

/// Protocol for HealthKit operations, enabling dependency injection and testing.
protocol HealthKitClient: Sendable {
    /// Requests authorization to read workout data.
    func requestAuthorization() async throws

    /// Fetches workouts within the given date range for the specified types.
    func fetchWorkouts(from startDate: Date, to endDate: Date, types: Set<WorkoutType>) async throws -> [Workout]

    /// Fetches all years that have workout data for the specified types.
    func fetchAvailableYears(types: Set<WorkoutType>) async throws -> [Int]
}

/// Errors that can occur during HealthKit operations.
enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied
    case queryFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device."
        case .authorizationDenied:
            return "Please allow Strider to access your workout data in Settings."
        case .queryFailed(let error):
            return "Failed to fetch workouts: \(error.localizedDescription)"
        }
    }
}

/// Live implementation of HealthKitClient using HKHealthStore.
final class LiveHealthKitClient: HealthKitClient, @unchecked Sendable {
    private let healthStore: HKHealthStore

    init() {
        self.healthStore = HKHealthStore()
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let workoutType = HKObjectType.workoutType()
        let typesToRead: Set<HKObjectType> = [workoutType]

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }

    func fetchWorkouts(from startDate: Date, to endDate: Date, types: Set<WorkoutType>) async throws -> [Workout] {
        let workoutType = HKObjectType.workoutType()

        // Build predicate for date range
        let datePredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        // Build predicate for activity types
        let activityTypes = types.flatMap { $0.healthKitActivityTypes }
        let activityPredicates = activityTypes.map { activityType in
            HKQuery.predicateForWorkouts(with: activityType)
        }
        let activityPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: activityPredicates)

        // Combine predicates
        let combinedPredicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [datePredicate, activityPredicate]
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: combinedPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                let workouts = (samples as? [HKWorkout] ?? [])
                    .compactMap { Workout(healthKitWorkout: $0) }

                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
        }
    }

    func fetchAvailableYears(types: Set<WorkoutType>) async throws -> [Int] {
        let workoutType = HKObjectType.workoutType()

        // Build predicate for activity types only (no date filter)
        let activityTypes = types.flatMap { $0.healthKitActivityTypes }
        let activityPredicates = activityTypes.map { activityType in
            HKQuery.predicateForWorkouts(with: activityType)
        }
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: activityPredicates)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                let calendar = Calendar.current
                let years = (samples as? [HKWorkout] ?? [])
                    .compactMap { workout -> Int? in
                        // Only include workouts that have distance
                        guard workout.totalDistance != nil else { return nil }
                        return calendar.component(.year, from: workout.startDate)
                    }

                let uniqueYears = Array(Set(years)).sorted(by: >)  // Most recent first
                continuation.resume(returning: uniqueYears)
            }

            healthStore.execute(query)
        }
    }
}
