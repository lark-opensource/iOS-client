//
//  CalendarDependencyImpl.swift
//  LarkByteView
//
//  Created by kiri on 2020/9/28.
//

import Foundation
import ByteView
import CalendarFoundation
import LarkExtensions
import LarkTimeFormatUtils
import LarkContainer

final class CalendarDependencyImpl: ByteView.CalendarDependency {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    var is24HourTime: Bool {
        Date.lf.is24HourTime
    }

    /// 格式化日程时间
    /// - parameter startTime: 日程开始时间，timeIntervalSince1970
    /// - parameter endTime: 日程结束时间，timeIntervalSince1970
    /// - parameter isAllDay: 是不是一个全天的日程
    func formatDateTimeRange(startTime: TimeInterval, endTime: TimeInterval, isAllDay: Bool) -> String {
        let start = Date(timeIntervalSince1970: startTime)
        let end = Date(timeIntervalSince1970: endTime)
        let is12HourStyle = !is24HourTime
        let options = Options(timeZone: TimeZone.current, is12HourStyle: is12HourStyle, shouldShowGMT: true,
                              timePrecisionType: .minute, datePrecisionType: .day, dateStatusType: .absolute)
        return CalendarTimeFormatter.formatFullDateTimeRange(startFrom: start, endAt: end, isAllDayEvent: isAllDay, shouldShowTailingGMT: true, with: options)
    }

    /// 显示日历详情简介
    func createDocsView() -> CalendarDocsViewHolder {
        CalendarDocsView(userResolver: userResolver)
    }
}
