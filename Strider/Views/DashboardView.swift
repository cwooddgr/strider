import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel

    init(healthKitClient: HealthKitClient) {
        _viewModel = State(wrappedValue: DashboardViewModel(healthKitClient: healthKitClient))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView("Loading workouts...")

                case .loaded(let summary):
                    let unit = viewModel.distanceUnit
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(WorkoutType.allCases, id: \.self) { type in
                                DistanceCard(
                                    title: type.displayName,
                                    distance: summary.distance(for: type, in: unit),
                                    unit: unit,
                                    iconName: type.iconName,
                                    isYTD: viewModel.isCurrentYear
                                )
                            }

                            Divider()
                                .padding(.vertical, 12)

                            DistanceCard(
                                title: "Total",
                                distance: summary.totalDistance(in: unit),
                                unit: unit,
                                iconName: "figure.walk.motion",
                                isTotal: true,
                                isYTD: viewModel.isCurrentYear
                            )
                        }
                        .padding(20)
                    }
                    .refreshable {
                        await viewModel.load()
                    }

                case .error(let message):
                    ContentUnavailableView {
                        Label("Unable to Load", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Try Again") {
                            Task {
                                await viewModel.load()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(viewModel.availableYears, id: \.self) { year in
                            Button {
                                viewModel.selectedYear = year
                            } label: {
                                HStack {
                                    Text(String(year))
                                    if year == viewModel.selectedYear {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(String(viewModel.selectedYear))
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                    }
                    .disabled(viewModel.availableYears.isEmpty)
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }
}

/// A card displaying distance for a workout type.
struct DistanceCard: View {
    let title: String
    let distance: Double
    let unit: DistanceUnit
    var iconName: String? = nil
    var isTotal: Bool = false
    var isYTD: Bool = true

    var body: some View {
        HStack(spacing: 20) {
            if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: isTotal ? 36 : 28))
                    .foregroundStyle(Color.accentColor.opacity(0.9))
                    .frame(width: 48)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(formattedDistance)
                    .font(.system(isTotal ? .largeTitle : .title, design: .rounded))
                    .fontWeight(.bold)
                    .contentTransition(.numericText())

                Text(isYTD ? "\(unit.abbreviation) YTD" : unit.abbreviation)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    private var formattedDistance: String {
        String(format: "%.1f", distance)
    }
}

#Preview {
    DashboardView(healthKitClient: PreviewHealthKitClient())
}

/// A mock client for SwiftUI previews.
private final class PreviewHealthKitClient: HealthKitClient, @unchecked Sendable {
    func requestAuthorization() async throws {}

    func fetchWorkouts(from startDate: Date, to endDate: Date, types: Set<WorkoutType>) async throws -> [Workout] {
        [
            Workout(type: .walk, distanceMeters: 160934.4, startDate: Date()),  // 100 miles
            Workout(type: .hike, distanceMeters: 48280.32, startDate: Date()),  // 30 miles
            Workout(type: .run, distanceMeters: 80467.2, startDate: Date())     // 50 miles
        ]
    }

    func fetchAvailableYears(types: Set<WorkoutType>) async throws -> [Int] {
        [2025, 2024, 2023, 2022]
    }
}
