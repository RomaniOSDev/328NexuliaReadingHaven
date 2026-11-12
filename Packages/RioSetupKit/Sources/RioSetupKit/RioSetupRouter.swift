//
//  RioSetupRouter.swift
//

import SwiftUI

/// Launch state machine: native shell, web document, or staging (ATT → AppsFlyer → probe).
@MainActor @Observable
final class RioSetupRouter {
    private(set) var destination: RioSetupDestination = .native
    let staging = RioSetupStagingState()
    let store: RioSetupSessionStoring

    private let entry: RioSetupEntryURLProviding
    private let probe: RioSetupReachabilityProbing
    private let tracking: RioSetupTrackingAuthorizing

    init(
        gate: RioSetupGate,
        store: RioSetupSessionStoring,
        entry: RioSetupEntryURLProviding,
        probe: RioSetupReachabilityProbing,
        tracking: RioSetupTrackingAuthorizing
    ) {
        self.store = store
        self.entry = entry
        self.probe = probe
        self.tracking = tracking

        store.resetIfFreshInstall()
        if store.savedLastURL == nil {
            store.hasShownNativeShell = false
        }

        // A previously saved final URL always wins: reopen it directly (no entry rebuild / probe).
        if let saved = store.savedLastURL {
            destination = .web(saved)
        } else if !gate.isOpen(on: .now) || store.hasShownNativeShell {
            destination = .native
        } else {
            destination = .staging
        }
        rioSetupLog("launch destination: \(destination)")
    }

    /// Runs the staging flow. Does nothing for native and web launches. Cancels with the calling task.
    func run() async {
        guard destination == .staging else { return }
        staging.startProgress()
        let resolved = await resolveStaging()
        staging.finish()
        if !Task.isCancelled {
            rioSetupLog("staging resolved: \(resolved)")
            destination = resolved
        }
    }

    func showNative() {
        destination = .native
    }

    /// ATT is requested on every launch path, not only in staging.
    func requestTracking() {
        Task { await tracking.requestIfNeeded() }
    }

    private func resolveStaging() async -> RioSetupDestination {
        await tracking.requestIfNeeded()
        await entry.waitForConversion()
        // The web view opens where the entry URL ends up after redirects, not the entry URL itself.
        guard !Task.isCancelled, let entryURL = makeEntryURL(), let finalURL = await probe.resolve(entryURL) else {
            return .native
        }
        return .web(finalURL)
    }

    private func makeEntryURL() -> URL? {
        let url = entry.makeEntryURL()
        rioSetupLog("entry URL: \(url?.absoluteString ?? "nil")")
        if let url {
            store.cachedEntryURL = url
        }
        return url
    }
}

/// SwiftUI root that swaps native / staging / web as the router resolves the launch.
struct RioSetupRootView<Native: View>: View {
    let router: RioSetupRouter
    let theme: RioSetupTheme
    @ViewBuilder let native: () -> Native

    var body: some View {
        ZStack {
            switch router.destination {
            case .native:
                native().transition(slide)
            case .staging:
                RioSetupStagingCanvas(state: router.staging, theme: theme).transition(slide)
            case .web(let url):
                RioSetupWebScreen(url: url, store: router.store, theme: theme, onFailure: router.showNative)
                    .transition(slide)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: router.destination)
        .task {
            router.requestTracking()
            await router.run()
        }
        // The first prompt can miss its window. Ask again each time the app returns to the foreground.
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            router.requestTracking()
        }
    }

    private var slide: AnyTransition {
        .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    }
}
