//
//  TodayEventUtils.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/23.
//

import LarkTimeFormatUtils

class TodayEventUtils {
    static func isAllday(instance: CalendarEventInstance) -> Bool {
        /*
         1. 全天日程为全天
         2. 跨天日程中，中间整天的时间段为全天
         */
        if instance.isAllDay {
            return true
        }
        let calendar = Calendar(identifier: .gregorian)
        let startDate = Date(timeIntervalSince1970: TimeInterval(instance.startTime))
        let endDate = Date(timeIntervalSince1970: TimeInterval(instance.endTime))
        if !Calendar.gregorianCalendar.isDate(startDate, inSameDayAs: endDate - 1) {
            let dayStart = calendar.startOfDay(for: Date())
            let dayEnd = dayStart.dayEnd()
            if (startDate < dayStart) && (endDate > dayEnd) {
                return true
            }
        }
        return false
    }

    static func isIn24Hours(startTime: Int64, endTime: Int64) -> Bool {
        return endTime - startTime <= 24 * 60 * 60
    }

    /*
     今日安排展示时间规则对齐pc，需要特殊处理
     1. 23:00-00:00（今天某一时刻至第二日零点）不算跨天日程，不能使用TimeFormatUtils.formatTimeRange直接处理
     2. 12小时制时，日程的开始时间和结束不能同时展示上午或下午，需使用TimeFormatUtils.formatTimeRange处理
     3. 跨天日程需展示（第x天，共y天），此逻辑对齐视图页
     */
    static func formatOneDayTimeRange(startFrom startDate: Date,
                                      endAt endDate: Date,
                                      with options: Options) -> String {
        var endDate = endDate
        let isOverOneDay = !startDate.isInSameDay(endDate)
        // 此方法只处理非跨天日程的范围时间显示，对于00:00会被TimeFormatUtils.formatTimeRange直接判断为跨天，
        // 所以当跨天时需要获取前一天的时间
        if isOverOneDay {
            endDate -= 24 * 60 * 60
        }
        return TimeFormatUtils.formatTimeRange(startFrom: startDate, endAt: endDate, with: options)
    }

    static func timeDescription(isOverOneDay: Bool,
                                endDay: Int32,
                                startDay: Int32,
                                startDate: Date,
                                endDate: Date,
                                currentDate: Date,
                                calendar: Calendar,
                                with customOptions: Options = Options()) -> String {
        // 场景: 列表视图-日程块上显示的时间表达文案，上下文:
        // 1. 跨天: 全天日程显示全天文案，非全天日程分三种情况: 起始日期显示起始时间，中期日期显示全天文案，结束日期显示结束时间
        // 2. 当天：时间范围，包含起始和结束时间
        // 使用设备当前时区
        var timeDescription = ""
        if isOverOneDay {// 跨天
            let dayNumber = endDay - startDay + 1
            let appearTimes = Calendar.gregorianCalendar.dateComponents([.day],
                                                                        from: startDate.dayStart(),
                                                                        to: currentDate.dayStart()).day ?? 0
            timeDescription = BundleI18n.Calendar.Calendar_View_AlldayInfo(day: appearTimes + 1, total: dayNumber)
        } else {
            timeDescription = TodayEventUtils.formatOneDayTimeRange(startFrom: startDate,
                                                                    endAt: endDate,
                                                                    with: customOptions)
        }
        return timeDescription
    }

    /*
     判断优先级: 开始时间>serverID
     1. 开始时间不同，选先开始的
     2. 开始时间相同，选serverID大的，serverID为0视为INT_MAX
     3. serverID相同，比较eventID，选大的
     */
    static func sortRules(lStartTime: Int64, lServerID: String, lEventID: String,
                          rStartTime: Int64, rServerID: String, rEventID: String) -> Bool {
        if lStartTime != rStartTime {
            return lStartTime < rStartTime
        }
        if var lID = Int64(lServerID),
           var rID = Int64(rServerID) {
            if lID == 0 {
                lID = INT64_MAX
            }
            if rID == 0 {
                rID = INT64_MAX
            }
            if lID != rID {
                return lID > rID
            }
        }
        if let lEventID = Int64(lEventID), let rEventID = Int64(rEventID) {
            return lEventID > rEventID
        }
        return false
    }
}
