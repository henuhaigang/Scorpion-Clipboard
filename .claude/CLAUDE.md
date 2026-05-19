# ScorpionClipboard

macOS 原生剪贴板管理器，SwiftUI + AppKit 混合架构。Bundle ID: `com.scorpion.ScorpionClipboard`，LSUIElement（无 Dock 图标）。

## 技术栈

| 层级 | 技术 |
|------|------|
| 语言 | Swift 5.9, macOS 14 (Sonoma) |
| UI | SwiftUI (Settings scene, MenuBarExtra, NSViewRepresentable) |
| 窗口管理 | AppKit NSPanel (浮动/菜单栏/跟随鼠标/固定位置) |
| 剪贴板 | NSPasteboard 轮询 changeCount (0.5s) |
| 全局快捷键 | KeyboardShortcuts 2.0.2 (sindresorhus) |
| 持久化 | UserDefaults + Codable JSON |
| 权限 | Accessibility (模拟按键), Apple Events |

## 架构

```
ScorpionClipboardApp     // @main, MenuBarExtra + Settings scene, 依赖注入
  └─ AppDelegate         // NSApplicationDelegate, 状态栏图标, 生命周期
       ↓
PasteboardMonitor        // 0.5s 轮询 changeCount → onNewContent 回调
HistoryStore             // @Observable, 内存数组 + 磁盘 JSON 持久化
IgnoreListManager        // @Observable, 前台 App bundleID 过滤
ShortcutController       // KeyboardShortcuts 注册 togglePanel
PanelController          // NSPanel 创建/定位/键盘事件处理
HistoryViewModel         // @Observable, 面板数据、搜索、粘贴逻辑
SettingsModel            // @Observable, UserDefaults 包装 (单例)
```

## 数据流

```
启动 → AppDelegate 注册快捷键 → PasteboardMonitor 开启定时器(0.5s)
  ↓
changeCount 变化 → PasteboardMonitor.readPasteboard()
  ↓ 类型优先级: fileURL → tiff → png → rtf → string
HistoryViewModel.handleNewContent() → IgnoreListManager 检查
  ↓ (不在忽略列表)
HistoryStore.add() → 去重(移到最前) + 淘汰(数量/100MB) + 持久化
  ↓
用户按快捷键 → PanelController.show() → 创建/显示 NSPanel
  ↓
键盘事件: 1-9/0 直接粘贴, ↑↓ 选择, Enter 粘贴, Delete 删除, Esc 关闭
  ↓
HistoryViewModel.pasteItem() → 写回剪贴板 → 激活目标 App → CGEvent Cmd+V
```

## 目录结构

```
Sources/
 ├─ App/
 │   ├─ ClipboardCanvasApp.swift       // @main, MenuBarExtra, 依赖注入
 │   └─ AppDelegate.swift              // 状态栏, 启动/退出生命周期
 ├─ Models/
 │   ├─ ClipboardItem.swift            // ClipboardType 枚举 + ClipboardItem 模型
 │   └─ SettingsModel.swift            // PanelPosition 枚举 + UserDefaults 包装
 ├─ Services/
 │   ├─ PasteboardMonitor.swift        // Timer 轮询, 类型读取, 缩略图生成
 │   ├─ HistoryStore.swift             // 增删查 + 去重 + 淘汰(数量/大小) + 磁盘持久化
 │   ├─ IgnoreListManager.swift        // bundleID 过滤 + 运行中 App 列表
 │   ├─ ShortcutController.swift       // KeyboardShortcuts 注册
 │   └─ PanelController.swift          // NSPanel 创建/定位/键盘处理
 ├─ ViewModels/
 │   └─ HistoryViewModel.swift         // 搜索(200ms 防抖) + 粘贴 + 前台 App 追踪
 └─ Views/
     ├─ HistoryPanelView.swift          // 主面板 + ClipboardItemRow + VisualEffectBlur
     └─ SettingsView.swift             // TabView(通用/忽略) + AppPickerSheet

Tests/
 └─ CoreTests.swift                    // 14 个 XCTest 用例

Scripts/
 ├─ generate_icon.swift                // 生成 AppIcon.iconset
 └─ build_dmg.swift                    // 构建 .app + 打包 DMG
```

## 核心类型

| 文件 | 类型 | 说明 |
|------|------|------|
| ClipboardItem.swift | `ClipboardType` (enum) | `.text`, `.rtf`, `.image`, `.fileURL` |
| ClipboardItem.swift | `ClipboardItem` (struct) | Codable, Identifiable, Hashable; `isDuplicateOf` 闭包去重 |
| SettingsModel.swift | `PanelPosition` (enum) | `.menuBar`, `.floatingWindow`, `.followMouse`, `.fixedPosition` |
| SettingsModel.swift | `SettingsModel` (@Observable) | `historyLimit`(默认50), `persistAfterRestart`, `ignoredBundleIDs`, `panelPosition` |
| HistoryStore.swift | `HistoryStore` (@Observable) | `add/remove/clear/items/count`; 淘汰: 数量限制 + 100MB 大小限制 |
| PasteboardMonitor.swift | `PasteboardMonitor` | `start/stop/pause/resume`; `onNewContent` 回调; 缩略图 100px TIFF |
| IgnoreListManager.swift | `IgnoreListManager` (@Observable) | `isCurrentAppIgnored/isAppIgnored/runningApps` |
| ShortcutController.swift | `ShortcutController` | `register()` + `onToggle` 回调 |
| PanelController.swift | `PanelController` | `toggle/show/close`; 4 种定位模式; 键盘事件(local+global monitor) |
| HistoryViewModel.swift | `HistoryViewModel` (@Observable) | `filteredItems/pasteItem/deleteItem/savePreviousApp`; 搜索 200ms 防抖 |
| HistoryPanelView.swift | `HistoryPanelView` (View) | 380x500, VisualEffectBlur 背景, ScrollViewReader |
| HistoryPanelView.swift | `ClipboardItemRow` (View) | 序号徽章 + 内容预览 + 右键菜单 |
| SettingsView.swift | `SettingsView` (View) | 450x350, 通用/忽略 两个 Tab |
| SettingsView.swift | `AppPickerSheet` (View) | 运行中 App 选择器 |

## 开发命令

```bash
swift build                  # 构建
swift run ScorpionClipboard  # 运行
swift test                   # 测试 (14 个用例)
swift package clean          # 清理
```

## 关键约束

- 面板打开时按 1-9/0 直接粘贴，无需 Cmd 修饰
- 键盘导航: ↑↓ 选择, Enter 粘贴, Delete 删除, Esc 关闭
- 失焦自动隐藏面板 (`hidesOnDeactivate = false`, 手动管理可见性)
- 图片只存缩略图（100px TIFF），原数据不保留
- 忽略列表通过 bundleID 匹配前台应用
- 粘贴流程: 暂停监听 → 写剪贴板 → 激活目标 App(最多 16 次×50ms) → CGEvent Cmd+V
- CGEvent 使用 `postToPid()` 发送到目标进程，virtualKey `0x09` + `.maskCommand`
- 搜索防抖 200ms (Task.sleep)
- 存储淘汰双重机制: 数量限制(historyLimit) + 大小限制(100MB)
- JSON 持久化路径: `~/Library/Application Support/ScorpionClipboard/history.json`

## 角色分工

| 角色 | 职责 | 对应文件 |
|------|------|----------|
| Architect | 架构设计、模块边界、接口契约、代码审查 | — |
| Backend | PasteboardMonitor、HistoryStore、IgnoreListManager、数据模型 | Services/, Models/ |
| UI | HistoryPanelView、SettingsView、HistoryViewModel、键盘事件 | Views/, ViewModels/ |
| Integration | PanelController、CGEvent、NSStatusItem、快捷键注册 | PanelController.swift, ShortcutController.swift |
| QA | 功能验证、边界测试、性能检查 | Tests/CoreTests.swift |

## 依赖

| 包 | 版本 | 用途 |
|----|------|------|
| KeyboardShortcuts | ^2.0 (resolved 2.0.2) | 全局快捷键绑定与冲突检测 |
