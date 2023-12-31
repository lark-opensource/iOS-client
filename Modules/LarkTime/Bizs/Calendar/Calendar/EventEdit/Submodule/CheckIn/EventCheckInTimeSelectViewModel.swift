//
//  EventCheckInTimeSelectViewModel.swift
//  Calendar
//
//  Created by huoyunjie on 2022/9/14.
//

import Foundation
import CalendarFoundation

class EventCheckInTimeSelectViewModel {

    typealias TimeEnum = Rust.CheckInConfig.CheckInTime.TypeEnum
    typealias CheckInTime = Rust.CheckInConfig.CheckInTime

    enum ColumnType {
        case timeEnum
        case timeHour
        case timeMinutes
    }

    enum TimeSelectType {
        case startTime
        case endTime
    }

    struct TimeMode {
        var timeEnum: TimeEnum = .beforeEventStart
        var hour: Int64 = 0
        var minutes: Int64 = 0
        var duration: Int64 {
            hour * 60 + minutes
        }
    }

    enum CheckInError {
        case outOfRange
        case notSupported
        case startEndError
    }

    // picker 每个滚轮的数据
    let timeEnumsColumn: [TimeEnum?] = [nil, nil, .beforeEventStart, .afterEventStart, .afterEventEnd, nil, nil]
    var timeHoursColumn: [Int64] = Array(0...12)
    let timeMinutesColumn: [Int64] = Array(0...59)

    // picker 滚轮数据类型
    let wheelMode: [ColumnType] = [.timeEnum, .timeHour, .timeMinutes]

    private(set) var currentTimeMode = TimeMode()

    let timeSelectType: TimeSelectType
    var currentCheckInTime: CheckInTime {
        transformToCheckInTime(currentTimeMode)
    }
    let timeIsValid: (CheckInTime) -> Bool

    init(timeSelectType: TimeSelectType, checkInTime: CheckInTime, timeIsValid: @escaping (CheckInTime) -> Bool) {
        self.timeSelectType = timeSelectType
        self.timeIsValid = timeIsValid
        self.currentTimeMode = self.transformToTimeMode(checkInTime)
    }

    // 更新时间类型 timeEnum，对 timeMinutes 有附加作用
    func updateTimeEnumWith(index: Int) {
        guard index < timeEnumsColumn.count,
            let timeEnum = timeEnumsColumn[index],
            timeEnum != currentTimeMode.timeEnum else {
            assertionFailureLog("out of range time enums")
            return
        }
        self.currentTimeMode.timeEnum = timeEnum
        if timeEnum == .beforeEventStart && currentTimeMode.duration == 0 {
            self.currentTimeMode.minutes = 15
        }
    }

    // 更新小时数 timeHour
    func updateTimeHourWith(index: Int) {
        guard index < timeHoursColumn.count else {
            assertionFailureLog("out of range time hour")
            return
        }
        self.currentTimeMode.hour = timeHoursColumn[index]
    }

    // 更新分钟数 timeMinutes
    func updateTimeMinutesWith(index: Int) {
        guard index < timeMinutesColumn.count else {
            assertionFailureLog("out of range time minutes")
            return
        }
        self.currentTimeMode.minutes = timeMinutesColumn[index]
    }

    func getCheckInError() -> CheckInError? {
        if currentTimeMode.timeEnum == .beforeEventStart && currentTimeMode.duration == 0 {
            return .notSupported
        } else if currentTimeMode.duration > 720 {
            return .outOfRange
        } else if !timeIsValid(transformToCheckInTime(currentTimeMode)) {
            return .startEndError
        } else {
            return nil
        }
    }

    // CheckInTime -> TimeMode
    private func transformToTimeMode(_ checkInTime: CheckInTime) -> TimeMode {
        let timeEnum = checkInTime.type
        let hour = checkInTime.duration / 60
        let minutes = checkInTime.duration % 60
        return TimeMode(timeEnum: timeEnum, hour: hour, minutes: minutes)
    }

    // TimeMode -> CheckInTime
    func transformToCheckInTime(_ timeMode: TimeMode) -> CheckInTime {
        var checkInTime = CheckInTime()
        checkInTime.type = timeMode.timeEnum
        checkInTime.duration = timeMode.duration
        return checkInTime
    }

}

extension Rust.CheckInConfig.CheckInTime.TypeEnum {
    var description: String {
        switch self {
        case .beforeEventStart: return I18n.Calendar_Event_BeforeStartDropMenu
        case .afterEventStart: return I18n.Calendar_Event_AfterStartDropMenu
        case .afterEventEnd: return I18n.Calendar_Event_AfterEndDropMenu
        @unknown default: return ""
        }
    }
}

extension Rust.CheckInConfig.CheckInTime {
    func getReadableStr(isStart: Bool) -> String {
        switch type {
        case .beforeEventStart:
            if duration == 0 {
                return I18n.Calendar_Event_PleaseSelectAnother
            } else {
                return I18n.Calendar_Event_StartMinEventStart(number: duration)
            }
        case .afterEventStart:
            if duration == 0 {
                return isStart ? I18n.Calendar_Event_StartOnceEventStart : I18n.Calendar_Event_StartOnceEventEnd
            } else {
                return I18n.Calendar_Event_StartMinAfterEvent(number: duration)
            }
        case .afterEventEnd:
            if duration == 0 {
                return isStart ? I18n.Calendar_Event_EndOnceEventStart : I18n.Calendar_Event_EndOnceEventEnd
            } else {
                return I18n.Calendar_Event_StartMinEventEnd(number: duration)
            }
        @unknown default: return ""
        }
    }
}
