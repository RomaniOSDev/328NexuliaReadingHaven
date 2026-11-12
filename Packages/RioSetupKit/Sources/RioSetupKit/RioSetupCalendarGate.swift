//
//  RioSetupCalendarGate.swift
//

import Foundation

/// Opens on the anchor calendar day (`dd.MM.yyyy`) in the given time zone.
struct RioSetupCalendarGate: RioSetupGate {
    let anchor: String
    var timeZone = TimeZone.current

    func isOpen(on date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let anchorDate = formatter.date(from: anchor) else { return false }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.startOfDay(for: date) >= calendar.startOfDay(for: anchorDate)
    }
}
