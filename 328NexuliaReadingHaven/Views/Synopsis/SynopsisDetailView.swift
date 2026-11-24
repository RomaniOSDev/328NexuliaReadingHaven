import SwiftUI

struct SynopsisDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let synopsis: BookSynopsis
    @State private var showEditSheet = false
    @State private var linkedDraftToEdit: SynopsisDraft?

    private var current: BookSynopsis {
        store.synopsis(for: synopsis.id) ?? synopsis
    }

    private var linkedDraft: SynopsisDraft? {
        store.drafts(forBookId: current.id).sorted { $0.lastEdited > $1.lastEdited }.first
    }

    var body: some View {
        NavigationStack {
            JournalPage {
                VStack(alignment: .leading, spacing: 8) {
                    Text(current.bookTitle)
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(AppPalette.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Chapter \(current.chapter)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppPalette.ink)
                    StatusBadgeView(status: current.chapterStatus)
                    Text(current.lastEdited, style: .date)
                        .font(.caption)
                        .foregroundStyle(AppPalette.muted)
                }

                JournalRule()

                Text(current.synopsisText)
                    .font(.body)
                    .foregroundStyle(AppPalette.ink)
                    .lineSpacing(5)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let draft = linkedDraft {
                    Button {
                        linkedDraftToEdit = draft
                    } label: {
                        Label("Open linked draft", systemImage: "link")
                    }
                    .buttonStyle(PressButtonStyle(kind: .secondary))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Edit") { showEditSheet = true }
                        .foregroundStyle(Color("AppAccent"))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            .sheet(isPresented: $showEditSheet) {
                SynopsisEditorSheet(mode: .edit(current)) { title, chapter, text, status in
                    store.updateSynopsis(
                        current,
                        bookTitle: title,
                        chapter: chapter,
                        synopsisText: text,
                        chapterStatus: status
                    )
                }
                .appSheetChrome()
            }
            .sheet(item: $linkedDraftToEdit) { draft in
                DraftEditorSheet(mode: .edit(draft)) { title, text, bookId in
                    store.updateDraft(draft, bookTitle: title, draftText: text, bookId: bookId)
                }
                .appSheetChrome()
            }
        }
    }
}
