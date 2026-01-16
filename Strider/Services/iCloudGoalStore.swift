import Foundation
import UIKit

/// Notification posted when goal settings are changed from another device via iCloud sync.
extension Notification.Name {
    static let goalSettingsDidChangeExternally = Notification.Name("goalSettingsDidChangeExternally")
    /// Notification posted when goal settings are changed locally.
    static let goalSettingsDidChange = Notification.Name("goalSettingsDidChange")
}

/// iCloud-backed implementation of GoalStore using NSUbiquitousKeyValueStore.
/// Falls back to UserDefaults when iCloud is unavailable.
final class iCloudGoalStore: GoalStore, @unchecked Sendable {
    /// Shared singleton instance.
    static let shared = iCloudGoalStore()

    private let cloud = NSUbiquitousKeyValueStore.default
    private let local: UserDefaultsGoalStore
    private let key = "com.strider.goalSettings"
    private let migrationKey = "com.strider.iCloudMigrationComplete"
    private let lastSyncedHashKey = "com.strider.lastSyncedSettingsHash"

    private init(localFallback: UserDefaultsGoalStore = UserDefaultsGoalStore()) {
        self.local = localFallback
        setupNotifications()
        migrateIfNeeded()
        cloud.synchronize()
        updateLastSyncedHash()
    }

    func load() -> GoalSettings {
        // Try iCloud first
        if let data = cloud.data(forKey: key),
           let settings = try? JSONDecoder().decode(GoalSettings.self, from: data) {
            return settings
        }
        // Fall back to local
        return local.load()
    }

    func save(_ settings: GoalSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }

        // Save to both iCloud and local (local serves as cache)
        cloud.set(data, forKey: key)
        cloud.synchronize()

        local.save(settings)
        updateLastSyncedHash()

        // Notify other parts of the app about the local change
        NotificationCenter.default.post(
            name: .goalSettingsDidChange,
            object: nil,
            userInfo: ["settings": settings]
        )
    }

    // MARK: - Private

    private func setupNotifications() {
        // Listen for iCloud sync notifications
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud,
            queue: .main
        ) { [weak self] notification in
            self?.handleExternalChange(notification)
        }

        // Check for updates when app enters foreground (handles case where app was terminated)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkForCloudUpdates()
        }
    }

    /// Checks if iCloud has newer data than what we last saw, and notifies if so.
    private func checkForCloudUpdates() {
        // Pull latest from iCloud
        cloud.synchronize()

        // Compare current cloud data hash with what we last synced
        guard let data = cloud.data(forKey: key) else { return }
        let currentHash = data.hashValue
        let lastHash = UserDefaults.standard.integer(forKey: lastSyncedHashKey)

        if currentHash != lastHash {
            // Cloud has new data - update local and notify
            if let settings = try? JSONDecoder().decode(GoalSettings.self, from: data) {
                local.save(settings)
                updateLastSyncedHash()
                NotificationCenter.default.post(
                    name: .goalSettingsDidChangeExternally,
                    object: nil,
                    userInfo: ["settings": settings]
                )
            }
        }
    }

    /// Updates the hash of the last synced settings.
    private func updateLastSyncedHash() {
        if let data = cloud.data(forKey: key) {
            UserDefaults.standard.set(data.hashValue, forKey: lastSyncedHashKey)
        }
    }

    private func handleExternalChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int,
              let keys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
              keys.contains(key) else {
            return
        }

        switch reason {
        case NSUbiquitousKeyValueStoreServerChange,
             NSUbiquitousKeyValueStoreInitialSyncChange:
            let settings = load()
            // Update local cache and hash
            local.save(settings)
            updateLastSyncedHash()
            // Notify the app of external changes
            NotificationCenter.default.post(
                name: .goalSettingsDidChangeExternally,
                object: nil,
                userInfo: ["settings": settings]
            )
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            // Storage quota exceeded - this shouldn't happen with small settings data
            // but we continue to function with local storage
            break
        case NSUbiquitousKeyValueStoreAccountChange:
            // iCloud account changed - reload from new account or fall back to local
            let settings = load()
            updateLastSyncedHash()
            NotificationCenter.default.post(
                name: .goalSettingsDidChangeExternally,
                object: nil,
                userInfo: ["settings": settings]
            )
        default:
            break
        }
    }

    private func migrateIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        // If local has user data but cloud doesn't, push local to cloud
        let localSettings = local.load()
        let hasCloudData = cloud.data(forKey: key) != nil
        let hasLocalData = localSettings != .default

        if hasLocalData && !hasCloudData {
            if let data = try? JSONEncoder().encode(localSettings) {
                cloud.set(data, forKey: key)
                cloud.synchronize()
            }
        }

        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
