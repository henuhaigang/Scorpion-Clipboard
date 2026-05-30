import AppKit
import Foundation

final class PasteboardMonitor {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private var isPaused = false

    var onNewContent: ((ClipboardItem) -> Void)?

    func start() {
        lastChangeCount = pasteboard.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func pause() {
        isPaused = true
    }

    func resume() {
        isPaused = false
        lastChangeCount = pasteboard.changeCount
    }

    private func checkForChanges() {
        guard !isPaused else { return }
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if let item = readPasteboard() {
            onNewContent?(item)
        }
    }

    private func readPasteboard() -> ClipboardItem? {
        guard let types = pasteboard.types else { return nil }

        if types.contains(.fileURL), let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL], let url = urls.first {
            return ClipboardItem(
                type: .fileURL,
                briefText: url.lastPathComponent,
                filePath: url.path
            )
        }

        if types.contains(.tiff), let data = pasteboard.data(forType: .tiff) {
            let thumbnail = generateThumbnail(from: data)
            return ClipboardItem(
                type: .image,
                briefText: "Image",
                rawData: data,
                thumbnailData: thumbnail
            )
        }

        if types.contains(.png), let data = pasteboard.data(forType: .png) {
            let thumbnail = generateThumbnail(from: data)
            return ClipboardItem(
                type: .image,
                briefText: "Image",
                rawData: data,
                thumbnailData: thumbnail
            )
        }

        if types.contains(.rtf), let data = pasteboard.data(forType: .rtf) {
            let plainText: String
            if let attributed = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
                plainText = attributed.string
            } else {
                plainText = pasteboard.string(forType: .string) ?? ""
            }
            guard !plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            let fullTextData = plainText.data(using: .utf8)
            return ClipboardItem(
                type: .rtf,
                briefText: String(plainText.prefix(200)),
                rawData: fullTextData,
                rtfData: data
            )
        }

        if types.contains(.string), let text = pasteboard.string(forType: .string), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let fullTextData = text.data(using: .utf8)
            return ClipboardItem(
                type: .text,
                briefText: String(text.prefix(200)),
                rawData: fullTextData
            )
        }

        return nil
    }

    private func generateThumbnail(from imageData: Data) -> Data? {
        guard let image = NSImage(data: imageData) else { return nil }
        let targetSize = NSSize(width: 100, height: 100)
        let thumbnail = NSImage(size: targetSize)
        thumbnail.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: targetSize),
                   from: .zero,
                   operation: .copy,
                   fraction: 1.0)
        thumbnail.unlockFocus()
        return thumbnail.tiffRepresentation
    }
}
