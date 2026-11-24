import SwiftUI

struct DraftListView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showAddSheet = false
    @State private var editingDraft: SynopsisDraft?
    @State private var pendingUndo: SynopsisDraft?
    @State private var showUndoSnackbar = false

    private var sortedDrafts: [SynopsisDraft] {
        store.drafts.sorted { $0.lastEdited > $1.lastEdited }
    }

    var body: some View {
        JournalPage {
            JournalHeading(title: "Drafts", detail: "\(store.draftCount) \(store.draftCount == 1 ? "draft" : "drafts")")

            if sortedDrafts.isEmpty {
                AppEmptyState(
                    artwork: "DraftBookplate",
                    title: "Room for a first thought",
                    message: "Start a note here, or keep working on the draft linked to a synopsis.",
                    actionTitle: "New Draft",
                    action: { showAddSheet = true }
                )
            } else {
                Button {
                    showAddSheet = true
                } label: {
                    Label("New Draft", systemImage: "plus")
                }
                .buttonStyle(PressButtonStyle())

                LazyVStack(spacing: 0) {
                    JournalRule()
                    ForEach(sortedDrafts) { draft in
                        Button {
                            editingDraft = draft
                        } label: {
                            JournalEntryRow(title: draft.bookTitle, excerpt: draft.draftText, updated: draft.lastEdited) {
                                if draft.bookId != nil {
                                    Label("Linked to a synopsis", systemImage: "link")
                                        .font(.caption)
                                        .foregroundStyle(AppPalette.accent)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Delete", role: .destructive) { deleteDraft(draft) }
                        }
                        .accessibilityAction(named: "Delete") { deleteDraft(draft) }
                        JournalRule()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showUndoSnackbar, pendingUndo != nil {
                UndoSnackbar(message: "Draft removed") {
                    if let draft = pendingUndo {
                        _ = store.restoreDraft(draft)
                    }
                    pendingUndo = nil
                    showUndoSnackbar = false
                }
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            DraftEditorSheet(mode: .create) { title, text, bookId in
                store.addDraft(bookTitle: title, draftText: text, bookId: bookId) != nil
            }
            .appSheetChrome()
        }
        .sheet(item: $editingDraft) { draft in
            DraftEditorSheet(mode: .edit(draft)) { title, text, bookId in
                store.updateDraft(draft, bookTitle: title, draftText: text, bookId: bookId)
            }
            .appSheetChrome()
        }
    }

    private func deleteDraft(_ draft: SynopsisDraft) {
        if let removed = store.deleteDraft(draft) {
            pendingUndo = removed
            showUndoSnackbar = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                if pendingUndo?.id == removed.id {
                    pendingUndo = nil
                    showUndoSnackbar = false
                }
            }
        }
    }
}
