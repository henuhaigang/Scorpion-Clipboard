import AppKit

@Observable
final class IgnoreListManager {
    private let settings: SettingsModel

    init(settings: SettingsModel = .shared) {
        self.settings = settings
    }

    var ignoredBundleIDs: [String] {
        settings.ignoredBundleIDs
    }

    func isCurrentAppIgnored() -> Bool {
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return false
        }
        return settings.ignoredBundleIDs.contains(bundleID)
    }

    func isAppIgnored(bundleID: String) -> Bool {
        settings.ignoredBundleIDs.contains(bundleID)
    }

    func addIgnoredApp(_ bundleID: String) {
        settings.addIgnoredApp(bundleID)
    }

    func removeIgnoredApp(_ bundleID: String) {
        settings.removeIgnoredApp(bundleID)
    }

    func runningApps() -> [(name: String, bundleID: String)] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in
                guard let name = app.localizedName,
                      let bundleID = app.bundleIdentifier else { return nil }
                return (name: name, bundleID: bundleID)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
