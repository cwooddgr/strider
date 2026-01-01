# Strider

![Strider](strider.png)

A privacy-first iOS app that tracks your walking, hiking, and running distances from Apple HealthKit.

## Features

- **YTD Distance Totals** - See your year-to-date miles for walking, hiking, and running
- **HealthKit Integration** - Reads workout data directly from Apple Health
- **Privacy-First** - All data stays on your device
- **Clean Interface** - Simple dashboard focused on the metrics that matter

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

- **Models** - `WorkoutType`, `Workout`, `DistanceSummary`
- **Services** - `HealthKitClient` (protocol + live implementation), `DistanceAggregator`
- **Views** - SwiftUI views with `@Observable` ViewModels

All HealthKit access is abstracted behind protocols for testability.

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
