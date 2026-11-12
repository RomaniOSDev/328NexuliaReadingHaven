//
//  RioSetupConfiguration+App.swift
//

import RioSetupKit
import SwiftUI

extension RioSetupConfiguration {

    /// Everything this app passes to RioSetupKit.
    static var app: RioSetupConfiguration {
        RioSetupConfiguration(
            appsFlyerDevKey: "cqTiFvvyhL5a2SNAqqAna3",
            appleAppID: "6798512841",
            entryURLTemplate: RioSetupSecrets.remoteFlowEntryTemplate,
            calendarGateAnchor: RioSetupSecrets.calendarGateAnchor,
            theme: RioSetupTheme(
                primary: Color("AppPrimary"),
                accent: Color("AppAccent"),
                background: Color("AppBackground"),
                text: Color("AppTextPrimary")
            )
        )
    }
}
