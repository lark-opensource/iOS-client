//
//  SearchDataLoader.swift
//  CalendarInChat
//
//  Created by zoujiayi on 2019/8/11.
//
import UIKit
import RxSwift
import RxCocoa
import Foundation
import CalendarFoundation
import LarkTimeFormatUtils

typealias HighlightTexts = [HighlighItem: [String]]

final class SearchDataLoader {
    private let calendarAPI: CalendarRustAPI
    private let skinType: CalendarSkinType
    private let isCoverPassEvent: Bool
    private let is12Hour: BehaviorRelay<Bool>
    private let disposeBag = DisposeBag()
    private let startWeekday: DaysOfWeek

    var reloadData: ((_ isEmptyQuery: Bool) -> Void)?

    init(api: CalendarRustAPI,
         skinType: CalendarSkinType,
         is12Hour: BehaviorRelay<Bool>,
         startWeekday: DaysOfWeek) {
        self.calendarAPI = api
        self.skinType = skinType
        self.isCoverPassEvent = false // 产品需求
        self.is12Hour = is12Hour
        self.startWeekday = startWeekday
    }

    func search(query: String, filter: CalendarSearchFilter) {
        calendarAPI.searchEvent(query: query, filter: filter)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (events) in
                guard let `self` = self else { return }
                var displayedMonth = Set<Date>()
                var newData: [SearchCellData] = []
                for (instance, content) in events {
                    let date = Date(timeIntervalSince1970: TimeInterval(instance.startTime))
                    let month = date.startOfMonth()
                    if !displayedMonth.contains(month) {
                        displayedMonth.insert(month)
                        newData.append(SearchCellData.monthHeader(date: date))
                    }

                    let cellData = SearchCellData.from(searchInstance: instance,
                                                       content: content,
                                                       skinType: self.skinType,
                                                       isCoverPassEvent: self.isCoverPassEvent,
                                                       is12Hour: self.is12Hour,
                                                       calendar: Calendar(identifier: .gregorian))
                    newData.append(cellData)
                }
                self.data = newData
                self.reloadData?(query.isEmpty)
            }).disposed(by: disposeBag)
    }

    private var data: [SearchCellData] = []

    func getData() -> [SearchCellData] {
        return data
    }
}

struct SearchCellData: SearchCellProtocol, SearchInstanceViewContent {
    var currentDayCount: Int

    var totalDayCount: Int

    var calendarId: String

    var key: String

    var originalTime: Int64

    var highlightedBGColor: UIColor

    var highlightStrings: HighlightTexts

    var hasStrikethrough: Bool

    var height: CGFloat

    var cellType: SearchTableViewCellType

    var belongingDate: Date

    var timeDes: String

    var timeText: String

    var titleText: String

    var locationText: String

    var attendeeText: String

    var descText: String

    var dashedBorderColor: UIColor?

    var backgroundColor: UIColor

    var textColor: UIColor

    var indicatorInfo: (color: UIColor, isStripe: Bool)?

    var stripBackgroundColor: UIColor?

    var stripLineColor: UIColor?

    var startDate: Date

    var endDate: Date

    var isCoverPassEvent: Bool

    var maskOpacity: Float

    var userInfo: [String: Any] = [:]

    init(height: CGFloat,
         cellType: SearchTableViewCellType,
         belongingDate: Date,
         timeDes: String,
         timeText: String,
         titleText: String,
         locationText: String,
         attendeeText: String,
         descText: String,
         dashedBorderColor: UIColor?,
         backgroundColor: UIColor,
         textColor: UIColor,
         indicatorInfo: (color: UIColor, isStripe: Bool)?,
         stripBackgroundColor: UIColor?,
         stripLineColor: UIColor?,
         highlightedBGColor: UIColor,
         startDate: Date,
         endDate: Date,
         isCoverPassEvent: Bool,
         maskOpacity: Float,
         hasStrikethrough: Bool,
         key: String,
         calendarId: String,
         originalTime: Int64,
         highlightStrings: HighlightTexts,
         currentDayCount: Int,
         totalDayCount: Int) {
        self.height = height
        self.cellType = cellType
        self.belongingDate = belongingDate
        self.timeDes = timeDes
        self.timeText = timeText
        self.titleText = titleText
        self.locationText = locationText
        self.attendeeText = attendeeText
        self.descText = descText
        self.dashedBorderColor = dashedBorderColor
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.indicatorInfo = indicatorInfo
        self.stripBackgroundColor = stripBackgroundColor
        self.stripLineColor = stripLineColor
        self.startDate = startDate
        self.endDate = endDate
        self.isCoverPassEvent = isCoverPassEvent
        self.maskOpacity = maskOpacity
        self.hasStrikethrough = hasStrikethrough
        self.highlightedBGColor = highlightedBGColor
        self.key = key
        self.calendarId = calendarId
        self.originalTime = originalTime
        self.highlightStrings = highlightStrings
        self.currentDayCount = currentDayCount
        self.totalDayCount = totalDayCount
    }

    static func from(searchInstance: CalendarSearchInstance,
                     content: CalendarSearchContent,
                     skinType: CalendarSkinType,
                     isCoverPassEvent: Bool,
                     is12Hour: BehaviorRelay<Bool>,
                     calendar: Calendar) -> SearchCellData {
        let startDate = Date(timeIntervalSince1970: TimeInterval(searchInstance.startTime))
        let endDate = Date(timeIntervalSince1970: TimeInterval(searchInstance.endTime))
        let belongingDate = startDate.dayStart()
        let timeCombo = timeDescription(currentDayCount: searchInstance.currentDayCount,
                                        totalDayCount: searchInstance.totalDayCount,
                                        isAllDay: content.isAllday,
                                        startDate: startDate,
                                        endDate: endDate,
                                        currentDate: belongingDate,
                                        calendar: calendar,
                                        is12HourStyle: is12Hour.value)
        let skinColorHelper = SkinColorHelper(
            skinType: skinType,
            insInfo: .init(selfStatus: content.selfAttendeeStatus,
                           eventColorIndex: content.eventColorIndex,
                           calColorIndex: content.calendarColorIndex)
        )
        let cellData = SearchCellData(height: content.haveExtraInfo() ? 79 : 60,
                                      cellType: .event,
                                      belongingDate: Date(timeIntervalSince1970: TimeInterval(searchInstance.startTimeForInstance)).dayStart(),
                                      timeDes: timeCombo.0,
                                      timeText: timeCombo.1,
                                      titleText: content.summary,
                                      locationText: content.location,
                                      attendeeText: content.attendee,
                                      descText: content.desc,
                                      dashedBorderColor: skinColorHelper.dashedBorderColor,
                                      backgroundColor: skinColorHelper.backgroundColor,
                                      textColor: skinColorHelper.eventTextColor,
                                      indicatorInfo: skinColorHelper.indicatorInfo,
                                      stripBackgroundColor: skinColorHelper.stripeColor?.background,
                                      stripLineColor: skinColorHelper.stripeColor?.foreground,
                                      highlightedBGColor: skinColorHelper.highLightColor,
                                      startDate: startDate,
                                      endDate: endDate,
                                      isCoverPassEvent: isCoverPassEvent,
                                      maskOpacity: 0.5,
                                      hasStrikethrough: content.selfAttendeeStatus == .decline,
                                      key: content.key,
                                      calendarId: content.calendarID,
                                      originalTime: content.originalTime,
                                      highlightStrings: content.eventHighLight,
                                      currentDayCount: searchInstance.currentDayCount,
                                      totalDayCount: searchInstance.totalDayCount
        )
        return cellData
    }

    static func monthHeader(date: Date) -> SearchCellData {
        // 此时得到的时区就是当前设备时区
        let isInSameYear = Calendar(identifier: .gregorian).isDate(date, equalTo: Date(), toGranularity: .year)
        // 使用系统当前时区
        let customOptions = Options(
            timeFormatType: isInSameYear ? .short : .long,
            datePrecisionType: .month,
            dateStatusType: .absolute
        )

        let cellData = SearchCellData(height: 64.5,
                                      cellType: .monthTitle,
                                      belongingDate: date.dayStart(),
                                      timeDes: "",
                                      timeText: "",
                                      titleText: TimeFormatUtils.formatDate(from: date, with: customOptions),
                                      locationText: "",
                                      attendeeText: "",
                                      descText: "",
                                      dashedBorderColor: nil,
                                      backgroundColor: UIColor.clear,
                                      textColor: UIColor.clear,
                                      indicatorInfo: nil,
                                      stripBackgroundColor: nil,
                                      stripLineColor: UIColor.clear,
                                      highlightedBGColor: UIColor.clear,
                                      startDate: Date(),
                                      endDate: Date(),
                                      isCoverPassEvent: false,
                                      maskOpacity: 0,
                                      hasStrikethrough: false,
                                      key: "",
                                      calendarId: "",
                                      originalTime: -1,
                                      highlightStrings: [:],
                                      currentDayCount: -1,
                                      totalDayCount: -1
        )
        return cellData
    }

    static func timeDescription(currentDayCount: Int,
                                totalDayCount: Int,
                                isAllDay: Bool,
                                startDate: Date,
                                endDate: Date,
                                currentDate: Date,
                                calendar: Calendar,
                                is12HourStyle: Bool,
                                trimTailingZeros: Bool = true) -> (String, String) {
        // 场景: 搜索视图-列表视图-日程块上显示的时间，
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
        if totalDayCount != 1 {// 跨天
            overDayInfo = BundleI18n.Calendar.Calendar_View_AlldayInfo(day: currentDayCount, total: totalDayCount)
            if isAllDay {
                timeDescription = BundleI18n.Calendar.Calendar_Edit_Allday
            } else {
                if currentDayCount == 1 {
                    timeDescription = TimeFormatUtils.formatTime(from: startDate, with: customOptions)
                } else if currentDayCount == totalDayCount {
                    let endTime = TimeFormatUtils.formatTime(from: endDate, with: customOptions)
                    timeDescription = BundleI18n.Calendar.Calendar_RRule_Until(endDate: endTime)
                } else {
                    timeDescription = BundleI18n.Calendar.Calendar_Edit_Allday
                }
            }
        } else {
            timeDescription = isAllDay ? BundleI18n.Calendar.Calendar_Edit_Allday : CalendarTimeFormatter.formatOneDayTimeRange(startFrom: startDate, endAt: endDate, with: customOptions)
        }
        return (overDayInfo, timeDescription)
    }
}

enum HighlighItem: String {
    case title
    case desc
    case location
    case attendee
    case meetingRoom
    case chat
}
