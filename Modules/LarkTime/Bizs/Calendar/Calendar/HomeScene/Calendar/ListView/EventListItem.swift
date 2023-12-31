//
//  BlockListItem.swift
//  Calendar
//
//  Created by zhu chao on 2018/8/9.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkTimeFormatUtils
import UniverseDesignIcon

protocol EventListSeparatorItem {
    var isMonthSeparator: Bool { get set }
    var isWeekSeparator: Bool { get set }
    var text: String { get set }

    static func month(date: Date) -> EventListSeparatorItem
    static func week(date: Date, firstWeekday: DaysOfWeek) -> EventListSeparatorItem
}

struct EventListSeparatorModel: EventListSeparatorItem {
    var isMonthSeparator: Bool
    var isWeekSeparator: Bool
    var text: String

    static func month(date: Date) -> EventListSeparatorItem {
        // 此时得到的时区就是当前设备时区
        let isInSameYear = Calendar(identifier: .gregorian).isDate(date, equalTo: Date(), toGranularity: .year)
        // 使用系统当前时区
        let customOptions = Options(
            timeFormatType: isInSameYear ? .short : .long,
            datePrecisionType: .month,
            dateStatusType: .absolute
        )
        // 上下文: 非跨年日程显示月份全写，跨年日程显示年月结合的时间格式
        return EventListSeparatorModel(
            isMonthSeparator: true,
            isWeekSeparator: false,
            text: TimeFormatUtils.formatDate(from: date, with: customOptions)
        )
    }

    static func week(date: Date, firstWeekday: DaysOfWeek) -> EventListSeparatorItem {
        var calendar = Calendar.gregorianCalendar
        calendar.firstWeekday = firstWeekday.rawValue
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let weekEnd = (date + 6.days)!
        let isSameYear = calendar.isDate(date, equalTo: weekEnd, toGranularity: .year)
        // 使用系统当前时区
        let customOptions = Options(
            timeFormatType: isSameYear ? .short : .long,
            datePrecisionType: .day,
            dateStatusType: .absolute
        )

        let monthStartText = TimeFormatUtils.formatDate(from: date, with: customOptions)
        let monthEndText = TimeFormatUtils.formatDate(from: weekEnd, with: customOptions)
        let text = BundleI18n.Calendar.Calendar_StandardTime_WeekDateRangeCombineFormat(
            number: weekOfYear,
            dateRange: BundleI18n.Calendar.Calendar_StandardTime_GeneralDateTimeRangeWithoutWrap(
                startTime: monthStartText,
                endTime: monthEndText
            )
        )
        return EventListSeparatorModel(isMonthSeparator: false, isWeekSeparator: true, text: text)
    }
}

protocol BlockListEventItem {
    var isFirstEventOfDay: Bool { get set }
    var eventDate: Date { get set }
    var weekDay: String { get }
    var monthDay: String { get }
    var isLaterThanToday: Bool? { get }
    var content: ListBlockViewContent? { get }
}

private struct BlockListModel: BlockListEventItem {
    var content: ListBlockViewContent?
    var isFirstEventOfDay: Bool
    var eventDate: Date
    var weekDay: String
    var monthDay: String
    var isLaterThanToday: Bool?

    static func eventContent(with model: BlockDataProtocol,
                             calendar: CalendarModel?,
                             isFirstEventOfDay: Bool,
                             date: Date,
                             sysCalendar: Calendar,
                             eventViewSetting: EventViewSetting,
                             is12HourStyle: Bool) -> BlockListModel {
        var content: ListBlockViewContent?
        if let instance = model as? CalendarEventInstanceEntity {
            content = EventInstanceViewModel(eventViewSetting: eventViewSetting,
                                             instance: instance,
                                             calendar: calendar,
                                             currentDate: date,
                                             sysCalendar: sysCalendar,
                                             is12HourStyle: is12HourStyle)

        } else if let timeBlock = model as? TimeBlockModel {
            content = ListTimeBlockViewModel(eventViewSetting: eventViewSetting,
                                             timeBlock: timeBlock,
                                             currentDate: date,
                                             is12HourStyle: is12HourStyle)
        }
        guard let content else { return BlockListModel(isFirstEventOfDay: false, eventDate: Date(), weekDay: "", monthDay: "") }
        let day = CalendarTimeFormatter.formatDayWithLeadingZero(from: date)

        let today = Date()
        let isToday = sysCalendar.isDate(date, inSameDayAs: today)
        // 使用的是设备当前时区
        let customOptions = Options(timeFormatType: .short)
        let weekdayString = TimeFormatUtils.formatWeekday(from: date, with: customOptions)
        return BlockListModel(content: content,
                              isFirstEventOfDay: isFirstEventOfDay,
                              eventDate: date,
                              weekDay: weekdayString,
                              monthDay: day,
                              isLaterThanToday: isToday ? nil : date > today)

    }

    static func nullEventContent(date: Date,
                                 sysCalendar: Calendar) -> BlockListModel {
        let day = CalendarTimeFormatter.formatDayWithLeadingZero(from: date)
        let today = Date()
        let isToday = sysCalendar.isDate(date, inSameDayAs: today)
        // 使用的是设备当前时区
        let customOptions = Options(timeFormatType: .short)
        let weekdayString = TimeFormatUtils.formatWeekday(from: date, with: customOptions)
        return BlockListModel(content: nil,
                                   isFirstEventOfDay: true,
                                   eventDate: date,
                                   weekDay: weekdayString,
                                   monthDay: day,
                                   isLaterThanToday: isToday ? nil : date > today)

    }

}

protocol BlockListItem {
    var cellHeight: CGFloat { get set }
    var cellIdentifer: String { get set }
    var separator: EventListSeparatorItem? { get set }
    var event: BlockListEventItem? { get set }
    /// 当天的23:59:59
    var date: Date { get }
    var dateTimeString: String { get }

    func isSeparator() -> Bool
    func isEvent() -> Bool
    static func monthSeparatorItem(with date: Date) -> BlockListItem
    static func weekSeparatorItem(with date: Date, firstWeekday: DaysOfWeek) -> BlockListItem
}

extension BlockListItem {
    var dateStart: Date {
        return date.dayStart()
    }
}

struct BlockListItemModel: BlockListItem {
    var cellHeight: CGFloat
    var cellIdentifer: String
    var separator: EventListSeparatorItem?
    var event: BlockListEventItem?
    var date: Date
    var dateTimeString: String

    func isSeparator() -> Bool {
        return separator != nil
    }

    func isEvent() -> Bool {
        return event != nil || self.cellIdentifer == ListCell.identifier
    }

    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: TimeFormatUtils.languageIdentifier)
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()

    static func monthSeparatorItem(with date: Date) -> BlockListItem {
        return BlockListItemModel(cellHeight: MonthCell.cellHeight,
                                  cellIdentifer: MonthCell.identifier,
                                  separator: EventListSeparatorModel.month(date: date),
                                  event: nil,
                                  date: date,
                                  dateTimeString: BlockListItemModel.formatter.string(from: date))
    }

    static func weekSeparatorItem(with date: Date, firstWeekday: DaysOfWeek) -> BlockListItem {
        return BlockListItemModel(
            cellHeight: WeekCell.cellHeight,
            cellIdentifer: WeekCell.identifier,
            separator: EventListSeparatorModel.week(date: date, firstWeekday: firstWeekday),
            event: nil,
            date: date,
            dateTimeString: BlockListItemModel.formatter.string(from: date)
        )
    }

    static func eventItem(with model: BlockDataProtocol,
                          calendar: CalendarModel?,
                          isFirstEventOfDay: Bool,
                          date: Date,
                          sysCalendar: Calendar,
                          eventViewSetting: EventViewSetting,
                          is12HourStyle: Bool) -> BlockListItemModel {
        let content = BlockListModel.eventContent(with: model,
                                                  calendar: calendar,
                                                  isFirstEventOfDay: isFirstEventOfDay,
                                                  date: date,
                                                  sysCalendar: sysCalendar,
                                                  eventViewSetting: eventViewSetting,
                                                  is12HourStyle: is12HourStyle)
        return BlockListItemModel(cellHeight: isFirstEventOfDay ? ListCell.cellHeight : ListSubCell.cellHeight,
                                  cellIdentifer: isFirstEventOfDay ? ListCell.identifier : ListSubCell.identifier,
                                  separator: nil,
                                  event: content,
                                  date: date,
                                  dateTimeString: BlockListItemModel.formatter.string(from: date))
    }

    static func nullItem(date: Date, sysCalendar: Calendar) -> BlockListItemModel {
        return BlockListItemModel(cellHeight: ListCell.cellHeight,
                                  cellIdentifer: ListCell.identifier,
                                  separator: nil,
                                  event: BlockListModel.nullEventContent(date: date, sysCalendar: sysCalendar),
                                  date: date,
                                  dateTimeString: BlockListItemModel.formatter.string(from: date))
    }
}

struct ListTimeBlockViewModel: ListBlockViewContent {
    var icon: (image: UIImage, isSelected: Bool, expandTapInset: UIEdgeInsets)?
    var startDay: Int32
    var endDay: Int32
    var isCoverPassEvent: Bool = false
    var maskOpacity: Float
    var cornerImageColor: UIColor? = nil
    var sourceIcon: UIImage? = nil
    var dotColor: UIColor
    var backgroundColor: UIColor
    var foregroundColor: UIColor
    var strikethroughColor: UIColor
    var indicatorInfo: (color: UIColor, isStripe: Bool)? = nil
    var dashedBorderColor: UIColor? = nil
    var titleText: String
    var timeDes: String
    var timeText: String
    var locationText: String
    var hasStrikethrough: Bool
    var stripBackgroundColor: UIColor? = nil
    var stripLineColor: UIColor? = nil
    var startDate: Date
    var endDate: Date
    var userInfo: [String: Any] = [:]
    let timeBlock: TimeBlockModel
    let isAllDay: Bool

    init(eventViewSetting: EventViewSetting,
         timeBlock: TimeBlockModel,
         currentDate: Date,
         is12HourStyle: Bool) {
        self.timeBlock = timeBlock
        self.startDate = timeBlock.startDate
        self.endDate = timeBlock.endDate
        self.startDay = timeBlock.startDay
        self.endDay = timeBlock.endDay
        self.isAllDay = timeBlock.isAllDay
        self.userInfo = ["timeBlock": timeBlock]
        self.hasStrikethrough = timeBlock.taskBlockModel?.isCompleted == true
        self.isCoverPassEvent = eventViewSetting.showCoverPassEvent
        let skinColorHelper = SkinColorHelper(skinType: eventViewSetting.skinTypeIos, insInfo: .init(from: timeBlock))
        let iconColor = skinColorHelper.indicatorInfo?.color ?? skinColorHelper.eventTextColor
        let isLightScene = skinColorHelper.skinType == .light
        let normalColor = isLightScene ? iconColor : TimeBlockUtils.Config.darkSceneBlockIconColor
        let selectedColor = isLightScene ? iconColor : TimeBlockUtils.Config.darkSceneBlockIconColor
        let image = TimeBlockUtils.getIcon(model: timeBlock, isLight: isLightScene, color: normalColor, selectedColor: selectedColor)
        self.icon = (image: image, isSelected: timeBlock.taskBlockModel?.isCompleted == true, expandTapInset: .init(top: 0, left: 0, bottom: 0, right: -10))
        self.backgroundColor = skinColorHelper.backgroundColor
        self.foregroundColor = TimeBlockUtils.getTitleColor(helper: skinColorHelper, model: timeBlock)
        self.strikethroughColor = skinColorHelper.eventTextColor.withAlphaComponent(0.7)
        self.dotColor = skinColorHelper.dotColor
        self.maskOpacity = TimeBlockUtils.getMaskOpacity(helper: skinColorHelper, model: timeBlock)
        self.cornerImageColor = nil
        self.titleText = InstanceBaseFunc.getTitleFromModel(model: timeBlock)
        self.timeDes = TimeBlockUtils.getOverDaySummary(model: timeBlock,
                                                        currentDate: currentDate,
                                                        is12HourStyle: is12HourStyle)
        self.timeText = TimeBlockUtils.getTimeDescription(model: timeBlock,
                                                          currentDate: currentDate,
                                                          is12HourStyle: is12HourStyle)
        self.locationText = ""
    }
}

struct EventInstanceViewModel: ListBlockViewContent {
    static let googleImage = UIImage.cd.image(named: "googleFlagShape_highlighted")
        .withRenderingMode(.alwaysTemplate)
    static let exchangeImage = UIImage.cd.image(named: "exchangeFlagShape")
        .withRenderingMode(.alwaysTemplate)
    static let localImage = UIImage.cd.image(named: "localFlagShape")
        .withRenderingMode(.alwaysTemplate)

    var icon: (image: UIImage, isSelected: Bool, expandTapInset: UIEdgeInsets)? = nil
    var startDay: Int32 = 0
    var endDay: Int32 = 0
    var isCoverPassEvent: Bool = false
    var maskOpacity: Float
    var cornerImageColor: UIColor?
    var sourceIcon: UIImage?
    var strikethroughColor: UIColor = .ud.textPlaceholder

    var dotColor: UIColor

    var backgroundColor: UIColor

    var foregroundColor: UIColor

    var indicatorInfo: (color: UIColor, isStripe: Bool)?

    var titleText: String

    var timeDes: String

    var timeText: String

    var locationText: String

    var hasStrikethrough: Bool = false

    var stripBackgroundColor: UIColor?

    var stripLineColor: UIColor?

    var dashedBorderColor: UIColor?

    var startDate: Date

    var endDate: Date

    var userInfo: [String: Any]
    var isAllDay: Bool

    private var instance: CalendarEventInstanceEntity

    private var calendar: CalendarModel?

    init(eventViewSetting: EventViewSetting,
         instance: CalendarEventInstanceEntity,
         calendar: CalendarModel?,
         currentDate: Date,
         sysCalendar: Calendar,
         is12HourStyle: Bool) {
        self.instance = instance
        self.calendar = calendar
        self.startDate = instance.startDate
        self.endDate = instance.endDate
        self.userInfo = ["instance": instance, "calendar": calendar as Any]
        self.isAllDay = instance.isAllDay
        self.isCoverPassEvent = eventViewSetting.showCoverPassEvent
        let skinColorHelper = SkinColorHelper(skinType: eventViewSetting.skinTypeIos, insInfo: .init(from: instance))
        let selfStatus = instance.selfAttendeeStatus

        if instance.displayType == .undecryptable {
            // 加密日程颜色，特别设置
            self.backgroundColor = UIColor.ud.N200
            self.foregroundColor = UIColor.ud.textCaption
            self.dotColor = UIColor.ud.udtokenColorpickerNeutral
        } else if instance.isCreatedByMeetingRoom.strategy || instance.isCreatedByMeetingRoom.requisition {
            // 会议室自己创建的日程需要特别设置颜色
            self.backgroundColor = UIColor.ud.N100
            self.foregroundColor = UIColor.ud.N600
            self.dotColor = UIColor.ud.udtokenColorpickerNeutral
        } else {
            self.backgroundColor = skinColorHelper.backgroundColor
            self.foregroundColor = skinColorHelper.eventTextColor
            self.dotColor = skinColorHelper.dotColor
        }

        if instance.displayType != .undecryptable {
            // 配置底色条纹
            if let stripeColors = skinColorHelper.stripeColor {
                self.stripLineColor = stripeColors.foreground
                self.stripBackgroundColor = stripeColors.background
            }
            self.hasStrikethrough = selfStatus == .decline
            var image: UIImage?
            if instance.isGoogleEvent() {
                image = Self.googleImage
            } else if instance.isExchangeEvent() {
                image = Self.exchangeImage
            } else if instance.isLocalEvent() {
                image = Self.localImage
            }
            self.sourceIcon = image
        }

        self.indicatorInfo = skinColorHelper.indicatorInfo
        self.dashedBorderColor = skinColorHelper.dashedBorderColor

        self.maskOpacity = skinColorHelper.maskOpacity

        let hasNoCornerIcon = !instance.isGoogleEvent() && !instance.isExchangeEvent() && !instance.isLocalEvent()
        self.cornerImageColor = hasNoCornerIcon ? nil : skinColorHelper.typeIconTintColor

        self.titleText = InstanceBaseFunc.getTitleFromModel(model: instance, calendar: calendar)
        let timeInfo = TimeUtils.timeDescription(ins: instance,
                                                 currentDate: currentDate,
                                                 calendar: sysCalendar,
                                                 is12HourStyle: is12HourStyle)
        self.timeDes = timeInfo.0
        self.timeText = timeInfo.1

        self.locationText = InstanceBaseFunc.getSubTitleFromModel(model: instance)

    }
}

struct TimeUtils {
    static func timeDescription(ins: CalendarEventInstanceEntity,
                                currentDate: Date,
                                calendar: Calendar,
                                is12HourStyle: Bool,
                                trimTailingZeros: Bool = true) -> (String, String) {
        return timeDescription(isOverOneDay: ins.isOverOneDay,
                               endDay: ins.endDay,
                               startDay: ins.startDay,
                               isAllDay: ins.isAllDay,
                               startDate: ins.startDate,
                               endDate: ins.endDate,
                               currentDate: currentDate,
                               calendar: calendar,
                               is12HourStyle: is12HourStyle)
    }

    static func timeDescription(isOverOneDay: Bool,
                                endDay: Int32,
                                startDay: Int32,
                                isAllDay: Bool,
                                startDate: Date,
                                endDate: Date,
                                currentDate: Date,
                                calendar: Calendar,
                                is12HourStyle: Bool,
                                trimTailingZeros: Bool = true) -> (String, String) {
        // 场景: 列表视图-日程块上显示的时间表达文案，上下文:
        // 1. 跨天: 全天日程显示全天文案，非全天日程分三种情况: 起始日期显示起始时间，中期日期显示全天文案，结束日期显示结束时间
        // 2. 当天：时间范围，包含起始和结束时间
        // 使用设备当前时区
        var overDayInfo = ""
        var timeDescription = ""
        let customOptions = Options(
            is12HourStyle: is12HourStyle,
            timePrecisionType: .minute,
            shouldRemoveTrailingZeros: trimTailingZeros
        )
        if isOverOneDay {// 跨天
            let dayNumber = endDay - startDay + 1
            let appearTimes = Calendar.gregorianCalendar.dateComponents([.day],
                                                                from: startDate.dayStart(),
                                                                to: currentDate.dayStart()).day ?? 0
            overDayInfo = BundleI18n.Calendar.Calendar_View_AlldayInfo(day: appearTimes + 1, total: dayNumber)
            if isAllDay {
                timeDescription = BundleI18n.Calendar.Calendar_Edit_Allday
            } else {
                if calendar.isDate(currentDate, inSameDayAs: startDate) {
                    timeDescription = TimeFormatUtils.formatTime(from: startDate, with: customOptions)
                } else if calendar.isDate(currentDate, inSameDayAs: endDate) {
                    let endTime = TimeFormatUtils.formatTime(from: endDate, with: customOptions)
                    timeDescription = BundleI18n.Calendar.Calendar_RRule_Until(endDate: endTime)
                } else {
                    let dayStart = calendar.startOfDay(for: currentDate)
                    let dayEnd = dayStart.dayEnd()
                    if (startDate < dayStart) && (endDate > dayEnd) {
                        timeDescription = BundleI18n.Calendar.Calendar_Edit_Allday
                    } else {
                        assertionFailureLog()
                    }
                }
            }
        } else {
            timeDescription = isAllDay ? BundleI18n.Calendar.Calendar_Edit_Allday : CalendarTimeFormatter.formatOneDayTimeRange(startFrom: startDate, endAt: endDate, with: customOptions)
        }
        return (overDayInfo, timeDescription)
    }
}

// 月视图时间块下拉列表ViewData
class MonthTimeBlockItemModel: MonthEventItem {
    var icon: UIImage? = nil
    var originalModel: BlockDataProtocol
    var leftIcon: UIImage?
    var color: UIColor
    var isSolid: Bool = false
    var title: NSAttributedString
    var subTitle: NSAttributedString
    var startTime: Date
    var colorBlockCornerRadius: CGFloat = MonthBlockCell.Config.colorBlockSize.width / 2
    var endTime: Date
    var isCoverPassEvent: Bool
    var isAllDay: Bool
    var maskOpacity: Float
    struct Resource {
        static let normalIcon = UDIcon.ellipseOutlined
        static let finishIcon = UDIcon.yesFilled
    }

    init(eventViewSetting: EventViewSetting,
         timeBlock: TimeBlockModel,
         date: Date,
         is12HourStyle: Bool) {
        let isCompleted = timeBlock.taskBlockModel?.isCompleted == true
        self.originalModel = timeBlock
        self.isAllDay = timeBlock.isAllDay
        self.isCoverPassEvent = eventViewSetting.showCoverPassEvent
        let skinColorHelper = SkinColorHelper(skinType: eventViewSetting.skinTypeIos, insInfo: .init(from: timeBlock))
        self.maskOpacity = TimeBlockUtils.getMaskOpacity(helper: skinColorHelper, model: timeBlock)
        let image = TimeBlockUtils.getIcon(model: timeBlock, isLight: skinColorHelper.skinType == .light, color: UIColor.ud.iconN3, selectedColor: skinColorHelper.dotColor)
        self.leftIcon = image
        let startDate = timeBlock.startDate
        let endDate = timeBlock.endDate
        self.startTime = startDate
        self.endTime = endDate
        self.color = skinColorHelper.dotColor
        let title = InstanceBaseFunc.getTitleFromModel(model: timeBlock) + TimeBlockUtils.getOverDaySummary(model: timeBlock, currentDate: date, is12HourStyle: is12HourStyle)
        let hasStrikethrough = timeBlock.taskBlockModel?.isCompleted == true
        let titleColor = isCompleted ? UIColor.ud.textPlaceholder : UIColor.ud.textTitle
        self.title = title.attributedText(with: UIFont.cd.mediumFont(ofSize: 14),
                                          color: titleColor,
                                          hasStrikethrough: hasStrikethrough,
                                          strikethroughColor: titleColor,
                                          lineBreakMode: .byWordWrapping)
        let subText = TimeBlockUtils.getTimeDescription(model: timeBlock, currentDate: date, is12HourStyle: is12HourStyle)
        let subTitleColor = isCompleted ? UIColor.ud.textPlaceholder : UIColor.ud.N600
        self.subTitle = subText.attributedText(with: UIFont.cd.regularFont(ofSize: 12),
                                               color: subTitleColor,
                                               hasStrikethrough: hasStrikethrough,
                                               strikethroughColor: subTitleColor,
                                               lineBreakMode: .byWordWrapping)
    }
}

struct MonthEventItemModel: MonthEventItem {
    var leftIcon: UIImage? = nil
    var isCoverPassEvent: Bool
    var maskOpacity: Float
    var icon: UIImage?
    var startTime: Date
    var endTime: Date
    var originalModel: BlockDataProtocol
    var color: UIColor
    var colorBlockCornerRadius: CGFloat = 2
    var isSolid: Bool
    var title: NSAttributedString
    var isAllDay: Bool
    var subTitle: NSAttributedString
    init(eventViewSetting: EventViewSetting,
         instance: CalendarEventInstanceEntity,
         calendar: CalendarModel?,
         date: Date, is12HourStyle: Bool) {
        self.originalModel = instance
        self.startTime = instance.startDate
        self.endTime = instance.endDate
        self.isAllDay = instance.isAllDay
        self.isCoverPassEvent = eventViewSetting.showCoverPassEvent
        let skinColorHelper = SkinColorHelper(skinType: eventViewSetting.skinTypeIos, insInfo: .init(from: instance))

        if instance.displayType == .undecryptable {
            // 加密秘钥失效日程，特别设置
            self.color = .ud.udtokenColorpickerNeutral
            self.isSolid = false
        } else if instance.isCreatedByMeetingRoom.strategy || instance.isCreatedByMeetingRoom.requisition {
            // 会议室自己创建的日程需要特别设置颜色
            self.color = .ud.udtokenColorpickerNeutral
            self.isSolid = true
        } else {
            self.color = skinColorHelper.dotColor
            self.isSolid = instance.selfAttendeeStatus == .accept
        }
        let timeInfo = TimeUtils.timeDescription(ins: instance,
                                                 currentDate: date,
                                                 calendar: Calendar(identifier: .gregorian),
                                                 is12HourStyle: is12HourStyle)
        self.maskOpacity = skinColorHelper.maskOpacity
        let timeDes = timeInfo.0
        let timeText = timeInfo.1

        let title = InstanceBaseFunc.getTitleFromModel(model: instance, calendar: calendar) + " " + timeDes
        var locationText = ""
        if instance.displayType == .full {
            locationText = InstanceBaseFunc.getSubTitleFromModel(model: instance)
        }

        let hasStrikethrough = instance.selfAttendeeStatus == .decline
        let gray = UIColor.ud.textPlaceholder
        let subText = (timeText + " " + locationText).trimmingCharacters(in: .whitespacesAndNewlines)

        // 加密秘钥失效日程，特别设置
        if instance.displayType == .undecryptable {
            self.title = title.attributedText(with: UIFont.cd.mediumFont(ofSize: 14),
                                              color: UIColor.ud.textCaption,
                                              lineBreakMode: .byWordWrapping)
            self.subTitle = NSAttributedString(string: "")
            self.subTitle = subText.attributedText(with: UIFont.cd.regularFont(ofSize: 12),
                                                   color: UIColor.ud.N600,
                                                   lineBreakMode: .byWordWrapping)
        } else if hasStrikethrough {
            self.title = title.attributedText(with: UIFont.cd.mediumFont(ofSize: 14),
                                              color: gray,
                                              hasStrikethrough: true,
                                              strikethroughColor: gray,
                                              lineBreakMode: .byWordWrapping)

            self.subTitle = subText.attributedText(with: UIFont.cd.regularFont(ofSize: 12),
                                              color: gray,
                                              hasStrikethrough: true,
                                              strikethroughColor: gray,
                                              lineBreakMode: .byWordWrapping)
        } else {
            self.title = title.attributedText(with: UIFont.cd.mediumFont(ofSize: 14),
                                              color: UIColor.ud.textTitle,
                                              lineBreakMode: .byWordWrapping)
            self.subTitle = subText.attributedText(with: UIFont.cd.regularFont(ofSize: 12),
                                                   color: UIColor.ud.N600,
                                                   lineBreakMode: .byWordWrapping)
        }
        if instance.isGoogleEvent() {
            self.icon = UIImage.cd.image(named: "month_google").withRenderingMode(.alwaysOriginal)
        } else if instance.isExchangeEvent() {
            self.icon = UDIcon.getIconByKey(.exchangeColorful, size: CGSize(width: 16, height: 16))
        } else if instance.isLocalEvent() {
            self.icon = UIImage.cd.image(named: "localFlagShape").withRenderingMode(.alwaysOriginal)
        } else {
            self.icon = nil
        }
    }
}
