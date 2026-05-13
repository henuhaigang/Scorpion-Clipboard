# Fix: Ctrl+数字键触发粘贴

## 问题

`PanelController.handleKeyEvent()` 只匹配无修饰键的数字键，`Ctrl+数字` 被忽略导致面板关闭但不执行粘贴。

## 修改

**文件**: `Sources/Services/PanelController.swift:73-74`

```swift
// Before:
        // Number keys 1-9, 0 without modifier (when panel is open)
        if flags.isEmpty || flags == .numericPad,

// After:
        // Number keys 1-9, 0 with Ctrl modifier (when panel is open)
        if flags == .control || flags.isEmpty || flags == .numericPad,
```

## 验证

```bash
swift build
```
