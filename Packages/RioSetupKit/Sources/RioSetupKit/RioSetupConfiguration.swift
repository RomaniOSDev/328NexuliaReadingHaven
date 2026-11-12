//
//  RioSetupConfiguration.swift
//

import SwiftUI

/// App-provided settings for the launch flow. The package embeds no per-app values.
public struct RioSetupConfiguration {
    public var appsFlyerDevKey: String
    public var appleAppID: String
    /// Base entry URL. `sub7` from the AppsFlyer conversion becomes its last path component.
    public var entryURLTemplate: String
    /// Gate day in `dd.MM.yyyy`. Web and staging are allowed from this calendar day on.
    public var calendarGateAnchor: String
    public var gateTimeZone: TimeZone
    /// Query item added to the fallback entry URL when the template does not carry it.
    public var trackingParameterName: String
    /// Text shown under the staging progress indicator.
    public var stagingMessage: String
    public var theme: RioSetupTheme

    /// - Parameter trackingParameterName: `nil` keeps the package default.
    public init(
        appsFlyerDevKey: String,
        appleAppID: String,
        entryURLTemplate: String,
        calendarGateAnchor: String,
        gateTimeZone: TimeZone = .current,
        trackingParameterName: String? = nil,
        stagingMessage: String = "Preparing your experience...",
        theme: RioSetupTheme = RioSetupTheme()
    ) {
        self.appsFlyerDevKey = appsFlyerDevKey
        self.appleAppID = appleAppID
        self.entryURLTemplate = entryURLTemplate
        self.calendarGateAnchor = calendarGateAnchor
        self.gateTimeZone = gateTimeZone
        self.trackingParameterName = trackingParameterName ?? RioSetupKeys.trackingParameter
        self.stagingMessage = stagingMessage
        self.theme = theme
    }
}

/// Colors of the staging and web screens. Every value has a default, so pass only what the app brands.
public struct RioSetupTheme {
    public var primary: Color
    public var accent: Color
    public var background: Color
    public var text: Color
    /// Optional image drawn dimmed behind the staging screen.
    public var stagingBackground: Image?
    /// Toolbar buttons and spinner of the web screen.
    public var webTint: Color
    public var webBackground: Color

    public init(
        primary: Color = Color(red: 0.42, green: 0.36, blue: 0.91),
        accent: Color = Color(red: 0.93, green: 0.42, blue: 0.62),
        background: Color = Color(red: 0.06, green: 0.06, blue: 0.10),
        text: Color = .white,
        stagingBackground: Image? = nil,
        webTint: Color = Color(red: 0.20, green: 0.16, blue: 0.42),
        webBackground: Color = Color(red: 0.97, green: 0.96, blue: 0.99)
    ) {
        self.primary = primary
        self.accent = accent
        self.background = background
        self.text = text
        self.stagingBackground = stagingBackground
        self.webTint = webTint
        self.webBackground = webBackground
    }
}

/// XOR decoding for literals kept out of plain text.
public enum RioSetupObfuscation {
    public static func unfold(_ payload: [UInt8], blend: UInt8) -> String {
        String(decoding: payload.map { $0 ^ blend }, as: UTF8.self)
    }
}

/// Literals owned by the package. Changing a storage key orphans the values saved under it.
enum RioSetupKeys {
    /// Keychain account of the saved web URL.
    static var savedLastURL: String {
        RioSetupObfuscation.unfold([41, 63, 41, 41, 51, 53, 52, 27, 52, 57, 50, 53, 40, 15, 8, 22], blend: 0x5A)
    }

    /// Keychain account of the "native shell was shown" flag.
    static var nativeShell: String {
        RioSetupObfuscation.unfold([40, 51, 53, 5, 41, 63, 46, 47, 42, 5, 40, 63, 55, 53, 46, 63, 5, 56, 54, 53, 57, 49, 63, 62], blend: 0x5A)
    }

    /// Default `RioSetupConfiguration.trackingParameterName`.
    static var trackingParameter: String {
        RioSetupObfuscation.unfold([59, 60, 60, 5, 41, 47, 56], blend: 0x5A)
    }
}
