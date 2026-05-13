import Foundation

@Observable
final class HistoryStore {
    private(set) var items: [ClipboardItem] = []

    private let settings: SettingsModel
    private let fileManager = FileManager.default

    private var storageURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ClipboardCanvas", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json")
    }

    init(settings: SettingsModel = .shared) {
        self.settings = settings
        if settings.persistAfterRestart {
            loadFromDisk()
        }
    }

    func add(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { item.isDuplicateOf($0) }) {
            items.remove(at: index)
        }
        items.insert(item, at: 0)
        evictIfNeeded()
        saveToDisk()
    }

    func remove(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index)
        saveToDisk()
    }

    func clear() {
        items.removeAll()
        saveToDisk()
    }

    var count: Int { items.count }

    private func evictIfNeeded() {
        while items.count > settings.historyLimit {
            items.removeLast()
        }
    }

    private func evictBySizeIfNeeded() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let maxSize: Int = 1 * 1024 * 1024
        var data = (try? encoder.encode(items)) ?? Data()
        while data.count > maxSize, !items.isEmpty {
            items.removeLast()
            if let updatedData = try? encoder.encode(items) {
                data = updatedData
            } else {
                break
            }
        }
    }

    private func saveToDisk() {
        guard settings.persistAfterRestart else { return }
        evictBySizeIfNeeded()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    private func loadFromDisk() {
        guard fileManager.fileExists(atPath: storageURL.path) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: storageURL),
              let loaded = try? decoder.decode([ClipboardItem].self, from: data) else { return }
        items = Array(loaded.prefix(settings.historyLimit))
    }
}
