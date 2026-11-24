import SwiftUI

enum AppPalette {
    static let background = Color("AppBackground")
    static let surface = Color("AppSurface")
    static let ink = Color("AppTextPrimary")
    static let muted = Color("AppTextSecondary")
    static let accent = Color("AppAccent")
    static let pink = Color(red: 1.0, green: 0.64, blue: 0.88)
    static let blue = Color("AppPrimary")
    static let rule = Color(red: 0.29, green: 0.24, blue: 0.40)
    static let fieldBorder = Color(red: 0.45, green: 0.38, blue: 0.62)
    static let buttonInk = Color(red: 0.11, green: 0.06, blue: 0.20)
}

extension Font {
    static func press(_ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        .custom("NexuliaPress-Regular", size: size, relativeTo: style)
    }
}
