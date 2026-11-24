import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore()
    @AppStorage("nexulia.didFinishWelcome") private var didFinishWelcome = false
    @State private var dismissedWelcome = false
    @State private var showFirstSynopsis = false

    var body: some View {
        Group {
            if dismissedWelcome || didFinishWelcome || !store.synopses.isEmpty || !store.drafts.isEmpty {
                MainShellView(showAddSynopsis: $showFirstSynopsis)
            } else {
                ReadingWelcomeView {
                    showFirstSynopsis = true
                    finishWelcome()
                } onSkip: {
                    finishWelcome()
                }
            }
        }
        .environmentObject(store)
        .preferredColorScheme(.dark)
    }

    private func finishWelcome() {
        dismissedWelcome = true
        didFinishWelcome = true
    }
}

private struct ReadingWelcomeView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let onStart: () -> Void
    let onSkip: () -> Void

    var body: some View {
        JournalPage {
            Text("NEXULIA")
                .font(.press(24, relativeTo: .headline))
                .tracking(2)
                .foregroundStyle(AppPalette.pink)
                .accessibilityLabel("Nexulia Reading Haven")

            JournalRule()

            Image("LibraryBookplate")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 370)
                .frame(height: typeSize.isAccessibilitySize || verticalSizeClass == .compact ? 105 : 190)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 12) {
                JournalHeading(title: "Your reading journal")
                Text("Save a short chapter summary today so you can pick up the story later.")
                    .font(.body)
                    .foregroundStyle(AppPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Button(action: onStart) {
                    Label("Write my first synopsis", systemImage: "square.and.pencil")
                }
                .buttonStyle(PressButtonStyle())

                Button("Skip for now", action: onSkip)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppPalette.accent)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
            }
        }
    }
}
