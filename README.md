# Worn Soles

*Codename: Strider*

![Strider](strider.png)

A privacy-first iOS app that tracks your walking, hiking, and running distances from Apple HealthKit.

## Features

### Summary
- Year-to-date distance totals for walking, hiking, and running
- Year selector to view historical data
- Combined total across all workout types

### Goals
- Set weekly, monthly, and yearly distance goals
- Track progress with visual progress bars
- Choose between calendar-aligned or rolling window modes
- Configurable week start day (Sunday/Monday)

### Details
- Recent workouts from the last 30 days
- Grouped by date with time and distance
- Pull-to-refresh for latest data

### Settings
- Switch between miles and kilometers
- Light, dark, or system appearance mode

### Privacy
- All data stays on your device
- Read-only HealthKit access
- No accounts, no cloud sync

## Requirements

- iOS 17.0+
- Xcode 15.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project generation

## Setup

1. Install XcodeGen:
   ```bash
   brew install xcodegen
   ```

2. Clone the repository:
   ```bash
   git clone https://github.com/cwooddgr/strider.git
   cd strider
   ```

3. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

4. Open in Xcode:
   ```bash
   open Strider.xcodeproj
   ```

5. Run on a physical device (HealthKit is not available in the Simulator)

## Build & Test

```bash
# Build
xcodebuild -scheme Strider -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run tests
xcodebuild -scheme Strider -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Architecture

The app follows MVVM with a service layer:

- **Models** - `WorkoutType`, `Workout`, `DistanceSummary`, `GoalSettings`
- **Services** - `HealthKitClient`, `DistanceAggregator`, `GoalStore`
- **Views** - SwiftUI views with `@Observable` ViewModels

All HealthKit access is abstracted behind protocols for testability. Settings are persisted via UserDefaults.

## License

MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
