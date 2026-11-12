//
//  RioSetupReachabilityProbe.swift
//

import Foundation

/// GET preflight that follows redirects and reports where the entry URL ends up.
struct RioSetupReachabilityProbe: RioSetupReachabilityProbing {
    var timeout: TimeInterval = 12
    var maxAttempts = 2

    func resolve(_ url: URL) async -> URL? {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout * 2
        configuration.waitsForConnectivity = false
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        request.setValue("text/html,application/xhtml+xml,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue(Locale.preferredLanguages.first ?? "en", forHTTPHeaderField: "Accept-Language")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("rio-setup", forHTTPHeaderField: "X-Entry-Channel")
        request.setValue(RioSetupUserAgent.safari, forHTTPHeaderField: "User-Agent")

        rioSetupLog("probe request: \(url.absoluteString)")
        for attempt in 1...max(1, maxAttempts) {
            guard !Task.isCancelled else { return nil }
            // A thrown error and a non-2xx status both fall through to the next attempt.
            do {
                let (_, response) = try await session.data(for: request)
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                let finalURL = response.url ?? url
                rioSetupLog("probe attempt \(attempt): HTTP \(status), final URL after redirects: \(finalURL.absoluteString)")
                if (200...299).contains(status) {
                    return finalURL
                }
            } catch {
                rioSetupLog("probe attempt \(attempt) failed: \(error.localizedDescription)")
            }
        }
        return nil
    }
}
