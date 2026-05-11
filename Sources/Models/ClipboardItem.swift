import Foundation

enum ClipboardType: String, Codable, CaseIterable {
    case text
    case rtf
    case image
    case fileURL
}

struct ClipboardItem: Codable, Identifiable, Hashable {
    let id: UUID
    let type: ClipboardType
    let timestamp: Date
    let briefText: String
    let rawData: Data?
    let thumbnailData: Data?
    let filePath: String?

    init(
        id: UUID = UUID(),
        type: ClipboardType,
        timestamp: Date = Date(),
        briefText: String,
        rawData: Data? = nil,
        thumbnailData: Data? = nil,
        filePath: String? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.briefText = briefText
        self.rawData = rawData
        self.thumbnailData = thumbnailData
        self.filePath = filePath
    }
}

extension ClipboardItem {
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var isDuplicateOf: (ClipboardItem) -> Bool {
        { other in
            switch self.type {
            case .text, .rtf:
                return self.briefText == other.briefText
            case .image:
                return self.thumbnailData == other.thumbnailData
            case .fileURL:
                return self.filePath == other.filePath
            }
        }
    }
}
