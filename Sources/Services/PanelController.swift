import AppKit
import SwiftUI
import KeyboardShortcuts

final class PanelController {
    private var panel: NSPanel?
    private let viewModel: HistoryViewModel
    private let settings: SettingsModel
    private var localMonitor: Any?
    private var globalMonitor: Any?

    init(viewModel: HistoryViewModel, settings: SettingsModel = .shared) {
        self.viewModel = viewModel
        self.settings = settings
    }

    deinit {
        stopMonitors()
    }

    func toggle() {
        if let panel = panel, panel.isVisible {
            close()
        } else {
            show()
        }
    }

    func show() {
        if panel == nil {
            createPanel()
        }
        viewModel.savePreviousApp()
        positionPanel()
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        startMonitors()
    }

    func close() {
        panel?.orderOut(nil)
        stopMonitors()
    }

    // MARK: - Keyboard Monitoring

    private func startMonitors() {
        stopMonitors()

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            return self?.handleKeyEvent(event) ?? event
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            _ = self?.handleKeyEvent(event)
        }
    }

    private func stopMonitors() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Number keys 1-9, 0 without modifier (when panel is open)
        if flags.isEmpty || flags == .numericPad,
           let chars = event.charactersIgnoringModifiers {
            let numbers = "1234567890"
            if let index = numbers.firstIndex(of: Character(chars)) {
                let position = numbers.distance(from: numbers.startIndex, to: index)
                let itemIndex = position

                if itemIndex < viewModel.filteredItems.count {
                    let item = viewModel.filteredItems[itemIndex]
                    pasteAndClose(item)
                    return nil
                }
            }
        }

        // Escape to close
        if event.keyCode == 53 {
            close()
            return nil
        }

        return event
    }

    private func pasteAndClose(_ item: ClipboardItem) {
        // 1. Hide panel immediately
        close()

        // 2. Wait for panel to hide and system to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.viewModel.restoreFocusAndPaste(item)
        }
    }

    // MARK: - Panel Creation

    private func createPanel() {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.title = "ClipboardCanvas"
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true

        let hostingView = NSHostingView(rootView:
            HistoryPanelView(viewModel: viewModel) { [weak self] in
                self?.close()
            }
        )
        panel.contentView = hostingView

        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            self?.close()
        }

        self.panel = panel
    }

    // MARK: - Positioning

    private func positionPanel() {
        guard let panel = panel else { return }

        switch settings.panelPosition {
        case .menuBar:
            positionAtMenuBar(panel)
        case .followMouse:
            positionAtMouse(panel)
        case .fixedPosition:
            positionAtFixed(panel)
        case .floatingWindow:
            positionCentered(panel)
        }
    }

    private func positionAtMenuBar(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let panelSize = panel.frame.size
        let x = screenFrame.midX - panelSize.width / 2
        let y = screenFrame.maxY - panelSize.height - 30
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func positionAtMouse(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let panelSize = panel.frame.size
        let x = mouseLocation.x - panelSize.width / 2
        let y = mouseLocation.y - panelSize.height
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func positionAtFixed(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelSize = panel.frame.size
        let x = screenFrame.maxX - panelSize.width - 20
        let y = screenFrame.minY + 20
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func positionCentered(_ panel: NSPanel) {
        panel.center()
    }

    @MainActor
    static func displayShortcut() -> String {
        if let shortcut = KeyboardShortcuts.Shortcut(name: .togglePanel) {
            return shortcut.description
        }
        return "未设置"
    }
}
