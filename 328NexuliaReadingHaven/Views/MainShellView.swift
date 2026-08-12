import SwiftUI

struct MainShellView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedTab: ShelfTab = .library
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            ShelfRailView(selection: $selectedTab) {
                showSettings = true
            }
            .zIndex(2)

            Group {
                switch selectedTab {
                case .library:
                    SynopsisListView()
                case .drafts:
                    DraftListView()
                case .overview:
                    SynopsisDashboardView(selectedTab: $selectedTab)
                case .stats:
                    StatisticsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(0)
        }
        .appScreenBackground()
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
        }
    }
}
