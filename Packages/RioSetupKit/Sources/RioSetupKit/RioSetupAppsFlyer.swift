//
//  RioSetupAppsFlyer.swift
//

import AdSupport
import AppsFlyerLib
import AppTrackingTransparency
import Foundation

// MARK: - AppsFlyer conversion delegate

/// Forwards AppsFlyer conversion callbacks to the entry URL builder.
final class RioSetupConversionListener: NSObject, AppsFlyerLibDelegate {
    private let entry: RioSetupAppsFlyerEntry

    init(entry: RioSetupAppsFlyerEntry) {
        self.entry = entry
    }

    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        let conversion = RioSetupAppsFlyerEntry.flatten(data)
        rioSetupLog("AppsFlyer conversion received (\(conversion.count) keys):\n" + conversion
            .sorted { $0.key < $1.key }
            .map { "    \($0.key) = \($0.value)" }
            .joined(separator: "\n"))
        Task { @MainActor [entry] in entry.receive(conversion) }
    }

    func onConversionDataFail(_ error: Error) {
        rioSetupLog("AppsFlyer conversion failed: \(error.localizedDescription)")
        let conversion = ["error": error.localizedDescription, "af_status": "Organic"]
        Task { @MainActor [entry] in entry.receive(conversion) }
    }
}

// MARK: - Entry URL from AppsFlyer conversion

/// Builds `base/{sub7}?…` when `sub7` exists, otherwise `base/?…`, from the stored conversion.
@MainActor
final class RioSetupAppsFlyerEntry: RioSetupEntryURLProviding {
    private let store: RioSetupSessionStoring
    private let baseTemplate: String
    private let fallback: RioSetupFallbackURLComposer
    private let timeout: Duration
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(
        store: RioSetupSessionStoring,
        baseTemplate: String,
        fallback: RioSetupFallbackURLComposer,
        timeout: Duration = .seconds(10)
    ) {
        self.store = store
        self.baseTemplate = baseTemplate
        self.fallback = fallback
        self.timeout = timeout
    }

    /// Called by the AppsFlyer delegate with the flattened conversion payload.
    func receive(_ conversion: [String: String]) {
        store.conversionData = conversion
        resumeWaiters()
    }

    func waitForConversion() async {
        guard store.conversionData == nil, store.cachedEntryURL == nil else { return }
        let deadline = Task { [weak self, timeout] in
            try? await Task.sleep(for: timeout)
            guard !Task.isCancelled else { return }
            rioSetupLog("AppsFlyer conversion did not arrive within \(timeout), continuing without it")
            self?.resumeWaiters()
        }
        await withCheckedContinuation { waiters.append($0) }
        deadline.cancel()
    }

    func makeEntryURL() -> URL? {
        appsFlyerURL(from: store.conversionData ?? [:]) ?? fallback.composedURL()
    }

    private func resumeWaiters() {
        let pending = waiters
        waiters.removeAll()
        pending.forEach { $0.resume() }
    }

    // MARK: - URL builder

    private func appsFlyerURL(from data: [String: String]) -> URL? {
        guard var components = URLComponents(string: baseTemplate) else { return nil }

        func value(_ keys: String...) -> String? {
            keys.lazy
                .compactMap { data[$0]?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty }
        }

        let slash = CharacterSet(charactersIn: "/")
        let sub7 = value("sub7", "af_sub7")
        if let sub7 {
            let basePath = components.path.trimmingCharacters(in: slash)
            let token = sub7.trimmingCharacters(in: slash)
            components.path = basePath.isEmpty ? "/\(token)" : "/\(basePath)/\(token)"
        }

        // Query names match the tracker offer URL. Values come from the AF conversion or the device.
        let appsFlyer = AppsFlyerLib.shared()
        let query: [(String, String?)] = [
            ("sub1", value("sub1", "af_sub1")),
            ("sub2", value("sub2", "af_sub2")),
            ("sub3", value("sub3", "af_sub3")),
            ("channel", value("channel", "af_channel", "media_source")),
            ("sub5", value("sub5", "af_sub5")),
            ("sub6", value("af_siteid", "siteid", "sub6", "af_sub6")),
            ("sub7", sub7),
            ("sub8", value("af_ad", "afad", "ad", "sub8")),
            ("idfa", Self.authorizedIDFA),
            ("d", value("d")),
            ("campid", value("campid", "campaign_id", "af_c_id", "campaignid")),
            ("adsetid", value("adsetid", "adset_id", "af_adset_id")),
            ("adset", value("adset", "af_adset")),
            ("app_id", value("app_id") ?? appsFlyer.appleAppID),
            ("sub20", value("sub20", "sub_20", "af_sub20")),
            ("sub11", appsFlyer.getAppsFlyerUID()),
            ("sub15", Bundle.main.bundleIdentifier),
        ]
        components.queryItems = query.compactMap { name, value in
            guard let value, !value.isEmpty else { return nil }
            return URLQueryItem(name: name, value: value)
        }
        return components.url
    }

    /// IDFA is available only after ATT is authorized.
    private static var authorizedIDFA: String? {
        guard ATTrackingManager.trackingAuthorizationStatus == .authorized else { return nil }
        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        return idfa == "00000000-0000-0000-0000-000000000000" ? nil : idfa
    }

    // MARK: - Conversion flatten

    /// Flattens nested conversion data into `a.b[0].c` string pairs.
    nonisolated static func flatten(_ dictionary: [AnyHashable: Any], prefix: String? = nil) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in dictionary {
            guard let key = key as? String else { continue }
            let path = prefix.map { "\($0).\(key)" } ?? key

            switch value {
            case let nested as [AnyHashable: Any]:
                result.merge(flatten(nested, prefix: path)) { current, _ in current }
            case let array as [Any]:
                for (index, element) in array.enumerated() {
                    let elementPath = "\(path)[\(index)]"
                    if let nested = element as? [AnyHashable: Any] {
                        result.merge(flatten(nested, prefix: elementPath)) { current, _ in current }
                    } else {
                        result[elementPath] = "\(element)"
                    }
                }
            case let number as NSNumber where CFGetTypeID(number) == CFBooleanGetTypeID():
                result[path] = number.boolValue ? "true" : "false"
            case let number as NSNumber:
                result[path] = number.stringValue
            default:
                result[path] = "\(value)"
            }
        }
        return result
    }
}
