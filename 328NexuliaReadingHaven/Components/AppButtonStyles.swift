import SwiftUI

struct PrimaryGradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color("AppTextPrimary"))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color("AppPrimary"), Color("AppAccent")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color("AppPrimary").opacity(configuration.isPressed ? 0.15 : 0.35), radius: 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SurfaceCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("AppSurface").opacity(0.95),
                                Color("AppSurface").opacity(0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: 10, y: 4)
    }
}

struct AppFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundStyle(Color("AppTextPrimary"))
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color("AppSurface").opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color("AppAccent").opacity(0.25), lineWidth: 1)
            )
    }
}

struct StatusBadgeView: View {
    let status: ChapterStatus

    var body: some View {
        Text(status.title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color("AppTextPrimary"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(status == .done ? Color("AppAccent").opacity(0.45) : Color("AppPrimary").opacity(0.35))
            )
    }
}

extension View {
    func surfaceCard() -> some View {
        modifier(SurfaceCardModifier())
    }

    func appFieldStyle() -> some View {
        modifier(AppFieldModifier())
    }
}
