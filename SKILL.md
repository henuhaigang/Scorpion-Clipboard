# ClipboardCanvas 开发技能指南

## SwiftUI 开发规范

### 状态管理
- 使用 `@Observable` 宏（macOS 14+），不用 `ObservableObject`
- `@State` 仅用于视图本地状态
- `@Environment` 注入共享服务
- 避免 `@ObservedObject`，改用 `@Bindable` 配合 `@Observable`

```swift
// ✅ 正确
@Observable
class HistoryViewModel {
    var items: [ClipboardItem] = []
    var searchText: String = ""
}

// ✅ 视图中使用
struct HistoryPanelView: View {
    @State var viewModel: HistoryViewModel
    // ...
}
```

### 视图拆分
- 单个视图不超过 150 行
- 列表行抽离为独立组件
- 复杂布局用 `@ViewBuilder` 封装

### 事件处理
- 键盘事件用 `.onKeyPress` (macOS 14+)
- 搜索防抖用 `Task.sleep` + `@Observable` 属性观察

```swift
TextField("搜索", text: $viewModel.searchText)
    .onChange(of: viewModel.searchText) { _, newValue in
        viewModel.debounceSearch(newValue)
    }
```

---

## AppKit 桥接规范

### NSPanel 配置
```swift
let panel = NSPanel(
    contentRect: .zero,
    styleMask: [.nonactivatingPanel, .titled, .closable],
    backing: .buffered,
    defer: true
)
panel.level = .floating
panel.isFloatingPanel = true
panel.hidesOnDeactivate = false  // 我们自己管理隐藏
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
```

### 失焦隐藏
```swift
NotificationCenter.default.addObserver(
    forName: NSWindow.didResignKeyNotification,
    object: panel,
    queue: .main
) { _ in
    panel.orderOut(nil)
}
```

### CGEvent 模拟粘贴
```swift
func simulatePaste() {
    let source = CGEventSource(stateID: .combinedSessionState)
    
    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)  // V key
    keyDown?.flags = [.maskCommand]
    keyDown?.post(tap: .cghidEventTap)
    
    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
    keyUp?.post(tap: .cghidEventTap)
}
```

### NSStatusItem 菜单栏
```swift
let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
statusItem.button?.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "ClipboardCanvas")

let menu = NSMenu()
menu.addItem(NSMenuItem(title: "设置", action: #selector(openSettings), keyEquivalent: ","))
menu.addItem(NSMenuItem.separator())
menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate), keyEquivalent: "q"))
statusItem.menu = menu
```

---

## 剪贴板监听规范

### 轮询实现
```swift
class PasteboardMonitor {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    
    var onNewContent: ((ClipboardItem) -> Void)?
    
    func start() {
        lastChangeCount = pasteboard.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    private func checkForChanges() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        if let item = readPasteboard() {
            onNewContent?(item)
        }
    }
}
```

### 类型判断优先级
1. `.fileURL` → 文件引用
2. `.tiff` / `.png` → 图片
3. `.rtf` / `.rtfd` → 富文本
4. `.string` → 纯文本（兜底）

---

## 数据模型规范

### ClipboardItem
```swift
struct ClipboardItem: Codable, Identifiable, Hashable {
    let id: UUID
    let type: ClipboardType
    let timestamp: Date
    let briefText: String          // 显示用摘要
    let rawData: Data?             // 原始数据（大文件为 nil）
    let thumbnailData: Data?       // 缩略图 PNG
    let filePath: String?          // 文件引用路径
    
    enum ClipboardType: String, Codable {
        case text, rtf, image, fileURL
    }
}
```

### 去重规则
- 文本：`briefText` 相同 → 移到最前，不新增
- 图片：`thumbnailData` 哈希相同 → 移到最前
- 文件：`filePath` 相同 → 移到最前

---

## 持久化规范

### UserDefaults 键名
```swift
enum SettingsKeys {
    static let historyLimit = "historyLimit"          // Int: 10-100
    static let persistAfterRestart = "persistAfterRestart"  // Bool
    static let ignoredBundleIDs = "ignoredBundleIDs"  // [String]
    static let panelPosition = "panelPosition"        // PanelPosition
    static let shortcutKey = "shortcutKey"            // KeyboardShortcuts.Name
}
```

### 磁盘存储
- 历史记录：`~/Library/Application Support/ClipboardCanvas/history.json`
- 图片缓存：`~/Library/Caches/ClipboardCanvas/thumbnails/`
- 启动时清理超过 7 天的缓存

---

## 测试策略

### 单元测试
- `HistoryStore`：添加、删除、去重、淘汰
- `IgnoreListManager`：过滤逻辑
- `ClipboardItem`：Codable 编解码

### 集成测试
- 模拟 `NSPasteboard` 写入 → 验证监听捕获
- 快捷键回调 → 验证面板状态

### 手动测试清单
- [ ] 复制纯文本 → 历史记录
- [ ] 复制图片 → 缩略图显示
- [ ] 数字键粘贴 → 内容正确
- [ ] 搜索过滤 → 实时响应
- [ ] 忽略列表 → 生效
- [ ] 重启保留 → 根据设置
- [ ] 失焦隐藏 → 自动
- [ ] 内存占用 → 无泄漏
