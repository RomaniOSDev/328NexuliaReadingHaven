import Foundation
import Combine

final class AppDataStore: ObservableObject {
    @Published private(set) var synopses: [BookSynopsis] = []
    @Published private(set) var drafts: [SynopsisDraft] = []

    private let synopsesKey = "nexulia.synopses.v1"
    private let draftsKey = "nexulia.drafts.v1"

    init() {
        load()
    }

    var synopsisCount: Int { synopses.count }
    var draftCount: Int { drafts.count }

    var dashboardItems: [BookSynopsis] {
        synopses.sorted {
            $0.bookTitle.localizedCaseInsensitiveCompare($1.bookTitle) == .orderedAscending
        }
    }

    var recentlyEditedSynopses: [BookSynopsis] {
        synopses.sorted { $0.lastEdited > $1.lastEdited }
    }

    var doneSynopsisCount: Int {
        synopses.filter { $0.chapterStatus == .done }.count
    }

    var inProgressSynopsisCount: Int {
        synopses.filter { $0.chapterStatus == .inProgress }.count
    }

    var linkedDraftCount: Int {
        drafts.filter { $0.bookId != nil }.count
    }

    /// Edits per day for the last 7 calendar days (synopses + drafts by `lastEdited`).
    var activityLast7Days: [(day: Date, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (0..<7).compactMap { offset -> Date? in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }.reversed()

        return days.map { day in
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let synopsisHits = synopses.filter { $0.lastEdited >= day && $0.lastEdited < next }.count
            let draftHits = drafts.filter { $0.lastEdited >= day && $0.lastEdited < next }.count
            return (day, synopsisHits + draftHits)
        }
    }

    /// Top books by synopsis count (max 6).
    var topBooksBySynopsisCount: [(title: String, count: Int)] {
        Dictionary(grouping: synopses, by: { $0.bookTitle.trimmingCharacters(in: .whitespacesAndNewlines) })
            .map { (title: $0.key.isEmpty ? "Untitled" : $0.key, count: $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return lhs.count > rhs.count
            }
            .prefix(6)
            .map { $0 }
    }

    func synopsis(for id: UUID) -> BookSynopsis? {
        synopses.first { $0.id == id }
    }

    func draft(for id: UUID) -> SynopsisDraft? {
        drafts.first { $0.id == id }
    }

    func drafts(forBookId bookId: UUID) -> [SynopsisDraft] {
        drafts.filter { $0.bookId == bookId }
    }

    @discardableResult
    func addSynopsis(
        bookTitle: String,
        chapter: String,
        synopsisText: String,
        chapterStatus: ChapterStatus = .inProgress
    ) -> BookSynopsis? {
        let title = bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let chap = chapter.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = synopsisText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !chap.isEmpty, !body.isEmpty else { return nil }

        let synopsis = BookSynopsis(
            bookTitle: title,
            chapter: chap,
            synopsisText: body,
            chapterStatus: chapterStatus
        )
        synopses.append(synopsis)
        ensureLinkedDraft(for: synopsis)
        persist()
        return synopsis
    }

    @discardableResult
    func updateSynopsis(
        _ synopsis: BookSynopsis,
        bookTitle: String,
        chapter: String,
        synopsisText: String,
        chapterStatus: ChapterStatus
    ) -> Bool {
        let title = bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let chap = chapter.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = synopsisText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !chap.isEmpty, !body.isEmpty else { return false }
        guard let index = synopses.firstIndex(where: { $0.id == synopsis.id }) else { return false }

        var updated = synopsis
        updated.bookTitle = title
        updated.chapter = chap
        updated.synopsisText = body
        updated.chapterStatus = chapterStatus
        updated.lastEdited = Date()
        synopses[index] = updated
        ensureLinkedDraft(for: updated)
        persist()
        return true
    }

    @discardableResult
    func deleteSynopsis(_ synopsis: BookSynopsis) -> (BookSynopsis, [SynopsisDraft])? {
        guard synopses.contains(where: { $0.id == synopsis.id }) else { return nil }
        let linked = drafts.filter { $0.bookId == synopsis.id }
        synopses.removeAll { $0.id == synopsis.id }
        drafts.removeAll { $0.bookId == synopsis.id }
        persist()
        return (synopsis, linked)
    }

    @discardableResult
    func restoreSynopsis(_ synopsis: BookSynopsis, linkedDrafts: [SynopsisDraft] = []) -> Bool {
        guard !synopses.contains(where: { $0.id == synopsis.id }) else { return false }
        synopses.append(synopsis)
        for draft in linkedDrafts where !drafts.contains(where: { $0.id == draft.id }) {
            drafts.append(draft)
        }
        persist()
        return true
    }

    @discardableResult
    func addDraft(bookTitle: String, draftText: String, bookId: UUID? = nil) -> SynopsisDraft? {
        let title = bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, text.count >= SynopsisDraft.minimumCharacterCount else { return nil }

        let draft = SynopsisDraft(bookId: bookId, bookTitle: title, draftText: text)
        drafts.append(draft)
        persist()
        return draft
    }

    @discardableResult
    func updateDraft(_ draft: SynopsisDraft, bookTitle: String, draftText: String, bookId: UUID? = nil) -> Bool {
        let title = bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, text.count >= SynopsisDraft.minimumCharacterCount else { return false }
        guard let index = drafts.firstIndex(where: { $0.id == draft.id }) else { return false }

        var updated = draft
        updated.bookTitle = title
        updated.draftText = text
        updated.bookId = bookId
        updated.lastEdited = Date()
        drafts[index] = updated
        persist()
        return true
    }

    @discardableResult
    func deleteDraft(_ draft: SynopsisDraft) -> SynopsisDraft? {
        guard drafts.contains(where: { $0.id == draft.id }) else { return nil }
        drafts.removeAll { $0.id == draft.id }
        persist()
        return draft
    }

    @discardableResult
    func restoreDraft(_ draft: SynopsisDraft) -> Bool {
        guard !drafts.contains(where: { $0.id == draft.id }) else { return false }
        drafts.append(draft)
        persist()
        return true
    }

    @discardableResult
    func promoteDraftToSynopsis(_ draft: SynopsisDraft, chapter: String = "1") -> BookSynopsis? {
        let title = draft.bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = draft.draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let chap = chapter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !chap.isEmpty, !body.isEmpty else { return nil }

        let synopsis = BookSynopsis(
            bookTitle: title,
            chapter: chap,
            synopsisText: body,
            chapterStatus: .inProgress
        )
        synopses.append(synopsis)

        if let index = drafts.firstIndex(where: { $0.id == draft.id }) {
            drafts[index].bookId = synopsis.id
            drafts[index].bookTitle = synopsis.bookTitle
            drafts[index].draftText = body
            drafts[index].lastEdited = Date()
        } else {
            ensureLinkedDraft(for: synopsis)
        }
        persist()
        return synopsis
    }

    func resetAllData() {
        synopses = []
        drafts = []
        persist()
    }

    /// Creates a linked draft only when missing; never overwrites user draft text.
    private func ensureLinkedDraft(for synopsis: BookSynopsis) {
        if let index = drafts.firstIndex(where: { $0.bookId == synopsis.id }) {
            if drafts[index].bookTitle != synopsis.bookTitle {
                drafts[index].bookTitle = synopsis.bookTitle
                drafts[index].lastEdited = Date()
            }
            return
        }

        let seed = "Draft notes for \(synopsis.chapter): \(synopsis.synopsisText)"
        let draftBody: String
        if seed.trimmingCharacters(in: .whitespacesAndNewlines).count >= SynopsisDraft.minimumCharacterCount {
            draftBody = String(seed.prefix(280))
        } else {
            draftBody = "Working draft linked to \(synopsis.bookTitle)."
        }

        let draft = SynopsisDraft(
            bookId: synopsis.id,
            bookTitle: synopsis.bookTitle,
            draftText: draftBody.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        drafts.append(draft)
    }

    private func load() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: synopsesKey),
           let decoded = try? decoder.decode([BookSynopsis].self, from: data) {
            synopses = decoded
        }
        if let data = UserDefaults.standard.data(forKey: draftsKey),
           let decoded = try? decoder.decode([SynopsisDraft].self, from: data) {
            drafts = decoded
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(synopses) {
            UserDefaults.standard.set(data, forKey: synopsesKey)
        }
        if let data = try? encoder.encode(drafts) {
            UserDefaults.standard.set(data, forKey: draftsKey)
        }
    }
}
