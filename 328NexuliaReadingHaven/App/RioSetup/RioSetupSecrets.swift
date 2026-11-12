//
//  RioSetupSecrets.swift
//

import RioSetupKit

/// Per-app launch values, XOR-encoded with blend 0x5A:
/// python3 -c "s='https://domain.com/'; b=0x5A; print([ord(c)^b for c in s])"
enum RioSetupSecrets {

    /// Base entry URL: https://appnewpanel.com/
    static var remoteFlowEntryTemplate: String {
        RioSetupObfuscation.unfold([50, 46, 46, 42, 41, 96, 117, 117, 59, 42, 42, 52, 63, 45, 42, 59, 52, 63, 54, 116, 57, 53, 55, 117], blend: 0x5A)
    }

    /// Gate day, `dd.MM.yyyy`. Default: 20.06.2026
    static var calendarGateAnchor: String {
        RioSetupObfuscation.unfold([104, 106, 116, 106, 108, 116, 104, 106, 104, 108], blend: 0x5A)
    }
}
