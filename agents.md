# ScorpionClipboard 开发代理定义

## 代理总览

| 代理 | 职责 | 触发条件 |
|------|------|----------|
| Architect | 架构设计与代码审查 | 新模块设计、重大改动 |
| Backend | 数据层与服务实现 | HistoryStore, PasteboardMonitor |
| UI | SwiftUI 视图与交互 | Views, ViewModels |
| Integration | AppKit 桥接与系统集成 | PanelController, CGEvent |
| QA | 测试与验证 | 每个步骤完成后 |

---

## Architect

**职责**
- 审核模块边界和依赖方向
- 确保单一职责原则
- 定义接口契约（protocol）
- 代码风格一致性

**技能要求**
- SwiftUI 状态管理（@Observable, @Environment）
- AppKit 窗口生命周期
- macOS 安全模型（Accessibility 权限）

**交付物**
- 模块接口定义
- 依赖注入方案
- 代码审查意见

---

## Backend

**职责**
- 实现 PasteboardMonitor（Timer 轮询）
- 实现 HistoryStore（内存 + 磁盘持久化）
- 实现 IgnoreListManager
- 数据模型 Codable 序列化

**技能要求**
- NSPasteboard API
- Timer 与 RunLoop
- UserDefaults + JSON 编解码
- OrderedSet 去重逻辑

**交付物**
- `ClipboardItem.swift` - 数据模型
- `HistoryStore.swift` - 存储服务
- `PasteboardMonitor.swift` - 监听服务
- `IgnoreListManager.swift` - 过滤服务

**关键接口**
```swift
protocol HistoryStoring {
    func add(_ item: ClipboardItem)
    func remove(at index: Int)
    var items: [ClipboardItem] { get }
    var count: Int { get }
}

protocol PasteboardMonitoring {
    func start()
    func stop()
    var onChange: ((ClipboardItem) -> Void)? { get set }
}
```

---

## UI

**职责**
- HistoryPanelView 主面板
- SettingsView 偏好设置
- HistoryViewModel 数据绑定
- 搜索过滤与键盘事件

**技能要求**
- SwiftUI List 与 ForEach
- @Observable 宏
- .onKeyPress 事件处理
- .popover tooltip
- SwiftUI Settings scene

**交付物**
- `HistoryPanelView.swift` - 主面板视图
- `SettingsView.swift` - 设置界面
- `HistoryViewModel.swift` - 视图模型
- `ClipboardItemRow.swift` - 列表行组件

**UI 规范**
- 跟随系统明暗模式
- 图片缩略图 100px
- 文本截断 50 字符
- 搜索框实时过滤（防抖 200ms）

---

## Integration

**职责**
- PanelController 窗口管理
- NSPanel 无标题栏浮动
- CGEvent 模拟 Cmd+V
- NSStatusItem 菜单栏图标
- 快捷键注册与回调

**技能要求**
- NSPanel / NSWindow 配置
- CGEvent 键盘模拟
- NSWorkspace 前台应用监听
- KeyboardShortcuts 库集成
- NSStatusItem 菜单

**交付物**
- `PanelController.swift` - 窗口控制器
- `ShortcutController.swift` - 快捷键管理
- `AppDelegate.swift` - 应用代理

**权限需求**
- Accessibility 权限（模拟按键）
- 可能需要 Screen Recording（读取其他 App 剪贴板）

---

## QA

**职责**
- 验证每步功能完整性
- 边界条件测试
- 性能基准检查

**测试场景**

| 场景 | 预期 |
|------|------|
| 复制纯文本 | 历史记录新增一条 |
| 复制图片 | 生成缩略图，历史新增 |
| 连续复制相同内容 | 去重，不重复添加 |
| 历史超过上限 | 自动淘汰最旧条目 |
| 在忽略应用中复制 | 不记录 |
| 按cmd+数字键 1 | 粘贴第 1 条到前台 |
| 面板失焦 | 自动隐藏 |
| 自动执行cmd+v  ｜ 自动粘贴 ｜
| 重启后 | 根据设置决定是否保留历史 |
