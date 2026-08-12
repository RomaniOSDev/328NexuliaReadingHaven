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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text(current.bookTitle)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            Spacer()
                            StatusBadgeView(status: current.chapterStatus)
                        }
                        Text("Chapter \(current.chapter)")
                            .font(.headline)
                            .foregroundStyle(Color("AppAccent"))
                        Text(current.lastEdited, style: .date)
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .surfaceCard()

                    Text(current.synopsisText)
                        .font(.body)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .surfaceCard()

                    if let draft = linkedDraft {
                        Button {
                            linkedDraftToEdit = draft
                        } label: {
                            Label("Open linked draft", systemImage: "link")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color("AppAccent"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .surfaceCard()
                    }
                }
                .padding(16)
            }
            .appScreenBackground()
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
            }
            .sheet(item: $linkedDraftToEdit) { draft in
                DraftEditorSheet(mode: .edit(draft)) { title, text, bookId in
                    store.updateDraft(draft, bookTitle: title, draftText: text, bookId: bookId)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
