# ClipboardCanvas

macOS 原生剪贴板管理器，SwiftUI + AppKit 混合架构。

## 技术栈

| 层级 | 技术 |
|------|------|
| UI | SwiftUI (Settings scene, popover views) |
| 窗口管理 | AppKit NSPanel (浮动/菜单栏/跟随鼠标) |
| 剪贴板 | NSPasteboard 轮询 changeCount |
| 全局快捷键 | KeyboardShortcuts (sindresorhus) |
| 持久化 | UserDefaults + Codable JSON |
| 最低系统 | macOS 14 (Sonoma) |

## 架构

```
ClipboardManager (单例)
 ├─ PasteboardMonitor        // 0.5s 轮询 changeCount
 ├─ HistoryStore             // 内存数组 + 磁盘持久化
 ├─ IgnoreListManager        // 前台 App 过滤
 ├─ ShortcutController       // 全局快捷键注册
 ├─ PanelController          // 悬浮窗生命周期
 └─ ViewModel (Observable)   // 面板数据绑定
```

## 数据流

```
启动 → 注册快捷键 → 开启定时器(0.5s)
  ↓
changeCount 变化 → 获取前台 App → 检查忽略列表
  ↓ (不在忽略列表)
读取 NSPasteboard → 类型判断 → 存入 HistoryStore
  ↓
用户按快捷键 → PanelController 显示窗口 → 加载历史列表
  ↓
按数字键/点击 → 写回剪贴板 → 关闭面板 → CGEvent 模拟 Cmd+V
```

## 目录结构

```
Sources/
 ├─ App/
 │   ├─ ClipboardCanvasApp.swift      // @main, MenuBarExtra
 │   └─ AppDelegate.swift             // NSApplicationDelegate
 ├─ Models/
 │   ├─ ClipboardItem.swift           // 数据模型
 │   └─ SettingsModel.swift           // UserDefaults 包装
 ├─ Services/
 │   ├─ PasteboardMonitor.swift       // 剪贴板轮询
 │   ├─ HistoryStore.swift            // 历史存储
 │   ├─ IgnoreListManager.swift       // 忽略列表
 │   └─ PanelController.swift         // 窗口管理
 ├─ ViewModels/
 │   └─ HistoryViewModel.swift        // 面板数据
 ├─ Views/
 │   ├─ HistoryPanelView.swift        // 主面板
 │   ├─ SettingsView.swift            // 偏好设置
 │   └─ Components/                   // 复用组件
 └─ Extensions/
     └─ NSPasteboard+.swift           // 扩展方法
```

## 开发命令

```bash
# 构建
swift build

# 运行
swift run ClipboardCanvas

# 清理
swift package clean
```

## 开发步骤（按顺序）

| 步骤 | 内容 | 核心文件 |
|------|------|----------|
| 1 | 项目骨架与数据模型 | ClipboardItem, HistoryStore |
| 2 | 剪贴板监听与写入 | PasteboardMonitor |
| 3 | 忽略应用列表 | IgnoreListManager |
| 4 | 全局快捷键 | ShortcutController |
| 5 | 面板 UI | HistoryPanelView, HistoryViewModel |
| 6 | 窗口管理 | PanelController |
| 7 | 粘贴操作 | PanelController (paste action) |
| 8 | 设置界面 | SettingsView |

## 关键约束

- 面板打开时按 1-9/0 直接粘贴，无需 Cmd 修饰
- 失焦自动隐藏面板
- 图片只存缩略图（100px），原数据写临时缓存
- 忽略列表通过 bundleID 匹配前台应用
- 模拟粘贴失败时回退为仅写入剪贴板

## 依赖

| 包 | 用途 |
|----|------|
| KeyboardShortcuts ^2.0 | 全局快捷键绑定与冲突检测 |
