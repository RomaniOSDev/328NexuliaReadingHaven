import SwiftUI

struct PressButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
    }

    var kind: Kind = .primary
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 5)
        configuration.label
            .font(.subheadline.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(kind == .primary ? AppPalette.buttonInk : AppPalette.accent)
            .padding(.horizontal, 15)
            .padding(.vertical, 11)
            .frame(minHeight: 44)
            .background {
                if kind == .primary {
                    shape.fill(AppPalette.accent)
                        .overlay {
                            PressTexture(name: "ButtonInk", opacity: 0.36)
                                .clipShape(shape)
                        }
                } else {
                    shape.fill(AppPalette.surface)
                        .overlay {
                            shape.strokeBorder(AppPalette.fieldBorder, lineWidth: 1)
                        }
                }
            }
            .overlay {
                shape.fill(AppPalette.buttonInk.opacity(configuration.isPressed ? 0.16 : 0))
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .opacity(isEnabled ? 1 : 0.48)
    }
}

struct PressTexture: View {
    let name: String
    let opacity: Double

    var body: some View {
        GeometryReader { proxy in
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
        .opacity(opacity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct JournalIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(AppPalette.accent)
            .frame(width: 44, height: 44)
            .background {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(AppPalette.fieldBorder, lineWidth: 1)
            }
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

struct AppFieldModifier: ViewModifier {
    var isFocused = false
    var minHeight: CGFloat = 50

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 5)
        content
            .font(.body)
            .foregroundStyle(AppPalette.ink)
            .tint(AppPalette.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background {
                shape.fill(AppPalette.surface)
                    .overlay {
                        PressTexture(name: "FieldPaper", opacity: 0.58)
                            .clipShape(shape)
                    }
                    .overlay {
                        shape.strokeBorder(
                            isFocused ? AppPalette.accent : AppPalette.fieldBorder,
                            lineWidth: isFocused ? 2 : 1
                        )
                    }
            }
    }
}

struct StatusBadgeView: View {
    let status: ChapterStatus

    var body: some View {
        Label(status.title, systemImage: status == .done ? "checkmark.circle" : "circle.lefthalf.filled")
            .font(.caption.weight(.medium))
            .foregroundStyle(status == .done ? AppPalette.blue : AppPalette.accent)
    }
}

extension View {
    func appFieldStyle(isFocused: Bool = false, minHeight: CGFloat = 50) -> some View {
        modifier(AppFieldModifier(isFocused: isFocused, minHeight: minHeight))
    }

    func appSheetChrome() -> some View {
        presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppPalette.background)
    }

    func appCompactSheetChrome() -> some View {
        presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppPalette.background)
    }
}
