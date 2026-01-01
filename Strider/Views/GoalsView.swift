import SwiftUI

struct GoalsView: View {
    @State private var viewModel: GoalsViewModel
    @State private var isEditingGoals = false

    init(healthKitClient: HealthKitClient) {
        _viewModel = State(wrappedValue: GoalsViewModel(healthKitClient: healthKitClient))
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading goals...")

            case .loaded(let weekly, let monthly, let yearly):
                List {
                    Section {
                        if let progress = weekly {
                            GoalProgressRow(title: "Weekly", progress: progress)
                        } else {
                            NoGoalRow(title: "Weekly")
                        }

                        if let progress = monthly {
                            GoalProgressRow(title: "Monthly", progress: progress)
                        } else {
                            NoGoalRow(title: "Monthly")
                        }

                        if let progress = yearly {
                            GoalProgressRow(title: "Yearly", progress: progress)
                        } else {
                            NoGoalRow(title: "Yearly")
                        }
                    } header: {
                        Text("Progress")
                    }

                    Section {
                        HStack {
                            Text("Window Mode")
                            Spacer()
                            Text(viewModel.settings.windowMode.displayName)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Week Starts")
                            Spacer()
                            Text(viewModel.settings.weekStart.displayName)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Settings")
                    }
                }
                .refreshable {
                    await viewModel.loadProgress()
                }

            case .error(let message):
                ContentUnavailableView {
                    Label("Unable to Load", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") {
                        Task {
                            await viewModel.loadProgress()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Goals")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isEditingGoals = true
                }
            }
        }
        .sheet(isPresented: $isEditingGoals) {
            EditGoalsView(settings: $viewModel.settings) {
                viewModel.saveSettings()
            }
        }
        .task {
            await viewModel.loadProgress()
        }
    }
}

/// Row showing progress toward a goal.
struct GoalProgressRow: View {
    let title: String
    let progress: GoalProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if progress.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            ProgressView(value: progress.progress)
                .tint(progress.isComplete ? .green : .accentColor)

            HStack {
                Text(String(format: "%.1f / %.1f miles", progress.currentMiles, progress.goalMiles))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if !progress.isComplete {
                    Text(String(format: "%.1f to go", progress.remainingMiles))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// Row shown when no goal is set.
struct NoGoalRow: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text("No goal set")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

/// Sheet for editing goal settings.
struct EditGoalsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var settings: GoalSettings
    let onSave: () -> Void

    @State private var weeklyMiles: String = ""
    @State private var monthlyMiles: String = ""
    @State private var yearlyMiles: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Weekly")
                        Spacer()
                        TextField("miles", text: $weeklyMiles)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("mi")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Monthly")
                        Spacer()
                        TextField("miles", text: $monthlyMiles)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("mi")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Yearly")
                        Spacer()
                        TextField("miles", text: $yearlyMiles)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("mi")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Distance Goals")
                } footer: {
                    Text("Leave blank to disable a goal.")
                }

                Section {
                    Picker("Window Mode", selection: $settings.windowMode) {
                        ForEach(WindowMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }

                    Picker("Week Starts On", selection: $settings.weekStart) {
                        ForEach(WeekStart.allCases, id: \.self) { day in
                            Text(day.displayName).tag(day)
                        }
                    }
                } header: {
                    Text("Settings")
                } footer: {
                    Text(settings.windowMode.description)
                }
            }
            .navigationTitle("Edit Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentValues()
            }
        }
    }

    private func loadCurrentValues() {
        weeklyMiles = settings.weeklyGoalMiles.map { String(format: "%.0f", $0) } ?? ""
        monthlyMiles = settings.monthlyGoalMiles.map { String(format: "%.0f", $0) } ?? ""
        yearlyMiles = settings.yearlyGoalMiles.map { String(format: "%.0f", $0) } ?? ""
    }

    private func saveAndDismiss() {
        settings.weeklyGoalMiles = Double(weeklyMiles)
        settings.monthlyGoalMiles = Double(monthlyMiles)
        settings.yearlyGoalMiles = Double(yearlyMiles)
        onSave()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        GoalsView(healthKitClient: PreviewHealthKitClient())
    }
}

/// A mock client for SwiftUI previews.
private final class PreviewHealthKitClient: HealthKitClient, @unchecked Sendable {
    func requestAuthorization() async throws {}

    func fetchWorkouts(from startDate: Date, to endDate: Date, types: Set<WorkoutType>) async throws -> [Workout] {
        [
            Workout(type: .walk, distanceMeters: 16093.44, startDate: Date()),   // 10 miles
            Workout(type: .run, distanceMeters: 8046.72, startDate: Date())      // 5 miles
        ]
    }

    func fetchAvailableYears(types: Set<WorkoutType>) async throws -> [Int] {
        [2025, 2024, 2023]
    }
}
