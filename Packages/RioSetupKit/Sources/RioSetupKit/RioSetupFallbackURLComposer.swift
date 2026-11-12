//
//  RioSetupFallbackURLComposer.swift
//

import Foundation

/// Entry URL used when the AppsFlyer builder cannot produce one: fills the
/// `{subid}` / `{clickid}` / `{subid2}` placeholders and appends the tracking parameter.
struct RioSetupFallbackURLComposer {
    let template: String
    let trackingParameterName: String

    func composedURL() -> URL? {
        let geo = Locale.current.region?.identifier ?? "XX"
        let subValue = "\(appHandle)_\(geo)"
        let clickId = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()

        var raw = template
        for (name, value) in [("subid", subValue), ("clickid", clickId), ("subid2", geo)] {
            for token in ["{\(name)}", "%7B\(name)%7D", "%7b\(name)%7d"] {
                raw = raw.replacingOccurrences(of: token, with: value)
            }
        }

        guard var components = URLComponents(string: raw) else { return nil }
        var items = components.queryItems ?? []
        if !items.contains(where: { $0.name == trackingParameterName }) {
            items.append(URLQueryItem(name: trackingParameterName, value: subValue))
        }
        components.queryItems = items
        return components.url
    }

    private var appHandle: String {
        let name = ["CFBundleDisplayName", "CFBundleName"].lazy
            .compactMap { Bundle.main.object(forInfoDictionaryKey: $0) as? String }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
        return (name ?? "App").replacingOccurrences(of: " ", with: "")
    }
}
