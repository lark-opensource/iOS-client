//
//  EventConflictModel.swift
//  Calendar
//
//  Created by huoyunjie on 2023/11/2.
//

import Foundation
import RustPB
import CalendarFoundation
import LarkTimeFormatUtils

struct EventConflictModel {
    var conflictType: Calendar_V1_ConflictType
    var conflictTime: Int64? = 0
    var dayInstances: [Rust.Instance] = []
    var event: Rust.Event?
    var displayOriginalTime: Int64?
    var nextStartTime: Int64?
    var layoutedDayInstancesMap: [JulianDay: [DayNonAllDayLayoutedInstance]] = [:]
    var currentUniqueId: String?
    
    mutating func handleCurrentUniqueId() {
        let instances = dayInstances.sorted { ins1, ins2 in
            ins1.quadrupleStr < ins2.quadrupleStr
        }
        if let currentInstance = instances.first(where: { instance in
            instance.calendarID == event?.calendarID &&
            instance.key == event?.key &&
            instance.originalTime == displayOriginalTime
        }) {
            currentUniqueId = currentInstance.quadrupleStr
        } else if let currentInstance = instances.first(where: { instance in
            instance.calendarID == event?.calendarID &&
            instance.key == event?.key
        }) {
            currentUniqueId = currentInstance.quadrupleStr
        } else if let currentInstance = instances.first(where: { instance in
            instance.key == event?.key
        }) {
            currentUniqueId = currentInstance.quadrupleStr
        }
    }
}

extension EventConflictModel {
    
    func getDayInstance(with uniqueId: String) -> Rust.Instance? {
        self.dayInstances.first(where: { $0.quadrupleStr == uniqueId })
    }
    
    /// 判断是否是冲突日程
    func isConflictInstance(uniqueId: String) -> Bool {
        guard let currentUniqueId = self.currentUniqueId else {
            return false
        }
        return uniqueId == currentUniqueId
    }

    /// 获取冲突标签文案
    func getConflictText(is12HourStyle: Bool, startTime: Int64) -> String? {
        guard conflictType != .none else {
            /// 没有冲突
            return nil
        }

        if conflictType == .normal { // 普通冲突
            return I18n.Calendar_Detail_Conflict
        }

        /// 重复性冲突
        guard let conflictTime = self.conflictTime else {
            assertionFailure("event conflict bu no conflictTime")
            return nil
        }
        let confilictDate = Date(timeIntervalSince1970: TimeInterval(conflictTime))
        let currentDate = Date(timeIntervalSinceNow: 0)

        // 如果冲突日期与卡片的展示日期在同一天，不显示冲突的具体日期
        let eventStartTime = Date(timeIntervalSince1970: TimeInterval(startTime))
        if confilictDate.isInSameDay(eventStartTime) {
            return I18n.Calendar_Detail_Conflict
        }

        let shouldShowYear = confilictDate.year != currentDate.year

        let customOptions = Options(
            timeFormatType: shouldShowYear ? .long : .short,
            datePrecisionType: .day
        )

        return I18n.Calendar_Detail_ConflictRecurring(date:
            TimeFormatUtils.formatDate(from: confilictDate, with: customOptions)
        )
    }
    
    var shouldShowTimeStamp: Int64 {
        if conflictType != .none,
           let conflictTime = conflictTime {
            return conflictTime
        }
        if let nextStartTime = self.nextStartTime {
            return nextStartTime
        }
        return event?.startTime ?? 0
    }

    /// 获取时间的文案：X月X日（周X），若无冲突，展示 dayInstance.startTime 的时间，用 eventStartTime 进行兜底
    func getConflictTimeStr(timezone: TimeZone, eventStartTime: Int64) -> String {
        // 使用设备时区
        let options = Options(
            timeZone: timezone,
            is12HourStyle: false,
            timeFormatType: .short,
            timePrecisionType: .hour,
            datePrecisionType: .day,
            dateStatusType: .relative,
            shouldRemoveTrailingZeros: false
        )

        let time = shouldShowTimeStamp

        let date =  Date(timeIntervalSince1970: TimeInterval(time))
        return TimeFormatUtils.formatFullDate(from: date, with: options)
    }
}
