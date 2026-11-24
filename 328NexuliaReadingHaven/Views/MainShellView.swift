import SwiftUI

struct MainShellView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedTab: ShelfTab = .library
    @State private var showSettings = false

    @Binding var showAddSynopsis: Bool

    var body: some View {
        VStack(spacing: 0) {
            JournalMasthead { showSettings = true }

            TabView(selection: $selectedTab) {
                SynopsisListView(showAddSheet: $showAddSynopsis)
                    .tabItem { Label("Library", systemImage: "books.vertical") }
                    .tag(ShelfTab.library)

                DraftListView()
                    .tabItem { Label("Drafts", systemImage: "pencil.line") }
                    .tag(ShelfTab.drafts)

                SynopsisDashboardView(selectedTab: $selectedTab)
                    .tabItem { Label("Overview", systemImage: "list.bullet.rectangle") }
                    .tag(ShelfTab.overview)

                StatisticsView()
                    .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
                    .tag(ShelfTab.stats)
            }
            .tint(AppPalette.accent)
        }
        .appScreenBackground()
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
        }
    }
}
