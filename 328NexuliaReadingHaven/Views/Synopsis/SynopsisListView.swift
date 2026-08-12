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
    @State private var showAddSheet = false
    @State private var selectedSynopsis: BookSynopsis?
    @State private var searchText = ""
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
        VStack(spacing: 0) {
            ShelfBannerView(imageName: "bannerPenNotes")

            VStack(spacing: 10) {
                TextField("Search title or chapter", text: $searchText)
                    .appFieldStyle()
                Picker("Sort", selection: $sort) {
                    ForEach(LibrarySort.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            if store.synopses.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color("AppAccent"))
                    Text("Add Synopsis")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text("Capture chapter summaries for your reading list.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Add Synopsis") { showAddSheet = true }
                        .buttonStyle(PrimaryGradientButtonStyle())
                }
                Spacer()
            } else if filteredSynopses.isEmpty {
                Spacer()
                Text("No matches for “\(searchText)”.")
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            } else {
                List {
                    ForEach(filteredSynopses) { synopsis in
                        Button {
                            selectedSynopsis = synopsis
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(synopsis.bookTitle)
                                        .font(.headline)
                                        .foregroundStyle(Color("AppTextPrimary"))
                                    Spacer()
                                    StatusBadgeView(status: synopsis.chapterStatus)
                                }
                                Text("Chapter \(synopsis.chapter)")
                                    .font(.subheadline)
                                    .foregroundStyle(Color("AppAccent"))
                                Text(synopsis.excerpt)
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color("AppSurface").opacity(0.6))
                    }
                    .onDelete(perform: deleteSynopses)
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
            }
        }
        .overlay(alignment: .bottom) {
            if showUndoSnackbar, pendingUndoSynopsis != nil {
                UndoSnackbar(message: "Synopsis removed") {
                    if let synopsis = pendingUndoSynopsis {
                        _ = store.restoreSynopsis(synopsis, linkedDrafts: pendingUndoDrafts)
                    }
                    pendingUndoSynopsis = nil
                    pendingUndoDrafts = []
                    showUndoSnackbar = false
                }
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !store.synopses.isEmpty {
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
            SynopsisEditorSheet(mode: .create) { title, chapter, text, status in
                store.addSynopsis(
                    bookTitle: title,
                    chapter: chapter,
                    synopsisText: text,
                    chapterStatus: status
                ) != nil
            }
        }
        .sheet(item: $selectedSynopsis) { synopsis in
            SynopsisDetailView(synopsis: synopsis)
        }
    }

    private func deleteSynopses(at offsets: IndexSet) {
        for index in offsets {
            let synopsis = filteredSynopses[index]
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
}
