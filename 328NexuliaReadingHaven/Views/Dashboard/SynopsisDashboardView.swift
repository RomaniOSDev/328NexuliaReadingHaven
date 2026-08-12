import SwiftUI

struct SynopsisDashboardView: View {
    @EnvironmentObject private var store: AppDataStore
    @Binding var selectedTab: ShelfTab
    @State private var expandedId: UUID?
    @State private var editingSynopsis: BookSynopsis?

    private var recentItems: [BookSynopsis] {
        Array(store.recentlyEditedSynopses.prefix(5))
    }

    private var remainingItems: [BookSynopsis] {
        let recentIds = Set(recentItems.map(\.id))
        return store.dashboardItems.filter { !recentIds.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ShelfBannerView(imageName: "bannerPagesGlow")

            HStack(spacing: 12) {
                insightChip(title: "Synopses", value: store.synopsisCount, icon: "books.vertical") {
                    selectedTab = .library
                }
                insightChip(title: "Drafts", value: store.draftCount, icon: "pencil.and.outline") {
                    selectedTab = .drafts
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if store.dashboardItems.isEmpty {
                Spacer()
                Text("Your overview fills in as you add synopses.")
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        Text("Recently edited")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .padding(.horizontal, 4)

                        ForEach(recentItems) { item in
                            dashboardRow(for: item)
                        }

                        if !remainingItems.isEmpty {
                            Text("All synopses")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                                .padding(.horizontal, 4)
                                .padding(.top, 8)

                            ForEach(remainingItems) { item in
                                dashboardRow(for: item)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .sheet(item: $editingSynopsis) { synopsis in
            SynopsisEditorSheet(mode: .edit(synopsis)) { title, chapter, text, status in
                store.updateSynopsis(
                    synopsis,
                    bookTitle: title,
                    chapter: chapter,
                    synopsisText: text,
                    chapterStatus: status
                )
            }
        }
    }

    private func insightChip(title: String, value: Int, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color("AppAccent"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                    Text("\(value)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .contentShape(Rectangle())
            .surfaceCard()
        }
        .buttonStyle(.plain)
    }

    private func dashboardRow(for item: BookSynopsis) -> some View {
        let isExpanded = expandedId == item.id
        return VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedId = isExpanded ? nil : item.id
                }
            } label: {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.bookTitle)
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            Spacer()
                            StatusBadgeView(status: item.chapterStatus)
                        }
                        Text("Chapter \(item.chapter)")
                            .font(.subheadline)
                            .foregroundStyle(Color("AppAccent"))
                        Text(item.excerpt)
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineLimit(isExpanded ? nil : 2)
                        Text("Last edited \(item.lastEdited.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(item.synopsisText)
                    .font(.body)
                    .foregroundStyle(Color("AppTextPrimary"))
                Button("Edit synopsis") {
                    editingSynopsis = item
                }
                .buttonStyle(PrimaryGradientButtonStyle())
            }
        }
        .surfaceCard()
    }
}
