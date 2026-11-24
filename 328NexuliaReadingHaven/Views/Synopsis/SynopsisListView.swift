import SwiftUI

enum LibrarySort: String, CaseIterable, Identifiable {
    case titleAZ
    case recentlyEdited

    var id: String { rawValue }

    var title: String {
        switch self {
        case .titleAZ: return "A–Z"
        case .recentlyEdited: return "Recent"
        }
    }
}

struct SynopsisListView: View {
    @EnvironmentObject private var store: AppDataStore
    @Binding var showAddSheet: Bool
    @State private var selectedSynopsis: BookSynopsis?
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool
    @State private var sort: LibrarySort = .titleAZ
    @State private var pendingUndoSynopsis: BookSynopsis?
    @State private var pendingUndoDrafts: [SynopsisDraft] = []
    @State private var showUndoSnackbar = false

    private var filteredSynopses: [BookSynopsis] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let base: [BookSynopsis]
        switch sort {
        case .titleAZ:
            base = store.synopses.sorted {
                $0.bookTitle.localizedCaseInsensitiveCompare($1.bookTitle) == .orderedAscending
            }
        case .recentlyEdited:
            base = store.synopses.sorted { $0.lastEdited > $1.lastEdited }
        }

        guard !query.isEmpty else { return base }
        return base.filter {
            $0.bookTitle.localizedCaseInsensitiveContains(query)
                || $0.chapter.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        JournalPage {
            JournalHeading(title: "Library", detail: "\(store.synopsisCount) \(store.synopsisCount == 1 ? "synopsis" : "synopses")")
            searchBar

            if store.synopses.isEmpty {
                AppEmptyState(
                    artwork: "LibraryBookplate",
                    title: "Where your reading begins",
                    message: "Save a chapter summary so you can pick up the story later.",
                    actionTitle: "Add Synopsis",
                    action: { showAddSheet = true }
                )
            } else {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add Synopsis", systemImage: "plus")
                }
                .buttonStyle(PressButtonStyle())

                if filteredSynopses.isEmpty {
                    Text("No matches for “\(searchText)”.")
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.muted)
                } else {
                    LazyVStack(spacing: 0) {
                        JournalRule()
                        ForEach(filteredSynopses) { synopsis in
                            Button {
                                selectedSynopsis = synopsis
                            } label: {
                                JournalEntryRow(
                                    title: synopsis.bookTitle,
                                    excerpt: synopsis.excerpt,
                                    updated: synopsis.lastEdited
                                ) {
                                    ViewThatFits(in: .horizontal) {
                                        HStack(spacing: 12) {
                                            chapter(synopsis).fixedSize()
                                            StatusBadgeView(status: synopsis.chapterStatus).fixedSize()
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            chapter(synopsis)
                                            StatusBadgeView(status: synopsis.chapterStatus)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Delete", role: .destructive) { deleteSynopsis(synopsis) }
                            }
                            .accessibilityAction(named: "Delete") { deleteSynopsis(synopsis) }
                            JournalRule()
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showUndoSnackbar, pendingUndoSynopsis != nil {
                UndoSnackbar(message: "Synopsis removed") {
                    if let synopsis = pendingUndoSynopsis {
                        _ = store.restoreSynopsis(synopsis, linkedDrafts: pendingUndoDrafts)
                    }
                    pendingUndoSynopsis = nil
                    pendingUndoDrafts = []
                    showUndoSnackbar = false
                }
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            SynopsisEditorSheet(mode: .create) { title, chapter, text, status in
                store.addSynopsis(
                    bookTitle: title,
                    chapter: chapter,
                    synopsisText: text,
                    chapterStatus: status
                ) != nil
            }
            .appSheetChrome()
        }
        .sheet(item: $selectedSynopsis) { synopsis in
            SynopsisDetailView(synopsis: synopsis)
                .appSheetChrome()
        }
    }

    private var searchBar: some View {
        HStack(spacing: 9) {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppPalette.accent)
                    .accessibilityHidden(true)
                TextField(
                    "Search title or chapter",
                    text: $searchText,
                    prompt: Text("Search title or chapter").foregroundStyle(AppPalette.muted)
                )
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit { searchFocused = false }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppPalette.muted)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                    .padding(.vertical, -7)
                    .padding(.trailing, -8)
                }
            }
            .appFieldStyle(isFocused: searchFocused)

            if !store.synopses.isEmpty {
                Menu {
                    Picker("Sort", selection: $sort) {
                        ForEach(LibrarySort.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundStyle(AppPalette.accent)
                        .frame(width: 48, height: 50)
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(AppPalette.fieldBorder, lineWidth: 1)
                        }
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Sort")
                .accessibilityValue(sort.title)
            }
        }
    }

    private func chapter(_ synopsis: BookSynopsis) -> some View {
        Text("Chapter \(synopsis.chapter)")
            .font(.caption)
            .foregroundStyle(AppPalette.muted)
    }

    private func deleteSynopsis(_ synopsis: BookSynopsis) {
        if let removed = store.deleteSynopsis(synopsis) {
            pendingUndoSynopsis = removed.0
            pendingUndoDrafts = removed.1
            showUndoSnackbar = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                if pendingUndoSynopsis?.id == removed.0.id {
                    pendingUndoSynopsis = nil
                    pendingUndoDrafts = []
                    showUndoSnackbar = false
                }
            }
        }
    }
}
