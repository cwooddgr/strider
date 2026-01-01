import XCTest
@testable import Strider

final class DistanceAggregatorTests: XCTestCase {
    var aggregator: DistanceAggregator!

    override func setUp() {
        super.setUp()
        aggregator = DistanceAggregator()
    }

    // MARK: - Summarize Tests

    func testSummarizeEmptyWorkouts() {
        let summary = aggregator.summarize([])

        XCTAssertEqual(summary.totalMeters, 0)
        XCTAssertEqual(summary.meters(for: .walk), 0)
        XCTAssertEqual(summary.meters(for: .hike), 0)
        XCTAssertEqual(summary.meters(for: .run), 0)
    }

    func testSummarizeSingleWorkout() {
        let workouts = [
            Workout(type: .walk, distanceMeters: 1609.344, startDate: Date())
        ]

        let summary = aggregator.summarize(workouts)

        XCTAssertEqual(summary.meters(for: .walk), 1609.344)
        XCTAssertEqual(summary.miles(for: .walk), 1.0, accuracy: 0.0001)
    }

    func testSummarizeMultipleWorkoutsSameType() {
        let workouts = [
            Workout(type: .run, distanceMeters: 1609.344, startDate: Date()),
            Workout(type: .run, distanceMeters: 1609.344, startDate: Date()),
            Workout(type: .run, distanceMeters: 1609.344, startDate: Date())
        ]

        let summary = aggregator.summarize(workouts)

        XCTAssertEqual(summary.miles(for: .run), 3.0, accuracy: 0.0001)
    }

    func testSummarizeMultipleWorkoutsDifferentTypes() {
        let workouts = [
            Workout(type: .walk, distanceMeters: 1609.344, startDate: Date()),
            Workout(type: .hike, distanceMeters: 3218.688, startDate: Date()),
            Workout(type: .run, distanceMeters: 4828.032, startDate: Date())
        ]

        let summary = aggregator.summarize(workouts)

        XCTAssertEqual(summary.miles(for: .walk), 1.0, accuracy: 0.0001)
        XCTAssertEqual(summary.miles(for: .hike), 2.0, accuracy: 0.0001)
        XCTAssertEqual(summary.miles(for: .run), 3.0, accuracy: 0.0001)
        XCTAssertEqual(summary.totalMiles, 6.0, accuracy: 0.0001)
    }

    // MARK: - Conversion Tests

    func testMetersToMilesConversion() {
        // 1 mile = 1609.344 meters
        let workouts = [
            Workout(type: .walk, distanceMeters: 1609.344, startDate: Date())
        ]

        let summary = aggregator.summarize(workouts)

        XCTAssertEqual(summary.miles(for: .walk), 1.0, accuracy: 0.0001)
    }

    func testMilesToMetersConversion() {
        // 5 miles = 8046.72 meters
        let workouts = [
            Workout(type: .run, distanceMeters: 8046.72, startDate: Date())
        ]

        let summary = aggregator.summarize(workouts)

        XCTAssertEqual(summary.miles(for: .run), 5.0, accuracy: 0.0001)
    }

    // MARK: - Date Range Tests

    func testYTDDateRange() {
        // Create a fixed date: July 15, 2024
        var components = DateComponents()
        components.year = 2024
        components.month = 7
        components.day = 15
        components.hour = 12
        let testDate = Calendar.current.date(from: components)!

        let (start, end) = aggregator.ytdDateRange(from: testDate)

        let startComponents = Calendar.current.dateComponents([.year, .month, .day], from: start)
        XCTAssertEqual(startComponents.year, 2024)
        XCTAssertEqual(startComponents.month, 1)
        XCTAssertEqual(startComponents.day, 1)

        XCTAssertEqual(end, testDate)
    }

    func testCurrentMonthDateRange() {
        // Create a fixed date: July 15, 2024
        var components = DateComponents()
        components.year = 2024
        components.month = 7
        components.day = 15
        components.hour = 12
        let testDate = Calendar.current.date(from: components)!

        let (start, end) = aggregator.currentMonthDateRange(from: testDate)

        let startComponents = Calendar.current.dateComponents([.year, .month, .day], from: start)
        XCTAssertEqual(startComponents.year, 2024)
        XCTAssertEqual(startComponents.month, 7)
        XCTAssertEqual(startComponents.day, 1)

        XCTAssertEqual(end, testDate)
    }
}
