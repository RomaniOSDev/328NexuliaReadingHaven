import Foundation

enum ChapterStatus: String, Codable, CaseIterable, Identifiable {
    case inProgress
    case done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inProgress: return "In progress"
        case .done: return "Done"
        }
    }
}

struct BookSynopsis: Identifiable, Codable, Equatable {
    var id: UUID
    var bookTitle: String
    var chapter: String
    var synopsisText: String
    var chapterStatus: ChapterStatus
    var lastEdited: Date

    init(
        id: UUID = UUID(),
        bookTitle: String,
        chapter: String,
        synopsisText: String,
        chapterStatus: ChapterStatus = .inProgress,
        lastEdited: Date = Date()
    ) {
        self.id = id
        self.bookTitle = bookTitle
        self.chapter = chapter
        self.synopsisText = synopsisText
        self.chapterStatus = chapterStatus
        self.lastEdited = lastEdited
    }

    enum CodingKeys: String, CodingKey {
        case id, bookTitle, chapter, synopsisText, chapterStatus, lastEdited
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        bookTitle = try container.decode(String.self, forKey: .bookTitle)
        chapter = try container.decode(String.self, forKey: .chapter)
        synopsisText = try container.decode(String.self, forKey: .synopsisText)
        chapterStatus = try container.decodeIfPresent(ChapterStatus.self, forKey: .chapterStatus) ?? .inProgress
        lastEdited = try container.decode(Date.self, forKey: .lastEdited)
    }

    var excerpt: String {
        let trimmed = synopsisText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 120 else { return trimmed }
        let index = trimmed.index(trimmed.startIndex, offsetBy: 120)
        return String(trimmed[..<index]) + "…"
    }
}
