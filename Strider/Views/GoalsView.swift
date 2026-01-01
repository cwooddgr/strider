import SwiftUI

struct GoalsView: View {
    @State private var viewModel: GoalsViewModel
    @State private var editingGoal: GoalType?

    init(healthKitClient: HealthKitClient) {
        _viewModel = State(wrappedValue: GoalsViewModel(healthKitClient: healthKitClient))
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading goals...")

            case .loaded(let weekly, let monthly, let yearly):
                let isRolling = viewModel.settings.windowMode == .rolling
                let unit = viewModel.settings.distanceUnit
                List {
                    Section {
                        GoalRow(
                            title: isRolling ? "7-Day Rolling" : "Weekly",
                            progress: weekly,
                            goalValue: viewModel.settings.weeklyGoalInUnit,
                            unit: unit,
                            iconName: GoalType.weekly.iconName
                        ) {
                            editingGoal = .weekly
                        }

                        GoalRow(
                            title: isRolling ? "30-Day Rolling" : "Monthly",
                            progress: monthly,
                            goalValue: viewModel.settings.monthlyGoalInUnit,
                            unit: unit,
                            iconName: GoalType.monthly.iconName
                        ) {
                            editingGoal = .monthly
                        }

                        GoalRow(
                            title: "Yearly",
                            progress: yearly,
                            goalValue: viewModel.settings.yearlyGoalInUnit,
                            unit: unit,
                            iconName: GoalType.yearly.iconName
                        ) {
                            editingGoal = .yearly
                        }
                    } footer: {
                        Text("Tap a goal to edit")
                    }

                    Section {
                        Picker("Goal Periods", selection: Binding(
                            get: { viewModel.settings.windowMode },
                            set: { newValue in
                                viewModel.settings.windowMode = newValue
                                viewModel.saveSettings()
                            }
                        )) {
                            ForEach(WindowMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }

                        if viewModel.settings.windowMode == .calendar {
                            Picker("Week Starts On", selection: Binding(
                                get: { viewModel.settings.weekStart },
                                set: { newValue in
                                    viewModel.settings.weekStart = newValue
                                    viewModel.saveSettings()
                                }
                            )) {
                                ForEach(WeekStart.allCases, id: \.self) { day in
                                    Text(day.displayName).tag(day)
                                }
                            }
                        }

                    } header: {
                        Text("Settings")
                    } footer: {
                        Text(viewModel.settings.windowMode.description)
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
        .sheet(item: $editingGoal) { goalType in
            EditGoalSheet(
                goalType: goalType,
                currentValue: currentGoalValue(for: goalType),
                unit: viewModel.settings.distanceUnit,
                onSave: { newValue in
                    setGoal(goalType, value: newValue)
                },
                onSaveAllFromYearly: goalType == .yearly ? { yearlyValue in
                    setAllGoalsFromYearly(yearlyValue)
                } : nil
            )
            .presentationDetents([.height(goalType == .yearly ? 280 : 200)])
        }
        .task {
            await viewModel.loadProgress()
        }
    }

    private func currentGoalValue(for goalType: GoalType) -> Double? {
        switch goalType {
        case .weekly: return viewModel.settings.weeklyGoalInUnit
        case .monthly: return viewModel.settings.monthlyGoalInUnit
        case .yearly: return viewModel.settings.yearlyGoalInUnit
        }
    }

    private func setGoal(_ goalType: GoalType, value: Double?) {
        switch goalType {
        case .weekly: viewModel.settings.weeklyGoalInUnit = value
        case .monthly: viewModel.settings.monthlyGoalInUnit = value
        case .yearly: viewModel.settings.yearlyGoalInUnit = value
        }
        viewModel.saveSettings()
    }

    private func setAllGoalsFromYearly(_ yearlyValue: Double?) {
        viewModel.settings.yearlyGoalInUnit = yearlyValue
        if let yearly = yearlyValue {
            viewModel.settings.monthlyGoalInUnit = yearly / 12
            viewModel.settings.weeklyGoalInUnit = yearly / 52
        } else {
            viewModel.settings.monthlyGoalInUnit = nil
            viewModel.settings.weeklyGoalInUnit = nil
        }
        viewModel.saveSettings()
    }
}

/// Identifies which goal is being edited.
enum GoalType: String, Identifiable {
    case weekly, monthly, yearly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    var iconName: String {
        switch self {
        case .weekly: return "7.circle"
        case .monthly: return "calendar"
        case .yearly: return "star.circle.fill"
        }
    }
}

/// Row showing a goal with optional progress.
struct GoalRow: View {
    let title: String
    let progress: GoalProgress?
    let goalValue: Double?
    let unit: DistanceUnit
    let iconName: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        if let progress, progress.isComplete {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else if goalValue != nil {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    if let progress {
                        ProgressView(value: progress.progress)
                            .tint(progress.isComplete ? .green : .accentColor)

                        HStack {
                            Text(String(format: "%.1f / %.1f %@", progress.displayCurrent(in: unit), progress.displayGoal(in: unit), unit.abbreviation))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if !progress.isComplete {
                                Text(String(format: "%.1f to go", progress.displayRemaining(in: unit)))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        HStack {
                            Text("No goal set")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                            Spacer()
                            Text("Tap to set")
                                .font(.subheadline)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Sheet for editing a single goal.
struct EditGoalSheet: View {
    let goalType: GoalType
    let currentValue: Double?
    let unit: DistanceUnit
    let onSave: (Double?) -> Void
    let onSaveAllFromYearly: ((Double?) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var valueText: String = ""
    @State private var setAllGoals: Bool = false
    @FocusState private var isFocused: Bool

    private var canSetAllGoals: Bool {
        onSaveAllFromYearly != nil
    }

    private var calculatedMonthly: Double? {
        guard let value = Double(valueText) else { return nil }
        return value / 12
    }

    private var calculatedWeekly: Double? {
        guard let value = Double(valueText) else { return nil }
        return value / 52
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Goal", text: $valueText)
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                        Text(unit.abbreviation)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Leave empty to remove the goal")
                }

                if canSetAllGoals {
                    Section {
                        Toggle("Also set weekly & monthly", isOn: $setAllGoals)
                    } footer: {
                        if setAllGoals, let monthly = calculatedMonthly, let weekly = calculatedWeekly {
                            Text("Monthly: \(String(format: "%.1f", monthly)) \(unit.abbreviation) · Weekly: \(String(format: "%.1f", weekly)) \(unit.abbreviation)")
                        }
                    }
                }
            }
            .navigationTitle("\(goalType.displayName) Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
            .onAppear {
                valueText = currentValue.map { formatValue($0) } ?? ""
                isFocused = true
            }
        }
    }

    private func save() {
        let value = Double(valueText)
        if setAllGoals, let saveAll = onSaveAllFromYearly {
            saveAll(value)
        } else {
            onSave(value)
        }
        dismiss()
    }

    /// Formats value, showing decimals only if needed.
    private func formatValue(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return String(format: "%.0f", rounded)
        } else {
            return String(format: "%.1f", rounded)
        }
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
