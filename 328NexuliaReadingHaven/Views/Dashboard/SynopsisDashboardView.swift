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
        JournalPage {
            JournalHeading(title: "Overview")

            VStack(spacing: 0) {
                JournalRule()
                countLink("Synopses", count: store.synopsisCount, tab: .library)
                JournalRule()
                countLink("Drafts", count: store.draftCount, tab: .drafts)
                JournalRule()
            }

            if recentItems.isEmpty {
                Text("Recently edited synopses will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.muted)
            } else {
                entries("Recently edited", items: recentItems)
                if !remainingItems.isEmpty {
                    entries("Other synopses", items: remainingItems)
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
            .appSheetChrome()
        }
    }

    private func countLink(_ title: String, count: Int, tab: ShelfTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(AppPalette.ink)
                Spacer()
                Text(count, format: .number)
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(AppPalette.accent)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.accent)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func entries(_ title: String, items: [BookSynopsis]) -> some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppPalette.ink)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 9)
            JournalRule()
            ForEach(items) { item in
                dashboardRow(for: item)
                JournalRule()
            }
        }
    }

    private func dashboardRow(for item: BookSynopsis) -> some View {
        let isExpanded = expandedId == item.id
        return VStack(alignment: .leading, spacing: 9) {
            Button {
                expandedId = isExpanded ? nil : item.id
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.bookTitle)
                            .font(.headline)
                            .foregroundStyle(AppPalette.ink)
                        Text("Chapter \(item.chapter)")
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.muted)
                        StatusBadgeView(status: item.chapterStatus)
                    }
                    Spacer(minLength: 2)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.accent)
                        .accessibilityHidden(true)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            Text(isExpanded ? item.synopsisText : item.excerpt)
                .font(isExpanded ? .body : .subheadline)
                .foregroundStyle(isExpanded ? AppPalette.ink : AppPalette.muted)
                .lineLimit(isExpanded ? nil : 2)

            if isExpanded {
                Text(item.lastEdited, format: .dateTime.day().month().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(AppPalette.muted)
                Button("Edit synopsis") { editingSynopsis = item }
                    .buttonStyle(PressButtonStyle(kind: .secondary))
            }
        }
        .padding(.vertical, 13)
    }
}
