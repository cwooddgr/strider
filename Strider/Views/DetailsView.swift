import SwiftUI

struct DetailsView: View {
    @State private var viewModel: DetailsViewModel

    init(healthKitClient: HealthKitClient) {
        _viewModel = State(wrappedValue: DetailsViewModel(healthKitClient: healthKitClient))
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading workouts...")

            case .loaded(let workouts):
                if workouts.isEmpty {
                    ContentUnavailableView {
                        Label("No Workouts", systemImage: "figure.walk")
                    } description: {
                        Text("No walk, hike, or run workouts found")
                    }
                } else {
                    workoutsList(workouts)
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
        .navigationTitle("Details")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Last 30 Days")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private func workoutsList(_ workouts: [Workout]) -> some View {
        List {
            ForEach(viewModel.workoutsByDay(workouts), id: \.date) { group in
                Section(viewModel.sectionHeader(for: group.date)) {
                    ForEach(group.workouts) { workout in
                        WorkoutRow(
                            workout: workout,
                            timeString: viewModel.timeString(for: workout.startDate)
                        )
                    }
                }
            }

            if let refreshedString = viewModel.lastRefreshedString {
                Section {
                    EmptyView()
                } footer: {
                    Text("Updated \(refreshedString)")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .refreshable {
            await viewModel.load()
        }
    }
}

struct WorkoutRow: View {
    let workout: Workout
    let timeString: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: workout.type.iconName)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.type.displayName)
                    .font(.headline)

                Text(timeString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(String(format: "%.1f mi", workout.distanceMiles))
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        DetailsView(healthKitClient: PreviewHealthKitClient())
    }
}

private final class PreviewHealthKitClient: HealthKitClient, @unchecked Sendable {
    func requestAuthorization() async throws {}

    func fetchWorkouts(from startDate: Date, to endDate: Date, types: Set<WorkoutType>) async throws -> [Workout] {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!

        return [
            Workout(type: .run, distanceMeters: 5000, startDate: now),
            Workout(type: .walk, distanceMeters: 3200, startDate: now.addingTimeInterval(-3600)),
            Workout(type: .hike, distanceMeters: 8000, startDate: yesterday),
            Workout(type: .walk, distanceMeters: 4800, startDate: yesterday.addingTimeInterval(-7200)),
            Workout(type: .run, distanceMeters: 10000, startDate: twoDaysAgo)
        ]
    }

    func fetchAvailableYears(types: Set<WorkoutType>) async throws -> [Int] {
        [2026, 2025, 2024]
    }
}
