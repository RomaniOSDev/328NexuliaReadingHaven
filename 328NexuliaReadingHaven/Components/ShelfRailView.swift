import SwiftUI

enum ShelfTab: Hashable {
    case library, drafts, overview, stats
}

struct JournalMasthead: View {
    let onSettings: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("NEXULIA")
                    .font(.press(24, relativeTo: .headline))
                    .tracking(2)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .foregroundStyle(AppPalette.pink)
                    .accessibilityLabel("Nexulia Reading Haven")

                Spacer()

                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(JournalIconButtonStyle())
                .accessibilityLabel("Settings")
            }
            JournalRule()
        }
        .padding(.horizontal, 24)
        .padding(.top, 3)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
        .background(AppPalette.background)
    }
}
