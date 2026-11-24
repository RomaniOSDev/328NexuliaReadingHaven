import SwiftUI

extension View {
    func appScreenBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppPalette.background.ignoresSafeArea())
    }
}

struct JournalPage<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22, content: content)
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 28)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .appScreenBackground()
    }
}

struct JournalHeading: View {
    let title: String
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.press(46, relativeTo: .largeTitle))
                .foregroundStyle(AppPalette.ink)
                .accessibilityLabel(title)
                .accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)

            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct JournalRule: View {
    var body: some View {
        Rectangle()
            .fill(AppPalette.rule)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}
