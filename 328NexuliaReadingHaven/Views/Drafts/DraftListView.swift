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
        VStack(spacing: 0) {
            ShelfBannerView(imageName: "imgBookStack")

            if sortedDrafts.isEmpty {
                Spacer()
                Text("No drafts yet")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                Text("Drafts appear when you build synopses or add notes.")
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                Button("New Draft") { showAddSheet = true }
                    .buttonStyle(PrimaryGradientButtonStyle())
                    .padding(.top, 20)
                Spacer()
            } else {
                List {
                    ForEach(sortedDrafts) { draft in
                        Button {
                            editingDraft = draft
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(draft.bookTitle)
                                        .font(.headline)
                                        .foregroundStyle(Color("AppTextPrimary"))
                                    if draft.bookId != nil {
                                        Image(systemName: "link.circle.fill")
                                            .foregroundStyle(Color("AppAccent"))
                                    }
                                }
                                Text(draft.draftText)
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                    .lineLimit(3)
                                Text(draft.lastEdited, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color("AppSurface").opacity(0.6))
                    }
                    .onDelete(perform: deleteDrafts)
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
            }
        }
        .overlay(alignment: .bottom) {
            if showUndoSnackbar, pendingUndo != nil {
                UndoSnackbar(message: "Draft removed") {
                    if let draft = pendingUndo {
                        _ = store.restoreDraft(draft)
                    }
                    pendingUndo = nil
                    showUndoSnackbar = false
                }
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !sortedDrafts.isEmpty {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(18)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color("AppPrimary"), Color("AppAccent")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: Color("AppPrimary").opacity(0.35), radius: 10, y: 4)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(24)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            DraftEditorSheet(mode: .create) { title, text, bookId in
                store.addDraft(bookTitle: title, draftText: text, bookId: bookId) != nil
            }
        }
        .sheet(item: $editingDraft) { draft in
            DraftEditorSheet(mode: .edit(draft)) { title, text, bookId in
                store.updateDraft(draft, bookTitle: title, draftText: text, bookId: bookId)
            }
        }
    }

    private func deleteDrafts(at offsets: IndexSet) {
        for index in offsets {
            let draft = sortedDrafts[index]
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
}
