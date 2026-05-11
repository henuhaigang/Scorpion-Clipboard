# ClipboardCanvas

macOS 原生剪贴板管理器，支持历史记录、快速粘贴、忽略应用等功能。

## 功能特性

- 剪贴板历史记录（文本/RTF/图片/文件）
- 全局快捷键呼出面板
- 数字键快速选择粘贴
- 搜索过滤历史记录
- 忽略指定应用
- 菜单栏常驻
- 支持明暗模式

## 技术栈

- Swift 5.9+
- SwiftUI + AppKit
- macOS 14 (Sonoma)
- KeyboardShortcuts

## 安装

```bash
swift build
swift run ClipboardCanvas
```

## 使用

1. 启动后菜单栏出现剪贴板图标
2. 点击图标 → "显示面板" 查看历史
3. 按 `⌃ + 数字键` 快速粘贴
4. 点击条目也可粘贴
5. 偏好设置中可配置快捷键、历史上限等

## 已知问题

- 自动粘贴（模拟 Cmd+V）在部分应用中不生效，需手动按 Cmd+V
- 需要辅助功能权限才能使用自动粘贴

## 许可证

MIT
