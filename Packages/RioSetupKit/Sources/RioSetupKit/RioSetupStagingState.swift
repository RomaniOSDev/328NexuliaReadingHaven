//
//  RioSetupStagingState.swift
//

import Foundation
import Observation

/// Staging screen model. Progress runs on its own clock, independent of the network probe.
@MainActor @Observable
final class RioSetupStagingState {
    var progress: Double = 0
    /// Text shown under the staging progress indicator.
    var statusMessage = "Preparing your experience..."

    @ObservationIgnored private var ticker: Task<Void, Never>?

    /// Eases toward 90% and holds there until `finish()`.
    func startProgress() {
        ticker?.cancel()
        progress = 0
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, !Task.isCancelled else { return }
                progress += (0.9 - progress) * 0.05
            }
        }
    }

    func finish() {
        ticker?.cancel()
        ticker = nil
        progress = 1
    }
}
