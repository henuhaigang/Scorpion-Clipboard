import Foundation
import SwiftUI

enum PanelPosition: String, Codable, CaseIterable {
    case menuBar
    case floatingWindow
    case followMouse
    case fixedPosition
}

@Observable
final class SettingsModel {
    static let shared = SettingsModel()

    private let defaults = UserDefaults.standard

    enum Keys {
        static let historyLimit = "historyLimit"
        static let persistAfterRestart = "persistAfterRestart"
        static let ignoredBundleIDs = "ignoredBundleIDs"
        static let panelPosition = "panelPosition"
    }

    var historyLimit: Int {
        get { defaults.object(forKey: Keys.historyLimit) as? Int ?? 50 }
        set { defaults.set(newValue, forKey: Keys.historyLimit) }
    }

    var persistAfterRestart: Bool {
        get { defaults.object(forKey: Keys.persistAfterRestart) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.persistAfterRestart) }
    }

    var ignoredBundleIDs: [String] {
        get { defaults.stringArray(forKey: Keys.ignoredBundleIDs) ?? [] }
        set { defaults.set(newValue, forKey: Keys.ignoredBundleIDs) }
    }

    var panelPosition: PanelPosition {
        get {
            guard let raw = defaults.string(forKey: Keys.panelPosition),
                  let pos = PanelPosition(rawValue: raw) else {
                return .floatingWindow
            }
            return pos
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.panelPosition) }
    }

    func addIgnoredApp(_ bundleID: String) {
        var list = ignoredBundleIDs
        guard !list.contains(bundleID) else { return }
        list.append(bundleID)
        ignoredBundleIDs = list
    }

    func removeIgnoredApp(_ bundleID: String) {
        ignoredBundleIDs = ignoredBundleIDs.filter { $0 != bundleID }
    }
}
