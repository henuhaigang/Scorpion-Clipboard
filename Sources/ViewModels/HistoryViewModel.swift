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
        // previousApp is already set by appActivated notification observer
        print("[ViewModel] savePreviousApp: previousApp=\(String(describing: previousApp?.localizedName))")
    }

    func pasteItem(_ item: ClipboardItem) {
        pasteboardMonitor.pause()
        writeToPasteboard(item)

        let hasAccessibility = AXIsProcessTrusted()
        if hasAccessibility {
            if let app = previousApp {
                app.activate()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self = self else { return }
                if let prev = self.previousApp,
                   NSWorkspace.shared.frontmostApplication != prev {
                    prev.activate()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.simulatePaste()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        self?.pasteboardMonitor.resume()
                    }
                }
            }
        } else {
            statusMessage = "已复制到剪贴板 (需要辅助功能权限才能自动粘贴)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.pasteboardMonitor.resume()
                self?.statusMessage = nil
            }
        }
    }

    func restoreFocusAndPaste(_ item: ClipboardItem) {
        pasteboardMonitor.pause()
        writeToPasteboard(item)

        if let app = previousApp {
            app.activate()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self = self else { return }

            if let prev = self.previousApp,
               NSWorkspace.shared.frontmostApplication != prev {
                prev.activate()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.simulatePaste()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self?.pasteboardMonitor.resume()
                }
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
        print("[ViewModel] simulatePaste: target=\(String(describing: frontmost.localizedName)), axTrusted=\(AXIsProcessTrusted())")

        // Method 1: Try CGEvent with .cgAnnotatedSessionEventTap (higher level, more reliable for local apps)
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKey: CGKeyCode = 0x09

        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cgAnnotatedSessionEventTap)
            print("[ViewModel] simulatePaste: posted Cmd+V keyDown (session tap)")

            Thread.sleep(forTimeInterval: 0.05)

            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false) {
                keyUp.flags = .maskCommand
                keyUp.post(tap: .cgAnnotatedSessionEventTap)
                print("[ViewModel] simulatePaste: posted Cmd+V keyUp (session tap)")
            } else {
                print("[ViewModel] simulatePaste: failed to create keyUp")
            }
        } else {
            print("[ViewModel] simulatePaste: failed to create keyDown")
        }
    }
}
