import AppKit
import SwiftUI
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    var viewModel: HistoryViewModel!
    var panelController: PanelController!
    var shortcutController: ShortcutController!
    var settings: SettingsModel!

    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        viewModel.startMonitoring()
        shortcutController.register()
        shortcutController.onToggle = { [weak self] in
            self?.panelController.toggle()
        }

        // Check accessibility permission
        checkAccessibility()
    }

    private func checkAccessibility() {
        let trusted = AXIsProcessTrusted()
        print("[ClipboardCanvas] Accessibility permission: \(trusted ? "GRANTED" : "NOT GRANTED")")

        if !trusted {
            // Show alert after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let alert = NSAlert()
                alert.messageText = "需要辅助功能权限"
                alert.informativeText = "ClipboardCanvas 需要辅助功能权限才能自动粘贴内容。\n\n请在系统设置中授权：\n隐私与安全性 → 辅助功能 → 添加 ClipboardCanvas"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "打开设置")
                alert.addButton(withTitle: "稍后再说")

                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        viewModel.stopMonitoring()
    }

    @MainActor
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "clipboard.fill", accessibilityDescription: "ClipboardCanvas")
        button.title = " \(viewModel.itemCount)"

        let menu = NSMenu()

        // Shortcut info
        let shortcutText = Self.currentShortcutText()
        let shortcutItem = NSMenuItem(title: "显示面板: \(shortcutText)", action: #selector(showPanel), keyEquivalent: "")
        shortcutItem.target = self
        menu.addItem(shortcutItem)

        menu.addItem(NSMenuItem.separator())

        let countItem = NSMenuItem(title: "历史记录: \(viewModel.itemCount) 条", action: nil, keyEquivalent: "")
        countItem.isEnabled = false
        menu.addItem(countItem)

        menu.addItem(NSMenuItem.separator())

        let showItem = NSMenuItem(title: "显示面板", action: #selector(showPanel), keyEquivalent: "o")
        showItem.keyEquivalentModifierMask = [.command]
        showItem.target = self
        menu.addItem(showItem)

        let clearItem = NSMenuItem(title: "清空历史", action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "偏好设置...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = [.command]
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出 ClipboardCanvas", action: #selector(quit), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @MainActor
    static func currentShortcutText() -> String {
        if let shortcut = KeyboardShortcuts.Shortcut(name: .togglePanel) {
            return shortcut.description
        }
        return "未设置"
    }

    @objc private func showPanel() {
        panelController.toggle()
    }

    @objc private func clearHistory() {
        let alert = NSAlert()
        alert.messageText = "清空历史记录"
        alert.informativeText = "确定要清空所有剪贴板历史记录吗？此操作不可撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "清空")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            viewModel.clearHistory()
            updateStatusTitle()
        }
    }

    @objc private func openSettings() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14.0, *) {
            NSApp.activate()
        }
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    func updateStatusTitle() {
        statusItem?.button?.title = " \(viewModel.itemCount)"
    }
}
