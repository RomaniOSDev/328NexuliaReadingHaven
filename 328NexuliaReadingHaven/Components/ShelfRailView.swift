import SwiftUI

enum ShelfTab: String, CaseIterable, Identifiable {
    case library
    case drafts
    case overview
    case stats

    var id: String { rawValue }

    var title: String {
        switch self {
        case .library: return "Library"
        case .drafts: return "Drafts"
        case .overview: return "Overview"
        case .stats: return "Stats"
        }
    }

    var systemImage: String {
        switch self {
        case .library: return "books.vertical.fill"
        case .drafts: return "pencil.and.outline"
        case .overview: return "square.stack.3d.up.fill"
        case .stats: return "chart.xyaxis.line"
        }
    }
}

struct ShelfRailView: View {
    @Binding var selection: ShelfTab
    var onSettings: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ShelfTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 17, weight: .semibold))
                        Text(tab.title)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(selection == tab ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: selection == tab
                                        ? [Color("AppSurface"), Color("AppPrimary").opacity(0.35)]
                                        : [Color("AppSurface").opacity(0.55), Color("AppSurface").opacity(0.35)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                selection == tab ? Color("AppAccent").opacity(0.8) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                }
                .buttonStyle(ShelfTabButtonStyle(isSelected: selection == tab))
            }

            Button(action: onSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color("AppSurface").opacity(0.7))
                    )
            }
            .buttonStyle(ShelfTabButtonStyle(isSelected: false))
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color("AppBackground").opacity(0.92))
        .contentShape(Rectangle())
    }
}

private struct ShelfTabButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(
                color: isSelected ? Color("AppPrimary").opacity(0.35) : Color.black.opacity(0.2),
                radius: isSelected ? 12 : 8,
                y: 4
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
