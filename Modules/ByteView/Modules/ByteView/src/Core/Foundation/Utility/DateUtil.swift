//
//  DateUtil.swift
//  ByteView
//
//  Created by kiri on 2021/6/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

final class DateUtil {
    static func formatDuration(_ duration: TimeInterval, concise: Bool = false) -> String {
        if duration < 0 { return "" }
        let hourInterval = 3600
        let minuteInterval = 60
        let interval = Int(duration)
        var hour = 0, min = 0, seconds = 0
        if interval >= hourInterval {
            hour = interval / hourInterval
            min = (interval % hourInterval) / minuteInterval
            seconds = interval % minuteInterval
            return concise ? String(format: "%02d:%02d:%02d", hour, min, seconds) : I18n.View_G_DurationHourMinSecBraces(hour, min, seconds)
        } else if interval >= minuteInterval {
            min = interval / minuteInterval
            seconds = interval % minuteInterval
            return concise ? String(format: "%02d:%02d", min, seconds) : I18n.View_G_DurationMinSecBraces(min, seconds)
        } else {
            return concise ? String(format: "00:%02d", interval) : I18n.View_G_DurationSecBraces(interval)
        }
    }
}

extension Calendar {
    static let gregorianCalendar = Calendar(identifier: .gregorian)

    static func gregorianCalendarWithCurrentTimeZone() -> Calendar {
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = TimeZone.current
        return calendar
    }
}
