import Foundation
@testable import Strider

/// A mock HealthKitClient for unit testing.
final class MockHealthKitClient: HealthKitClient, @unchecked Sendable {
    var authorizationError: Error?
    var workoutsToReturn: [Workout] = []
    var yearsToReturn: [Int] = [2025]
    var fetchError: Error?

    private(set) var requestAuthorizationCalled = false
    private(set) var fetchWorkoutsCalled = false
    private(set) var fetchAvailableYearsCalled = false
    private(set) var lastFetchStartDate: Date?
    private(set) var lastFetchEndDate: Date?
    private(set) var lastFetchTypes: Set<WorkoutType>?

    func requestAuthorization() async throws {
        requestAuthorizationCalled = true
        if let error = authorizationError {
            throw error
        }
    }

    func fetchWorkouts(from startDate: Date, to endDate: Date, types: Set<WorkoutType>) async throws -> [Workout] {
        fetchWorkoutsCalled = true
        lastFetchStartDate = startDate
        lastFetchEndDate = endDate
        lastFetchTypes = types

        if let error = fetchError {
            throw error
        }

        return workoutsToReturn
    }

    func fetchAvailableYears(types: Set<WorkoutType>) async throws -> [Int] {
        fetchAvailableYearsCalled = true

        if let error = fetchError {
            throw error
        }

        return yearsToReturn
    }
}
