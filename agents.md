# Subagent Instructions

When working on this project, follow these role-based guidelines.

## Code Review

When reviewing code changes:
- Check module boundaries respect single responsibility
- Verify `@Observable` usage (not `ObservableObject`)
- Ensure AppKit bridging uses `NSPanel` with `.nonactivatingPanel` style
- Confirm clipboard operations pause monitoring during paste to avoid re-capture
- Validate image thumbnails are 100px, stored as TIFF Data

## Implementation

When implementing new features:
- Follow the step order: Models → Services → ViewModels → Views → Integration
- Keep views under 150 lines; extract row components with `@ViewBuilder`
- Use computed properties (not `lazy var`) for `@Observable` compatibility
- Dedup clipboard items by moving existing item to front, not adding duplicates
- Type priority for clipboard: fileURL → tiff → png → rtf → string

## Debugging

When investigating bugs:
- Check `PasteboardMonitor` timer interval (0.5s) and `changeCount` polling
- Verify ignore list uses `bundleID` matching against frontmost app
- Confirm `CGEvent` uses virtualKey `0x09` (V) with `.maskCommand` flag
- Check `hidesOnDeactivate = false` — visibility is managed manually
- Use `NSWindow.didResignKeyNotification` for auto-hide behavior

## Testing

When running or writing tests:
- Use XCTest for model codable, dedup, and store operations
- Reset `UserDefaults` in `setUp()` to avoid test pollution
- Key scenarios: dedup, max history eviction, ignore list filtering, number key paste, auto-hide on focus loss
