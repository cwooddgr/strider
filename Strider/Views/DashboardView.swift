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
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(WorkoutType.allCases, id: \.self) { type in
                                DistanceCard(
                                    title: type.displayName,
                                    miles: summary.miles(for: type),
                                    isYTD: viewModel.isCurrentYear
                                )
                            }

                            Divider()
                                .padding(.vertical, 8)

                            DistanceCard(
                                title: "Total",
                                miles: summary.totalMiles,
                                isTotal: true,
                                isYTD: viewModel.isCurrentYear
                            )
                        }
                        .padding()
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
            .navigationTitle("Strider")
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
    let miles: Double
    var isTotal: Bool = false
    var isYTD: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(isTotal ? .headline : .subheadline)
                .foregroundStyle(.secondary)

            Text(formattedMiles)
                .font(isTotal ? .largeTitle : .title)
                .fontWeight(.bold)
                .contentTransition(.numericText())

            Text(isYTD ? "miles YTD" : "miles")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(isTotal ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var formattedMiles: String {
        String(format: "%.1f", miles)
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
