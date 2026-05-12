---
name: clipboard-dev
description: Development conventions and patterns for ClipboardCanvas macOS app. Use when writing SwiftUI views, AppKit bridging code, clipboard monitoring, or data models for this project.
---

## SwiftUI Conventions

- Use `@Observable` macro (macOS 14+), not `ObservableObject`
- `@State` for view-local state only
- `@Environment` for shared service injection
- Use `@Bindable` with `@Observable` instead of `@ObservedObject`
- Keep views under 150 lines; extract row components and complex layouts with `@ViewBuilder`

## AppKit Bridging

- NSPanel with `.nonactivatingPanel` style, `.floating` level
- Set `hidesOnDeactivate = false` — manage visibility manually
- Use `NSWindow.didResignKeyNotification` for auto-hide
- CGEvent for simulating keyboard input: virtualKey `0x09` (V), `.maskCommand` flag

## Clipboard Monitoring

- Poll `NSPasteboard.general.changeCount` every 0.5s via Timer
- Type priority: fileURL → tiff → png → rtf → string
- Pause monitoring during paste operations to avoid re-capture

## Data Models

- `ClipboardItem`: Codable, Identifiable, Hashable
- Dedup by moving existing item to front, not adding duplicate
- Image thumbnails: 100px, store as PNG Data

## Persistence

- History: JSON at `~/Library/Application Support/ClipboardCanvas/history.json`
- Settings: UserDefaults via `@Observable` wrapper
- Computed property for storageURL (not `lazy var` — incompatible with `@Observable`)

## Testing

- XCTest for model codable, dedup, store operations
- Reset UserDefaults in `setUp()` to avoid test pollution
