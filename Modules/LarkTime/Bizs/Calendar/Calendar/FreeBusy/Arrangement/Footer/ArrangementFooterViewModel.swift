//
//  ArrangementFooterViewModel.swift
//  Calendar
//
//  Created by harry zou on 2019/3/20.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import LarkTimeFormatUtils
import UniverseDesignColor

struct ArrangementFooterViewModel: ArrangementFooterViewInterface {
    var timeText: String {
        return getTimeText(startTime: startTime, endTime: endTime, is12HourStyle: is12HourStyle)
    }

    static let subTitleFont = UIFont.cd.regularFont(ofSize: 14)
    var subTitleAttributedText: NSAttributedString {
        if showFailure {
            return BundleI18n.Calendar.Calendar_Edit_FindTimeFailed
                .attributedText(with: ArrangementFooterViewModel.subTitleFont,
                                color: UIColor.ud.textPlaceholder)
        }
        if !hasNotWorkingHours {
            return getBusyAttributedText()
        }
        return notWorkingHoursText(attendeeCount: workingHourConflictCount)
    }

    private var startTime: Date
    private var endTime: Date
    private var showFailure: Bool = false
    private var totalAttendeeCnt: Int
    private var unAvailableAttendeeNames: [String]
    private var hasNotWorkingHours: Bool
    private let textMaxWidth: CGFloat
    private var workingHourConflictCount: Int = 0
    private var attendeeFreeBusyInfo: AttendeeFreeBusyInfo

    var is12HourStyle: Bool

    init(startTime: Date,
         endTime: Date,
         totalAttendeeCnt: Int,
         unAvailableAttendeeNames: [String],
         hasNotWorkingHours: Bool,
         textMaxWidth: CGFloat,
         is12HourStyle: Bool,
         attendeeFreeBusyInfo: AttendeeFreeBusyInfo) {
        self.is12HourStyle = is12HourStyle
        self.startTime = startTime
        self.endTime = endTime
        self.totalAttendeeCnt = totalAttendeeCnt
        self.unAvailableAttendeeNames = unAvailableAttendeeNames
        self.hasNotWorkingHours = hasNotWorkingHours
        self.textMaxWidth = textMaxWidth
        self.attendeeFreeBusyInfo = attendeeFreeBusyInfo
    }

    mutating func updateTime(startTime: Date, endTime: Date) {
        self.startTime = startTime
        self.endTime = endTime
    }

    mutating func updateSubTitle(hasNotWorkingHours: Bool,
                                 workingHourConflictCount: Int,
                                 attendeeFreeBusyInfo: AttendeeFreeBusyInfo) {
        self.showFailure = false
        self.totalAttendeeCnt = attendeeFreeBusyInfo.totalCount
        self.unAvailableAttendeeNames = (attendeeFreeBusyInfo.busyAttendees + attendeeFreeBusyInfo.maybeFreeAttendees).map { $0.name }
        self.hasNotWorkingHours = hasNotWorkingHours
        self.workingHourConflictCount = workingHourConflictCount
        self.attendeeFreeBusyInfo = attendeeFreeBusyInfo
    }

    mutating func showFailure(startTime: Date, endTime: Date) {
        updateTime(startTime: startTime, endTime: endTime)
        showFailure = true
    }

    private func getBusyAttributedText() -> NSAttributedString {
        return situationText().attributedText(with: ArrangementFooterViewModel.subTitleFont,
                                              color: situationTextColor())
    }

    private func situationText() -> String {
        // 未回复/待定优化
        return ArrangementFreeBusyTextUtil.textWithoutWorkingHour(with: attendeeFreeBusyInfo)
    }

    func situationTextColor() -> UIColor {
        return ArrangementFreeBusyTextUtil.textColor(with: attendeeFreeBusyInfo)
    }

    private func notWorkingHoursText(attendeeCount: Int) -> NSAttributedString {
        let text = ArrangementFreeBusyTextUtil.textOnWorkingHour(with: attendeeFreeBusyInfo)
        return text.attributedText(with: ArrangementFooterViewModel.subTitleFont, color: UDColor.textPlaceholder)
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
        fullString.addAttributes([NSAttributedString.Key.font: subTitleFont,
                                  NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder],
                                 range: NSRange(location: 0, length: fullString.length))
        return fullString
    }

    func getTimeText(startTime: Date, endTime: Date, is12HourStyle: Bool) -> String {
        // 场景: 安排时间-底部-获取当前预约的日程的时间
        // 上下文: 时间安排页的日程起始和结束时间只能预约在同一天，但是日程的日期可以跨年
        let customOptions = Options(
            is12HourStyle: is12HourStyle,
            timeFormatType: .short,
            timePrecisionType: .minute,
            datePrecisionType: .day,
            dateStatusType: .relative
        )

        let relativeDateString = TimeFormatUtils.formatFullDate(from: startTime, with: customOptions)
        let timeRangeString = CalendarTimeFormatter.formatOneDayTimeRange(
            startFrom: startTime,
            endAt: endTime,
            with: customOptions
        )
        return BundleI18n.Calendar.Calendar_StandardTime_RelativeDateTimeCombineFormat(relativeDate: relativeDateString,
                                                                                       time: timeRangeString
        )
    }
}
