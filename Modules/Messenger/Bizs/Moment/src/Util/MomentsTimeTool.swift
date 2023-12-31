//
//  MomentsTimeTool.swift
//  Moment
//
//  Created by liluobin on 2021/2/4.
//

import Foundation
import LarkTimeFormatUtils

/**
   PM：时间展示规则
   - 不是当年年份的时候显示年份信息， xx 年 xx 月 xx 日
   - 距离当前绝对时间超过 24 小时显示具体日期的时间戳 xx 月 xx 日
   - 当天的显示 xx 小时前， xx 分钟，1 分钟内显示 「刚刚」
 */

/// eg:
/// // Wed, 1 Jul, 2020, 02:00:00 GMT
/// let date = Date(timeIntervalSince1970: 1593568800)
/// var option = Options(datePrecisionType: .month, timeFormatType: .short)
/// print(TimeFormatUtils.formatDate(date), option)) // July
/// option.timeFormatType = .long
/// print(TimeFormatUtils.formatDate(date), option)) // Jul 2020
/// option.datePrecisionType = .day
/// print(TimeFormatUtils.formatDate(date), option)) // Jul 1, 2020
/// option.timeFormatType = .short
/// print(TimeFormatUtils.formatDate(date), option)) // Jul 1
/// option.dateStatusType = .relative
/// print(TimeFormatUtils.formatDate(date), option)) // Today

final class MomentsTimeTool {

    static func displayTimeForDate(_ date: Date) -> String {
        var display = ""
        let distance = Date().timeIntervalSince1970 - date.timeIntervalSince1970
        if distance < 3600 * 24 {
            if distance < 60 {
                display = BundleI18n.Moment.Lark_Community_JustNow
            } else if distance < 3600 {
                display = BundleI18n.Moment.Lark_Community_PastMinutes("\(Int(distance / 60))")
            } else {
                display = BundleI18n.Moment.Lark_Community_PastHours("\(Int(distance / 3600))")
            }
        } else {
            if !self.isCurrentYearWithCalendar(date: date) {
                var options = TimeFormatUtils.defaultOptions
                options.datePrecisionType = .day
                options.timeFormatType = .long
                display = TimeFormatUtils.formatDate(from: date, with: options)
            } else {
                var options = TimeFormatUtils.defaultOptions
                options.datePrecisionType = .day
                options.timeFormatType = .short
                display = TimeFormatUtils.formatDate(from: date, with: options)
            }
        }
        return display
    }

    static func isCurrentYearWithCalendar(date: Date) -> Bool {
        let theYear = Calendar.current.component(.year, from: date)
        let thisYear = Calendar.current.component(.year, from: Date())
        return theYear == thisYear
    }
}
