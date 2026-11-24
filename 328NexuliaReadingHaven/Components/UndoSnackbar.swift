import SwiftUI

struct UndoSnackbar: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppPalette.ink)
            Spacer(minLength: 8)
            Button("Undo", action: onUndo)
                .buttonStyle(PressButtonStyle(kind: .secondary))
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(AppPalette.surface)
                .strokeBorder(AppPalette.fieldBorder, lineWidth: 1)
        }
        .padding(.horizontal, 24)
    }
}
