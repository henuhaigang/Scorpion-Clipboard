import KeyboardShortcuts
import SwiftUI

@main
struct ClipboardCanvasApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var settings = SettingsModel.shared
    @State private var historyStore: HistoryStore
    @State private var pasteboardMonitor = PasteboardMonitor()
    @State private var ignoreListManager: IgnoreListManager
    @State private var shortcutController = ShortcutController()
    @State private var viewModel: HistoryViewModel
    @State private var panelController: PanelController

    init() {
        let settings = SettingsModel.shared
        let historyStore = HistoryStore(settings: settings)
        let pasteboardMonitor = PasteboardMonitor()
        let ignoreListManager = IgnoreListManager(settings: settings)
        let viewModel = HistoryViewModel(
            historyStore: historyStore,
            pasteboardMonitor: pasteboardMonitor,
            ignoreListManager: ignoreListManager
        )
        let panelController = PanelController(viewModel: viewModel, settings: settings)

        _historyStore = State(initialValue: historyStore)
        _ignoreListManager = State(initialValue: ignoreListManager)
        _viewModel = State(initialValue: viewModel)
        _panelController = State(initialValue: panelController)

        appDelegate.viewModel = viewModel
        appDelegate.panelController = panelController
        appDelegate.shortcutController = shortcutController
        appDelegate.settings = settings
    }

    var body: some Scene {
        MenuBarExtra("ClipboardCanvas", systemImage: "clipboard.fill") {
            Text("历史记录: \(viewModel.itemCount) 条")
                .font(.headline)
            Divider()
            Button("显示面板") {
                panelController.toggle()
            }
            .keyboardShortcut("o", modifiers: .command)
            Button("清空历史") {
                viewModel.clearHistory()
            }
            Divider()
            SettingsLink {
                Text("偏好设置...")
            }
            .keyboardShortcut(",", modifiers: .command)
            Divider()
            Button("退出") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }

        Settings {
            SettingsView(settings: settings, ignoreListManager: ignoreListManager)
                .onAppear {
                    // Ensure settings window is interactive
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
    }
}
