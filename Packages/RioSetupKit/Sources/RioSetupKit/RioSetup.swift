//
//  RioSetup.swift
//

import AppsFlyerLib
import SwiftUI
import UIKit

/// Entry point of the package: starts AppsFlyer and builds the root screen of the launch flow.
@MainActor
public final class RioSetup {
    private static var current: RioSetup?

    private let configuration: RioSetupConfiguration
    private let store = RioSetupSessionStore()
    private let tracking = RioSetupTrackingPrompt()
    private let entry: RioSetupAppsFlyerEntry
    /// AppsFlyer holds its delegate weakly.
    private let conversionListener: RioSetupConversionListener

    /// Call once from `application(_:didFinishLaunchingWithOptions:)`. Later calls are ignored.
    public static func start(_ configuration: RioSetupConfiguration) {
        guard current == nil else { return }
        current = RioSetup(configuration: configuration)
    }

    /// Root for the scene window. Shows `native`, the staging screen or the web screen, and requests ATT.
    public static func makeRootViewController<Native: View>(
        @ViewBuilder native: @escaping () -> Native
    ) -> UIViewController {
        guard let current else {
            assertionFailure("Call RioSetup.start(_:) before building the root view controller")
            return UIHostingController(rootView: native())
        }
        return UIHostingController(
            rootView: RioSetupRootView(router: current.makeRouter(), theme: current.configuration.theme, native: native)
        )
    }

    private init(configuration: RioSetupConfiguration) {
        self.configuration = configuration
        entry = RioSetupAppsFlyerEntry(
            store: store,
            baseTemplate: configuration.entryURLTemplate,
            fallback: RioSetupFallbackURLComposer(
                template: configuration.entryURLTemplate,
                trackingParameterName: configuration.trackingParameterName
            )
        )
        conversionListener = RioSetupConversionListener(entry: entry)

        let appsFlyer = AppsFlyerLib.shared()
        appsFlyer.appsFlyerDevKey = configuration.appsFlyerDevKey
        appsFlyer.appleAppID = configuration.appleAppID
        appsFlyer.delegate = conversionListener
        appsFlyer.isDebug = false
        appsFlyer.disableAdvertisingIdentifier = true
        appsFlyer.start()
    }

    private func makeRouter() -> RioSetupRouter {
        let router = RioSetupRouter(
            gate: RioSetupCalendarGate(anchor: configuration.calendarGateAnchor, timeZone: configuration.gateTimeZone),
            store: store,
            entry: entry,
            probe: RioSetupReachabilityProbe(),
            tracking: tracking
        )
        router.staging.statusMessage = configuration.stagingMessage
        return router
    }
}
