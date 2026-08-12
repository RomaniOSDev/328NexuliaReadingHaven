import Foundation

struct SynopsisDraft: Identifiable, Codable, Equatable {
    var id: UUID
    var bookId: UUID?
    var bookTitle: String
    var draftText: String
    var lastEdited: Date

    init(
        id: UUID = UUID(),
        bookId: UUID? = nil,
        bookTitle: String,
        draftText: String,
        lastEdited: Date = Date()
    ) {
        self.id = id
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.draftText = draftText
        self.lastEdited = lastEdited
    }

    static let minimumCharacterCount = 8
}
