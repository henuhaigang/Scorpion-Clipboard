# Subagent Instructions

When working on this project, follow these role-based guidelines.

## Code Review

When reviewing code changes:
- Check module boundaries respect single responsibility
- Verify `@Observable` usage (not `ObservableObject`); confirm no `lazy var` in `@Observable` classes
- Ensure AppKit bridging uses `NSPanel` with `.nonactivatingPanel` style, `.floating` level, `hidesOnDeactivate = false`
- Confirm clipboard operations pause monitoring during paste to avoid re-capture
- Validate image thumbnails are 100px, stored as TIFF Data
- Verify dedup uses `isDuplicateOf` closure (text/rtf by `briefText`, image by `thumbnailData`, fileURL by `filePath`)
- Check CGEvent uses `postToPid()` with virtualKey `0x09` + `.maskCommand`

## Implementation

When implementing new features:
- Follow the step order: Models → Services → ViewModels → Views → Integration
- Keep views under 150 lines; extract row components with `@ViewBuilder`
- Use computed properties (not `lazy var`) for `@Observable` compatibility
- Dedup clipboard items by moving existing item to front, not adding duplicates
- Type priority for clipboard: fileURL → tiff → png → rtf → string
- Use `VisualEffectBlur` (NSViewRepresentable) for vibrancy backgrounds
- Settings use `SettingsModel.shared` singleton backed by `UserDefaults.standard`

## Debugging

When investigating bugs:
- Check `PasteboardMonitor` timer interval (0.5s) and `changeCount` polling
- Verify ignore list uses `bundleID` matching against frontmost app (`NSWorkspace.shared.frontmostApplication`)
- Confirm `CGEvent` uses virtualKey `0x09` (V) with `.maskCommand` flag, posted via `postToPid()`
- Check `hidesOnDeactivate = false` — visibility is managed manually in `PanelController`
- Use `NSWindow.didResignKeyNotification` for auto-hide behavior
- Paste reliability: `pasteItem()` waits up to 16 attempts × 50ms for target app to become frontmost
- Storage eviction has two mechanisms: count limit (`historyLimit`) and size limit (100 MB)
- Search uses 200ms debounce via `Task.sleep`; cancel previous task on new input

## Testing

When running or writing tests:
- Use XCTest in `Tests/CoreTests.swift` (14 test methods)
- Reset `UserDefaults` in `setUp()` to avoid test pollution
- Key scenarios: codable round-trip, dedup (text/image/file), settings defaults, history store add/remove/clear/eviction, ignore list add/remove/check
- Run with `swift test`
