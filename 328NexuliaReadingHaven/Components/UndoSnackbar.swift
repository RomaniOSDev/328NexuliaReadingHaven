import SwiftUI

struct UndoSnackbar: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack {
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color("AppTextPrimary"))
            Spacer()
            Button("Undo", action: onUndo)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color("AppAccent"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color("AppSurface"))
                .shadow(color: Color("AppPrimary").opacity(0.3), radius: 10, y: 4)
        )
        .padding(.horizontal, 16)
    }
}
