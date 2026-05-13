import XCTest
@testable import ScorpionClipboard

final class CoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let settings = SettingsModel()
        settings.historyLimit = 50
        settings.persistAfterRestart = true
        settings.ignoredBundleIDs = []
        settings.panelPosition = .floatingWindow
    }

    // MARK: - ClipboardItem

    func testClipboardItemCreation() {
        let item = ClipboardItem(type: .text, briefText: "Hello")
        XCTAssertEqual(item.type, .text)
        XCTAssertEqual(item.briefText, "Hello")
        XCTAssertNotNil(item.id)
        XCTAssertNotNil(item.timestamp)
    }

    func testClipboardItemTypes() {
        let text = ClipboardItem(type: .text, briefText: "text")
        let rtf = ClipboardItem(type: .rtf, briefText: "rtf")
        let image = ClipboardItem(type: .image, briefText: "image")
        let file = ClipboardItem(type: .fileURL, briefText: "file")

        XCTAssertEqual(text.type, .text)
        XCTAssertEqual(rtf.type, .rtf)
        XCTAssertEqual(image.type, .image)
        XCTAssertEqual(file.type, .fileURL)
    }

    // MARK: - Deduplication

    func testTextDeduplication() {
        let item1 = ClipboardItem(type: .text, briefText: "Same")
        let item2 = ClipboardItem(type: .text, briefText: "Same")
        let item3 = ClipboardItem(type: .text, briefText: "Different")

        XCTAssertTrue(item1.isDuplicateOf(item2))
        XCTAssertFalse(item1.isDuplicateOf(item3))
    }

    func testImageDeduplication() {
        let data = Data([0x01, 0x02])
        let item1 = ClipboardItem(type: .image, briefText: "img", thumbnailData: data)
        let item2 = ClipboardItem(type: .image, briefText: "img", thumbnailData: data)
        let item3 = ClipboardItem(type: .image, briefText: "img", thumbnailData: Data([0x03]))

        XCTAssertTrue(item1.isDuplicateOf(item2))
        XCTAssertFalse(item1.isDuplicateOf(item3))
    }

    func testFileDeduplication() {
        let item1 = ClipboardItem(type: .fileURL, briefText: "file", filePath: "/tmp/test.txt")
        let item2 = ClipboardItem(type: .fileURL, briefText: "file", filePath: "/tmp/test.txt")
        let item3 = ClipboardItem(type: .fileURL, briefText: "file", filePath: "/tmp/other.txt")

        XCTAssertTrue(item1.isDuplicateOf(item2))
        XCTAssertFalse(item1.isDuplicateOf(item3))
    }

    // MARK: - SettingsModel

    func testSettingsDefaults() {
        let settings = SettingsModel()
        XCTAssertTrue(settings.persistAfterRestart)
        XCTAssertEqual(settings.panelPosition, .floatingWindow)
        XCTAssertTrue(settings.ignoredBundleIDs.isEmpty)
    }

    func testSettingsHistoryLimit() {
        let settings = SettingsModel()
        let original = settings.historyLimit
        settings.historyLimit = 30
        XCTAssertEqual(settings.historyLimit, 30)
        settings.historyLimit = original
    }

    func testSettingsIgnoreList() {
        let settings = SettingsModel()
        settings.ignoredBundleIDs = []
        settings.addIgnoredApp("com.test.app")
        XCTAssertTrue(settings.ignoredBundleIDs.contains("com.test.app"))
        settings.removeIgnoredApp("com.test.app")
        XCTAssertFalse(settings.ignoredBundleIDs.contains("com.test.app"))
    }

    // MARK: - HistoryStore

    func testHistoryStoreAddAndCount() {
        let settings = SettingsModel()
        settings.persistAfterRestart = false
        let store = HistoryStore(settings: settings)

        XCTAssertEqual(store.count, 0)
        store.add(ClipboardItem(type: .text, briefText: "First"))
        XCTAssertEqual(store.count, 1)
        store.add(ClipboardItem(type: .text, briefText: "Second"))
        XCTAssertEqual(store.count, 2)
    }

    func testHistoryStoreDedup() {
        let settings = SettingsModel()
        settings.persistAfterRestart = false
        let store = HistoryStore(settings: settings)

        store.add(ClipboardItem(type: .text, briefText: "Same"))
        store.add(ClipboardItem(type: .text, briefText: "Other"))
        store.add(ClipboardItem(type: .text, briefText: "Same"))

        XCTAssertEqual(store.count, 2)
        XCTAssertEqual(store.items[0].briefText, "Same")
    }

    func testHistoryStoreEviction() {
        let settings = SettingsModel()
        settings.persistAfterRestart = false
        settings.historyLimit = 3
        let store = HistoryStore(settings: settings)

        for i in 1...5 {
            store.add(ClipboardItem(type: .text, briefText: "Item \(i)"))
        }

        XCTAssertEqual(store.count, 3)
        XCTAssertEqual(store.items[0].briefText, "Item 5")
        XCTAssertEqual(store.items[2].briefText, "Item 3")
    }

    func testHistoryStoreRemove() {
        let settings = SettingsModel()
        settings.persistAfterRestart = false
        let store = HistoryStore(settings: settings)

        store.add(ClipboardItem(type: .text, briefText: "A"))
        store.add(ClipboardItem(type: .text, briefText: "B"))
        // items = ["B", "A"], removing index 0 removes "B"
        store.remove(at: 0)

        XCTAssertEqual(store.count, 1)
        XCTAssertEqual(store.items[0].briefText, "A")
    }

    func testHistoryStoreClear() {
        let settings = SettingsModel()
        settings.persistAfterRestart = false
        let store = HistoryStore(settings: settings)

        store.add(ClipboardItem(type: .text, briefText: "A"))
        store.clear()
        XCTAssertEqual(store.count, 0)
    }

    // MARK: - Codable

    func testClipboardItemCodable() throws {
        let original = ClipboardItem(type: .text, briefText: "Roundtrip")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(ClipboardItem.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.briefText, original.briefText)
        XCTAssertEqual(decoded.type, original.type)
    }

    // MARK: - IgnoreListManager

    func testIgnoreListManager() {
        let settings = SettingsModel()
        settings.ignoredBundleIDs = []
        let manager = IgnoreListManager(settings: settings)

        XCTAssertFalse(manager.isAppIgnored(bundleID: "com.test.app"))
        manager.addIgnoredApp("com.test.app")
        XCTAssertTrue(manager.isAppIgnored(bundleID: "com.test.app"))
        manager.removeIgnoredApp("com.test.app")
        XCTAssertFalse(manager.isAppIgnored(bundleID: "com.test.app"))
    }
}
