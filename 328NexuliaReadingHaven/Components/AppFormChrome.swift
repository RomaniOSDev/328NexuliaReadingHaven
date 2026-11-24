import SwiftUI

struct AppFieldLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppPalette.ink)
    }
}

struct AppTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var autocapitalization: TextInputAutocapitalization = .sentences
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            AppFieldLabel(title: title)
                .accessibilityHidden(true)
            TextField(title, text: $text, prompt: Text(placeholder).foregroundStyle(AppPalette.muted))
                .textInputAutocapitalization(autocapitalization)
                .focused($isFocused)
                .appFieldStyle(isFocused: isFocused)
                .accessibilityLabel(title)
        }
    }
}

struct AppTextEditorField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var accessory: String? = nil
    @FocusState private var isFocused: Bool
    @ScaledMetric(relativeTo: .body) private var editorHeight = 174.0

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    heading
                    Spacer(minLength: 0)
                    count
                }
                VStack(alignment: .leading, spacing: 4) {
                    heading
                    count
                }
            }

            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .focused($isFocused)
                .frame(minHeight: editorHeight)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundStyle(AppPalette.muted)
                            .padding(.leading, 5)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .appFieldStyle(isFocused: isFocused)
                .accessibilityLabel(title)
        }
    }

    private var heading: some View {
        AppFieldLabel(title: title)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var count: some View {
        if let accessory {
            Text(accessory)
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppPalette.muted)
        }
    }
}

struct AppMenuField<Selection: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: Selection
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            AppFieldLabel(title: title)
                .accessibilityHidden(true)
            Picker(title, selection: $selection, content: content)
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .appFieldStyle(minHeight: 44)
        }
    }
}

struct AppSegmentedField<Selection: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: Selection
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            AppFieldLabel(title: title)
                .accessibilityHidden(true)
            Picker(title, selection: $selection, content: content)
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
        }
    }
}

struct JournalEntryRow<Metadata: View>: View {
    let title: String
    let excerpt: String
    let updated: Date
    @ViewBuilder var metadata: () -> Metadata

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppPalette.ink)
                Spacer(minLength: 2)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.accent)
                    .accessibilityHidden(true)
            }

            metadata()

            Text(excerpt)
                .font(.subheadline)
                .foregroundStyle(AppPalette.muted)
                .lineLimit(2)

            Text(updated, style: .relative)
                .font(.caption)
                .foregroundStyle(AppPalette.muted)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

struct AppEmptyState: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let artwork: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    private var artworkHeight: CGFloat {
        typeSize.isAccessibilitySize || verticalSizeClass == .compact ? 110 : 190
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Image(artwork)
                .resizable()
                .scaledToFit()
                .frame(height: artworkHeight)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
                .padding(.bottom, 5)

            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppPalette.ink)
                .accessibilityAddTraits(.isHeader)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppPalette.muted)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: action) {
                Label(actionTitle, systemImage: "plus")
            }
            .buttonStyle(PressButtonStyle())
            .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
