//
//  RioSetupContracts.swift
//

import Foundation

/// Where the app lands at launch.
enum RioSetupDestination: Hashable {
    case native
    case staging
    case web(URL)
}

/// Decides whether the remote flow may run at all.
protocol RioSetupGate {
    func isOpen(on date: Date) -> Bool
}

/// Supplies the entry URL built from attribution data.
@MainActor
protocol RioSetupEntryURLProviding {
    /// Returns once conversion data is available or the wait times out.
    func waitForConversion() async
    func makeEntryURL() -> URL?
}

/// Preflight for the entry URL.
protocol RioSetupReachabilityProbing: Sendable {
    /// Follows redirects. Returns the final URL when it answers HTTP 2xx, otherwise `nil`.
    func resolve(_ url: URL) async -> URL?
}

/// App Tracking Transparency prompt.
@MainActor
protocol RioSetupTrackingAuthorizing {
    /// Returns once the user has answered or the prompt could not be shown.
    func requestIfNeeded() async
}

/// Single persistence point of the flow.
@MainActor
protocol RioSetupSessionStoring: AnyObject {
    /// Final URL (after redirects) of the first successful web session. Later launches open it directly.
    var savedLastURL: URL? { get set }
    var hasShownNativeShell: Bool { get set }
    /// Flattened AppsFlyer conversion payload.
    var conversionData: [String: String]? { get set }
    /// Last entry URL the flow built. Its presence skips the conversion wait.
    var cachedEntryURL: URL? { get set }
    func resetIfFreshInstall()
}

/// Console output for debugging the flow. Compiled out of release builds.
func rioSetupLog(_ message: @autoclosure () -> String) {
    #if DEBUG
    print("[RioSetup] \(message())")
    #endif
}

enum RioSetupUserAgent {
    /// Many TDS / offer pages blank out the default WKWebView user agent.
    static let safari = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"
}
