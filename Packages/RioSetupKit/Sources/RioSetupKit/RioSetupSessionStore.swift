//
//  RioSetupSessionStore.swift
//

import Foundation
import Security

/// Durable flags live in the Keychain, the attribution cache in UserDefaults.
@MainActor
final class RioSetupSessionStore: RioSetupSessionStoring {
    private enum DefaultsKey {
        static let installMarker = "rio_setup_install_marker"
        static let conversionData = "appsFlyerConversionData"
        static let cachedEntryURL = "finalAppsflyerURL"
    }

    private let defaults: UserDefaults
    private let keychain = RioSetupKeychain()
    private let lastURLKey = RioSetupKeys.savedLastURL
    private let nativeShellKey = RioSetupKeys.nativeShell

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Durable (Keychain)

    var savedLastURL: URL? {
        get { keychain[lastURLKey].flatMap(URL.init(string:)) }
        set { keychain[lastURLKey] = newValue?.absoluteString }
    }

    var hasShownNativeShell: Bool {
        get { keychain[nativeShellKey] == "1" }
        set { keychain[nativeShellKey] = newValue ? "1" : nil }
    }

    // MARK: - Attribution cache (UserDefaults)

    var conversionData: [String: String]? {
        get { defaults.dictionary(forKey: DefaultsKey.conversionData) as? [String: String] }
        set { defaults.set(newValue, forKey: DefaultsKey.conversionData) }
    }

    var cachedEntryURL: URL? {
        get { defaults.string(forKey: DefaultsKey.cachedEntryURL).flatMap(URL.init(string:)) }
        set { defaults.set(newValue?.absoluteString, forKey: DefaultsKey.cachedEntryURL) }
    }

    /// The Keychain survives uninstall and UserDefaults does not, so a missing marker means a fresh install.
    func resetIfFreshInstall() {
        guard !defaults.bool(forKey: DefaultsKey.installMarker) else { return }
        savedLastURL = nil
        hasShownNativeShell = false
        defaults.set(true, forKey: DefaultsKey.installMarker)
    }
}

/// Minimal generic-password Keychain wrapper scoped to the flow. Assigning `nil` removes the item.
private struct RioSetupKeychain {
    private let service = (Bundle.main.bundleIdentifier ?? "app") + ".riosetup"

    subscript(account: String) -> String? {
        get {
            var query = baseQuery(for: account)
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne

            var item: CFTypeRef?
            guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
                  let data = item as? Data else {
                return nil
            }
            return String(data: data, encoding: .utf8)
        }
        nonmutating set {
            var query = baseQuery(for: account)
            SecItemDelete(query as CFDictionary)
            guard let newValue else { return }
            query[kSecValueData as String] = Data(newValue.utf8)
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                rioSetupLog("keychain save failed for \(account): \(status)")
            }
        }
    }

    private func baseQuery(for account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
