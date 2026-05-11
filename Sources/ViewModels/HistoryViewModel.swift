import AppKit
import Foundation

@Observable
final class HistoryViewModel {
    private let historyStore: HistoryStore
    private let pasteboardMonitor: PasteboardMonitor
    private let ignoreListManager: IgnoreListManager

    var searchText: String = ""
    var statusMessage: String?
    private var searchTask: Task<Void, Never>?

    private var previousApp: NSRunningApplication?

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
        previousApp = NSWorkspace.shared.frontmostApplication
    }

    func pasteItem(_ item: ClipboardItem) {
        pasteboardMonitor.pause()
        writeToPasteboard(item)

        let hasAccessibility = AXIsProcessTrusted()
        if hasAccessibility {
            // Activate previous app and simulate paste
            if let app = previousApp {
                app.activate()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.simulatePaste()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.pasteboardMonitor.resume()
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
        // 1. Write to clipboard first
        pasteboardMonitor.pause()
        writeToPasteboard(item)

        // 2. Activate previous app and wait for it to fully focus
        if let app = previousApp {
            app.activate()
        }

        // 3. Wait for app to fully activate (1 second), then paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.simulatePaste()

            // 4. Resume monitoring after paste
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.pasteboardMonitor.resume()
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
        // Use NSAppleScript to simulate Cmd+V
        let script = """
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """

        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        appleScript?.executeAndReturnError(&error)

        if let error = error {
            // If AppleScript fails, try CGEvent as fallback
            simulatePasteWithCGEvent()
        }
    }

    private func simulatePasteWithCGEvent() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }

        let pid = frontApp.processIdentifier
        let source = CGEventSource(stateID: .combinedSessionState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) else { return }
        keyDown.flags = .maskCommand
        keyDown.postToPid(pid)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else { return }
            keyUp.flags = .maskCommand
            keyUp.postToPid(pid)
        }
    }
}
