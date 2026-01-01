import XCTest
import HealthKit
@testable import Strider

final class WorkoutTypeTests: XCTestCase {

    // MARK: - HKWorkoutActivityType Mapping

    func testWalkingMapsToWalk() {
        let type = WorkoutType(healthKitType: .walking)
        XCTAssertEqual(type, .walk)
    }

    func testHikingMapsToHike() {
        let type = WorkoutType(healthKitType: .hiking)
        XCTAssertEqual(type, .hike)
    }

    func testRunningMapsToRun() {
        let type = WorkoutType(healthKitType: .running)
        XCTAssertEqual(type, .run)
    }

    func testCyclingReturnsNil() {
        let type = WorkoutType(healthKitType: .cycling)
        XCTAssertNil(type)
    }

    func testSwimmingReturnsNil() {
        let type = WorkoutType(healthKitType: .swimming)
        XCTAssertNil(type)
    }

    // MARK: - Reverse Mapping

    func testWalkHealthKitActivityTypes() {
        let types = WorkoutType.walk.healthKitActivityTypes
        XCTAssertEqual(types, [.walking])
    }

    func testHikeHealthKitActivityTypes() {
        let types = WorkoutType.hike.healthKitActivityTypes
        XCTAssertEqual(types, [.hiking])
    }

    func testRunHealthKitActivityTypes() {
        let types = WorkoutType.run.healthKitActivityTypes
        XCTAssertEqual(types, [.running])
    }

    // MARK: - Display Names

    func testDisplayNames() {
        XCTAssertEqual(WorkoutType.walk.displayName, "Walk")
        XCTAssertEqual(WorkoutType.hike.displayName, "Hike")
        XCTAssertEqual(WorkoutType.run.displayName, "Run")
    }
}
