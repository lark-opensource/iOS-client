//
//  FreeBusy+ArrangementHeader.swift
//  Calendar
//
//  Created by pluto on 2023/8/29.
//

import Foundation
import LarkTimeFormatUtils


extension FreeBusyUtils {
    /// 返回参与人的时区 map
    static func getStartTimeMap(timezoneMap: [String: String],
                                        attendees: [UserAttendeeBaseDisplayInfo],
                                        startTime: Date,
                                        is12HourStyle: Bool) -> [String: StartTimeInfo] {
        if timezoneMap.isEmpty { return [:] }
        var result = [String: StartTimeInfo]()
        for attendee in attendees {
            /*
             SDK 返回的 timeZoneMap 有两种情况
             1. timeZoneID == "" (表示隐藏时区)
             2. attendee 对应 calendarID 在 map 中无对应 pair (后者不显示时间<而不是显示当前系统时区>)
            */
            var timeZone: TimeZone? {
                if let id = timezoneMap[attendee.calendarId] {
                    return TimeZone(identifier: id) ?? TimeZone.current
                } else { return nil }
            }

            guard let timeZone = timeZone else {
                continue
            }
            // 使用给定的时区 format 时间表达字符串
            let customOptions = Options(
                timeZone: timeZone,
                is12HourStyle: is12HourStyle,
                timeFormatType: .short,
                timePrecisionType: .minute
            )
            let startTimeString = TimeFormatUtils.formatTime(from: startTime, with: customOptions)
            let weekdayString = TimeFormatUtils.formatWeekday(from: startTime, with: customOptions)

            result[attendee.calendarId] = StartTimeInfo(timeString: startTimeString,
                                                                timezoneString: weekdayString)
        }
        return result
    }

    static func hasDifferentTimezone(startTimeMap: [String: StartTimeInfo]) -> Bool {
        guard let timeInfo = startTimeMap.values.first else {
            return false
        }
        return startTimeMap.values.contains(where: { $0 != timeInfo })
    }
    
    static func getAttachmentText(image: UIImage, endString: String) -> NSAttributedString {
        let endWithSpaceHolder = " " + endString
        let fullString = NSMutableAttributedString(string: "")
        let imageAttachment = NSTextAttachment()
        imageAttachment.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
        imageAttachment.image = image.withRenderingMode(.alwaysOriginal)
        let imageString = NSAttributedString(attachment: imageAttachment)
        fullString.append(imageString)

        fullString.append(NSAttributedString(string: endWithSpaceHolder))
        fullString.addAttributes([NSAttributedString.Key.font: UIFont.cd.regularFont(ofSize: 14),
                                  NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder],
                                 range: NSRange(location: 0, length: fullString.length))
        return fullString
    }
}

