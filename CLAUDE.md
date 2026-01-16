# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Strider** is an iOS app that tracks walking, hiking, and running distances from Apple HealthKit, showing YTD totals and progress toward weekly/monthly/yearly goals. Privacy-first, on-device only for MVP.

## Build & Test Commands

```bash
# Generate Xcode project (after modifying project.yml)
xcodegen generate

# Build the project
xcodebuild -scheme Strider -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run all tests
xcodebuild -scheme Strider -destination 'platform=iOS Simulator,name=iPhone 17' test

# Run a single test class
xcodebuild -scheme Strider -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:StriderTests/DistanceAggregatorTests test

# Run a single test method
xcodebuild -scheme Strider -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:StriderTests/DistanceAggregatorTests/testMetersToMilesConversion test
```

## Architecture

MVVM with a service layer. Key modules:

- **HealthKitClient** - Protocol-based wrapper for HealthKit authorization and workout queries. Mock implementation for tests.
- **DistanceAggregator** - Converts distances to meters, groups by workout type (walk/hike/run), produces YTD/rolling/calendar summaries.
- **GoalStore** - Persists goal settings via SwiftData or UserDefaults.
- **UI** - SwiftUI views. Business logic lives in ViewModels, not views.

## Data Model

### Workout Types Tracked
- Walking (Indoor/Outdoor)
- Hiking
- Running (Indoor/Outdoor)
- Track & Field (optional, maps to Run)

### Goal Settings Schema
- `weeklyGoalMeters`, `monthlyGoalMeters`, `yearlyGoalMeters`: Double?
- `windowMode`: calendar | rolling
- `weekStart`: sunday | monday

### Goals View
- Shows progress bars and daily average needed to reach each goal
- `daysRemaining` calculation includes today if no activity yet (encourages exercise)
- `hasActivityToday` in ViewModel checks if any workout started today
- Rolling mode uses fixed windows (7/30 days); calendar mode calculates actual days remaining

### Units
- Store/compute in **meters**
- Display in miles (US) or km based on locale

## Key Implementation Rules

### HealthKit
- Read-only access, request minimal permissions
- Use `HKWorkout.totalDistance` when available
- Filter by workout activity type and date range
- Deduplicate by workout UUID

### Date Handling
- Bucket workouts by **local calendar day** (user's current time zone)
- Assign overnight workouts to **start date**
- YTD = Jan 1 local time to now
- Calendar week start is configurable (Sunday/Monday)

### Testing
- Never depend on real HealthKit in unit tests
- Use protocol abstractions with mock implementations
- Test: meters↔miles conversion, workout type filtering, rolling/calendar window boundaries
