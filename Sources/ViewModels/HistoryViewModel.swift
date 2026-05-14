import AppKit
import Foundation

@Observable
final class HistoryViewModel {
    private let historyStore: HistoryStore
    private let pasteboardMonitor: PasteboardMonitor
    private let ignoreListManager: IgnoreListManager

    var searchText: String = ""
    var statusMessage: String?
    var selectedRowIndex: Int = 0
    private var searchTask: Task<Void, Never>?

    private var previousApp: NSRunningApplication?
    private var lastNonSelfApp: NSRunningApplication?

    init(
        historyStore: HistoryStore,
        pasteboardMonitor: PasteboardMonitor,
        ignoreListManager: IgnoreListManager
    ) {
        self.historyStore = historyStore
        self.pasteboardMonitor = pasteboardMonitor
        self.ignoreListManager = ignoreListManager

        pasteboardMonitor.onNewContent = { [weak self] item in
            self?.handleNewContent(item)
        }

        // Track activated apps to know which one was before ScorpionClipboard
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appActivated(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func appActivated(_ notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            print("[ViewModel] App activated: \(String(describing: app.localizedName)) (bundle: \(app.bundleIdentifier ?? "unknown"))")
            if app.bundleIdentifier != Bundle.main.bundleIdentifier {
                lastNonSelfApp = app
            } else {
                // ScorpionClipboard just became active — save the last non-self app
                previousApp = lastNonSelfApp
                print("[ViewModel] Saved previousApp: \(String(describing: previousApp?.localizedName))")
            }
        }
    }

    var filteredItems: [ClipboardItem] {
        guard !searchText.isEmpty else { return historyStore.items }
        return historyStore.items.filter {
            $0.briefText.localizedCaseInsensitiveContains(searchText)
        }
    }

    var itemCount: Int { historyStore.count }

    func startMonitoring() {
        pasteboardMonitor.start()
    }

    func stopMonitoring() {
        pasteboardMonitor.stop()
    }

    func updateSearch(_ text: String) {
        searchTask?.cancel()
        searchTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            searchText = text
        }
    }

    func savePreviousApp() {
        let ourBundleId = Bundle.main.bundleIdentifier ?? ""
        print("[ViewModel] savePreviousApp: ourBundleId=\(ourBundleId)")

        // Strategy 1: Get current frontmost app directly (before we activate ourselves)
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.bundleIdentifier != ourBundleId {
            previousApp = frontmost
            print("[ViewModel] savePreviousApp: captured frontmost=\(String(describing: previousApp?.localizedName))")
            return
        }

        // Strategy 2: Look through running apps for the most recently active non-self app
        let apps = NSWorkspace.shared.runningApplications
        for app in apps.reversed() {
            if app.activationPolicy == .regular,
               app.bundleIdentifier != ourBundleId,
               app.localizedName != nil {
                previousApp = app
                print("[ViewModel] savePreviousApp: fallback to app=\(String(describing: app.localizedName))")
                return
            }
        }

        print("[ViewModel] savePreviousApp: no suitable app found")
    }

    func pasteItem(_ item: ClipboardItem) {
        pasteboardMonitor.pause()
        writeToPasteboard(item)

        let hasAccessibility = AXIsProcessTrusted()
        if !hasAccessibility {
            statusMessage = "已复制到剪贴板 (需要辅助功能权限才能自动粘贴)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.pasteboardMonitor.resume()
                self?.statusMessage = nil
            }
            return
        }

        guard let targetApp = previousApp else {
            simulatePaste()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.pasteboardMonitor.resume()
            }
            return
        }

        targetApp.activate(options: .activateAllWindows)
        print("[ViewModel] pasteItem: activating \(String(describing: targetApp.localizedName))")

        Task { [weak self, targetApp] in
            guard let self else { return }
            var didPaste = false
            let maxAttempts = 16
            for attempt in 0..<maxAttempts {
                try? await Task.sleep(for: .milliseconds(50))
                await MainActor.run {
                    guard !didPaste else { return }
                    if NSWorkspace.shared.frontmostApplication == targetApp {
                        didPaste = true
                        print("[ViewModel] pasteItem: \(String(describing: targetApp.localizedName)) is frontmost after \(attempt + 1) attempts")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                            self?.simulatePaste()
                            self?.pasteboardMonitor.resume()
                        }
                    }
                }
                if didPaste { break }
            }
            guard !didPaste else { return }
            print("[ViewModel] pasteItem: timeout waiting for \(String(describing: targetApp.localizedName)), pasting anyway")
            await MainActor.run {
                self.simulatePaste()
                self.pasteboardMonitor.resume()
            }
        }
    }

    func restoreFocusAndPaste(_ item: ClipboardItem) {
        pasteboardMonitor.pause()
        writeToPasteboard(item)

        guard let targetApp = previousApp else {
            simulatePaste()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.pasteboardMonitor.resume()
            }
            return
        }

        // Activate target app and wait until it's confirmed frontmost
        targetApp.activate(options: .activateAllWindows)
        print("[ViewModel] restoreFocusAndPaste: activating \(String(describing: targetApp.localizedName))")

        Task { [weak self, targetApp] in
            guard let self else { return }
            var didPaste = false
            let maxAttempts = 16
            for attempt in 0..<maxAttempts {
                try? await Task.sleep(for: .milliseconds(50))
                await MainActor.run {
                    guard !didPaste else { return }
                    if NSWorkspace.shared.frontmostApplication == targetApp {
                        didPaste = true
                        print("[ViewModel] restoreFocusAndPaste: \(String(describing: targetApp.localizedName)) is frontmost after \(attempt + 1) attempts")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                            self?.simulatePaste()
                            self?.pasteboardMonitor.resume()
                        }
                    }
                }
                if didPaste { break }
            }
            guard !didPaste else { return }
            print("[ViewModel] restoreFocusAndPaste: timeout waiting for \(String(describing: targetApp.localizedName)), pasting anyway")
            await MainActor.run {
                self.simulatePaste()
                self.pasteboardMonitor.resume()
            }
        }
    }

    private func writeToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text:
            pasteboard.setString(item.briefText, forType: .string)
        case .rtf:
            if let data = item.rawData {
                pasteboard.setData(data, forType: .rtf)
            }
        case .image:
            if let data = item.rawData {
                pasteboard.setData(data, forType: .tiff)
            }
        case .fileURL:
            if let path = item.filePath {
                let url = URL(fileURLWithPath: path)
                pasteboard.writeObjects([url as NSURL])
            }
        }
    }

    func deleteItem(_ item: ClipboardItem) {
        if let index = historyStore.items.firstIndex(where: { $0.id == item.id }) {
            historyStore.remove(at: index)
        }
    }

    func clearHistory() {
        historyStore.clear()
    }

    private func handleNewContent(_ item: ClipboardItem) {
        guard !ignoreListManager.isCurrentAppIgnored() else { return }
        Task { @MainActor in
            historyStore.add(item)
        }
    }

    private func simulatePaste() {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else {
            print("[ViewModel] simulatePaste: no frontmost app")
            return
        }
        let pid = frontmost.processIdentifier
        print("[ViewModel] simulatePaste: target=\(String(describing: frontmost.localizedName)) pid=\(pid), axTrusted=\(AXIsProcessTrusted())")

        guard AXIsProcessTrusted() else {
            print("[ViewModel] simulatePaste: Accessibility not granted")
            statusMessage = "已复制到剪贴板，请按 ⌘V 粘贴"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.statusMessage = nil
            }
            return
        }

        let vKey: CGKeyCode = 0x09
        let source = CGEventSource(stateID: .privateState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true) else {
            print("[ViewModel] simulatePaste: failed to create keyDown")
            return
        }
        keyDown.flags = .maskCommand
        keyDown.postToPid(pid)
        print("[ViewModel] simulatePaste: posted Cmd+V keyDown to pid \(pid)")

        usleep(50000)

        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false) else {
            print("[ViewModel] simulatePaste: failed to create keyUp")
            return
        }
        keyUp.flags = .maskCommand
        keyUp.postToPid(pid)
        print("[ViewModel] simulatePaste: posted Cmd+V keyUp to pid \(pid)")
    }
}
