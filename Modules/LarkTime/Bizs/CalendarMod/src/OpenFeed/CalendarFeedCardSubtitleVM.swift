//
//  CalendarFeedCardSubtitleVM.swift
//  LarkFeedPlugin
//
//  Created by xiaruzhen on 2023/8/21.
//

import Foundation
import LarkOpenFeed
import LarkModel
import UniverseDesignColor
import RustPB
import LarkFeedBase
import CalendarFoundation
import LarkTimeFormatUtils
import Calendar
import LarkLocalizations

// MARK: - ViewModel
final class CalendarFeedCardSubtitleVM: FeedCardSubtitleVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .subtitle
    }

    // VM 数据
    let subtitleData: FeedCardSubtitleData

    // 在子线程生成view data
    required init(feedPreview: FeedPreview,
                  dependency: CalendarDependency?) {
        guard let originData = try? Feed_V1_CalendarSubtitle(serializedData: feedPreview.extraMeta.bizPb.extraData),
              let dependency = dependency else {
            self.subtitleData = .data(.default())
            return
        }
        if let data = Self.getNormalSubtitle(calendarSubtitleData: originData) {
            self.subtitleData = .data(data)
        } else {
            let builder: FeedCardSubtitleData.Builder = {
                Self.getTimeSubtitleDependOnRender(calendarSubtitleData: originData, dependency: dependency)
            }
            self.subtitleData = .buildDataOnRendering(builder)
        }
    }

    // 在子线程生成view data
    static func getNormalSubtitle(calendarSubtitleData: Feed_V1_CalendarSubtitle) -> FeedCardSubtitleData.R? {
        /* 对sdk的兜底逻辑，当今天没有日程时，且用户将feed日程提醒的开关从关闭变为打开时，
         sdk给到的eventSetting为空，需要端上兜底，默认展示为“今日无事件“，其余情况正常 */
        guard calendarSubtitleData.hasEventSetting else {
            return .text(BundleI18n.CalendarMod.Lark_Event_NoAgendaForToday_Text)
        }
        var text = ""
        let calendarCount = calendarSubtitleData.calendarCount
        if !calendarSubtitleData.eventSetting {
            // 如果关闭了事件提醒
            text = BundleI18n.CalendarMod.Lark_Event_NotificationsOff_Text
        } else if calendarCount == 0 {
            // 如果事件列表为空
            text = BundleI18n.CalendarMod.Lark_Event_NoAgendaForToday_Text
        } else if calendarCount == 1 {
            switch calendarSubtitleData.calendarType {
            case .vcMeeting:
                text = "ID: \(calendarSubtitleData.meetingID)"
            case .calendar:
                if calendarSubtitleData.isAllDay {
                    text = BundleI18n.CalendarMod.Lark_Event_AllDayEvent_Label
                } else {
                    let startTime = TimeInterval(calendarSubtitleData.startTime / 1000)
                    let endTime = TimeInterval(calendarSubtitleData.endTime / 1000)
                    if (startTime) != 0 && (endTime != 0) {
                        return nil
                    }
                }
            case .unknownCalendar: break
            @unknown default: break
            }
        } else if calendarCount > 1 {
            text = BundleI18n.CalendarMod.Lark_Event_NumMoreEventsClickView_Mobile_Text(number: calendarCount - 1)
        }
        return .text(text)
    }

    // 在主线程生成view data
    static func getTimeSubtitleDependOnRender(calendarSubtitleData: Feed_V1_CalendarSubtitle,
                                              dependency: CalendarDependency) -> FeedCardSubtitleData.R {
        let startTime = Date(timeIntervalSince1970: TimeInterval(calendarSubtitleData.startTime / 1000))
        let endTime = Date(timeIntervalSince1970: TimeInterval(calendarSubtitleData.endTime / 1000))
        let is12HourStyle = dependency.is12HourStyle.value
        let rangeTime = Self.getRangeTime(startFrom: startTime, endAt: endTime, is12HourStyle: is12HourStyle)
        if let meetInfo = Self.getMeetingInfo(rooms: calendarSubtitleData.meetingRoom) {
            let attributedString = NSMutableAttributedString(string: rangeTime)
            attributedString.append(meetInfo)
            return .attributedText(attributedString)
        } else {
            return .text(rangeTime)
        }
    }

    static func getRangeTime(startFrom startDate: Date,
                              endAt endDate: Date,
                              is12HourStyle: Bool) -> String {
        let options = Options(is12HourStyle: is12HourStyle,
                              timePrecisionType: .minute,
                              dateStatusType: .absolute)
        let monthOptions = Options(timeFormatType: .short, datePrecisionType: .day, dateStatusType: .absolute)
        let yearOptions = Options(timeFormatType: .long, datePrecisionType: .day, dateStatusType: .absolute)
        let currentLang = LanguageManager.currentLanguage

        var startTimeString = ""
        var endTimeString = ""
        let isInSameDay = startDate.isInSameDay(endDate)
        if isInSameDay {
            return TimeFormatUtils.formatTimeRange(startFrom: startDate, endAt: endDate, with: options)
        } else if startDate.isInSameYear(endDate) {
            startTimeString = TimeFormatUtils.formatDate(from: startDate, with: monthOptions)
            endTimeString = TimeFormatUtils.formatDate(from: endDate, with: monthOptions)
        } else {
            startTimeString = TimeFormatUtils.formatDate(from: startDate, with: yearOptions)
            endTimeString = TimeFormatUtils.formatDate(from: endDate, with: yearOptions)
        }
        return BundleI18n.CalendarMod
            .Calendar_StandardTime_GeneralDateTimeRangeWithoutWrap(startTime: startTimeString  + " " + TimeFormatUtils.formatTime(from: startDate, with: options),
                                                                   endTime: endTimeString  + " " + TimeFormatUtils.formatTime(from: endDate, with: options),
                                                                   lang: currentLang)
    }

    private static func getMeetingInfo(rooms: [String]) -> NSAttributedString? {
        let roomInfo = rooms.joined(separator: "; ")
        guard !rooms.isEmpty, !roomInfo.isEmpty else { return nil }
        let attributedString = NSMutableAttributedString()
        attributedString.append(Self.getAttributedString())
        attributedString.append(NSAttributedString(string: roomInfo))
        return attributedString
    }

    private static func getAttributedString() -> NSAttributedString {
        let font = FeedCardSubtitleComponentCons.subTitleFont
        let rect_w: CGFloat = 12
        let figmaH: CGFloat = 12
        let rect_h: CGFloat = figmaH.auto()
        let line_w: CGFloat = 1
        let y: CGFloat = (font.capHeight - rect_h) / 2
        let attachment = NSTextAttachment()
        let lineImage = UIImage.verticalLineinMiddle(
            rectSize: CGSize(width: rect_w, height: rect_h),
            rectColor: .clear,
            lineSize:  CGSize(width: line_w, height: rect_h),
            lineColor: UIColor.ud.lineDividerDefault)
        attachment.image = lineImage
        attachment.bounds = CGRect(x: 0, y: y, width: rect_w, height: rect_h)
        return NSAttributedString(attachment: attachment)
    }
}
