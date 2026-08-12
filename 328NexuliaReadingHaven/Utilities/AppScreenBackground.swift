import SwiftUI

extension View {
    func appScreenBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image("bgBookDesk")
                            .resizable()
                            .scaledToFill()
                            .opacity(0.35)
                    }
                    .clipped()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
    }
}

/// Banner image clipped so scaledToFill overflow cannot steal taps from the tab rail above.
struct ShelfBannerView: View {
    let imageName: String
    var height: CGFloat = 140

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .contentShape(Rectangle())
            .allowsHitTesting(false)
    }
}
