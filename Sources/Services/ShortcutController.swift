import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePanel = Self("togglePanel")
}

final class ShortcutController {
    var onToggle: (() -> Void)?

    func register() {
        KeyboardShortcuts.onKeyUp(for: .togglePanel) { [weak self] in
            self?.onToggle?()
        }
    }
}
