//
//  RioSetupTrackingPrompt.swift
//

import AppTrackingTransparency
import UIKit

/// Requests App Tracking Transparency on any launch path (native / web / staging).
@MainActor
final class RioSetupTrackingPrompt: RioSetupTrackingAuthorizing {
    private var inFlight: Task<Void, Never>?

    /// Safe to call repeatedly: concurrent callers share one system dialog.
    func requestIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        let request = inFlight ?? Task { await Self.present() }
        inFlight = request
        await request.value
        inFlight = nil
    }

    private static func present() async {
        // The system dialog only appears while the app is active.
        var attempts = 0
        while UIApplication.shared.applicationState != .active {
            guard attempts < 50 else { return }
            attempts += 1
            try? await Task.sleep(for: .milliseconds(100))
        }

        // Let the first screen render before the dialog covers it.
        try? await Task.sleep(for: .seconds(1))
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }
}
