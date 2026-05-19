---
name: clipboard-dev
description: Development conventions and patterns for ScorpionClipboard macOS app. Use when writing SwiftUI views, AppKit bridging code, clipboard monitoring, or data models for this project.
---

## SwiftUI Conventions

- Use `@Observable` macro (macOS 14+), not `ObservableObject`
- `@State` for view-local state only
- `@Environment` for shared service injection
- Use `@Bindable` with `@Observable` for two-way bindings in views
- Keep views under 150 lines; extract row components and complex layouts with `@ViewBuilder`
- `NSViewRepresentable` for AppKit views (e.g. `VisualEffectBlur` wrapping `NSVisualEffectView`)

## AppKit Bridging

- NSPanel with `.nonactivatingPanel` style, `.floating` level
- Set `hidesOnDeactivate = false` — manage visibility manually
- Use `NSWindow.didResignKeyNotification` for auto-hide
- Panel positioning: switch on `settings.panelPosition` (.menuBar, .floatingWindow, .followMouse, .fixedPosition)
- Keyboard handling: dual NSEvent monitors (local + global) in `PanelController.handleKeyEvent()`

## Clipboard Monitoring

- Poll `NSPasteboard.general.changeCount` every 0.5s via Timer
- Type priority: fileURL → tiff → png → rtf → string
- Pause monitoring during paste operations to avoid re-capture
- Generate thumbnails at 100x100 px, store as TIFF Data (`tiffRepresentation`)

## Data Models

- `ClipboardItem`: Codable, Identifiable, Hashable
- Equality by `id` (UUID); dedup via `isDuplicateOf` closure (text/rtf by `briefText`, image by `thumbnailData`, fileURL by `filePath`)
- Dedup by moving existing item to front, not adding duplicate

## Persistence

- History: JSON at `~/Library/Application Support/ScorpionClipboard/history.json`
- Settings: UserDefaults via `@Observable` wrapper (`SettingsModel.shared`)
- Computed property for `storageURL` (not `lazy var` — incompatible with `@Observable`)
- Dual eviction: count limit (`historyLimit`, default 50) + size limit (100 MB)

## Paste Flow

- `HistoryViewModel.pasteItem()` / `restoreFocusAndPaste()`
- Steps: pause monitor → write to pasteboard → activate target app → wait for frontmost (16 attempts × 50ms) → CGEvent Cmd+V
- CGEvent: virtualKey `0x09` (V), `.maskCommand` flag, posted via `postToPid()`
- Fallback: if activation fails, still write to pasteboard

## View Components

- `HistoryPanelView`: 380x500 frame, `VisualEffectBlur` background (.sheet material, .behindWindow blending)
- `ClipboardItemRow`: indexBadge (1-9 circle) + contentPreview + context menu (delete, ignore app)
- `SettingsView`: 450x350, `TabView` with General tab + Ignore tab
- `AppPickerSheet`: 400x400, lists running apps via `IgnoreListManager.runningApps()`

## Testing

- XCTest for model codable, dedup, store operations
- Reset UserDefaults in `setUp()` to avoid test pollution
- 14 test cases in `Tests/CoreTests.swift`
