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

        print("[PanelController] Monitors started: local=\(localMonitor != nil), global=\(globalMonitor != nil)")
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

        // keyCode mapping for number keys 1-9, 0 on US ANSI keyboard
        let keyCodeMap: [UInt16: Int] = [
            0x12: 0,  // 1 -> index 0
            0x13: 1,  // 2 -> index 1
            0x14: 2,  // 3 -> index 2
            0x15: 3,  // 4 -> index 3
            0x17: 4,  // 5 -> index 4
            0x16: 5,  // 6 -> index 5
            0x1A: 6,  // 7 -> index 6
            0x1C: 7,  // 8 -> index 7
            0x19: 8,  // 9 -> index 8
            0x1D: 9,  // 0 -> index 9
        ]

        if let itemIndex = keyCodeMap[event.keyCode],
           flags.isEmpty || flags.contains(.control),
           itemIndex < viewModel.filteredItems.count {
            viewModel.selectedRowIndex = itemIndex
            let item = viewModel.filteredItems[itemIndex]
            pasteAndClose(item)
            return nil
        }

        // Escape to close
        if event.keyCode == 53 {
            close()
            return nil
        }

        // Up arrow: move selection up
        if event.keyCode == 126 && !flags.contains(.command) {
            let count = viewModel.filteredItems.count
            if count > 0 {
                viewModel.selectedRowIndex = max(0, viewModel.selectedRowIndex - 1)
            }
            return nil
        }

        // Down arrow: move selection down
        if event.keyCode == 125 && !flags.contains(.command) {
            let count = viewModel.filteredItems.count
            if count > 0 {
                viewModel.selectedRowIndex = min(count - 1, viewModel.selectedRowIndex + 1)
            }
            return nil
        }

        // Enter: paste selected item
        if event.keyCode == 36 {
            let count = viewModel.filteredItems.count
            if count > 0, viewModel.selectedRowIndex < count {
                let item = viewModel.filteredItems[viewModel.selectedRowIndex]
                pasteAndClose(item)
            } else {
                close()
            }
            return nil
        }

        return event
    }

    private func pasteAndClose(_ item: ClipboardItem) {
        close()
        viewModel.restoreFocusAndPaste(item)
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
        panel.title = "ScorpionClipboard"
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
