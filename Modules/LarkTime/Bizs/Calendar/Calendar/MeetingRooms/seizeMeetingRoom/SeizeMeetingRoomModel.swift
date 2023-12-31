//
//  SeizeMeetingRoomModel.swift
//  Calendar
//
//  Created by harry zou on 2019/4/18.
//

import Foundation
import LarkTimeFormatUtils

struct SeizeMeetingRoomModel {
    enum Errors: Int, Error {
        // local error code
        case allDayEvent = -1001
        case availableDurationTooShoot = -1002

        // server error code
        case resourceSeizeClosedErr = 8025
        case resourceNotFoundErr = 8026
        case resourceIsDisabledErr = 8027
        case businessUnpaidErr = 8028
        case externalUser = 8029
    }

    let meetingRoom: CalendarMeetingRoom
    let seizeTime: Int
    let currentTimeStamp: Int
    let shouldShowConfirm: Bool
    let instances: [CalendarEventInstanceEntity]
    typealias SeizeInfo = (secondsLeft: Int, availableTimeStart: Int, availableTimeEnd: Int, hasCurrentInstance: Bool)
}

extension SeizeMeetingRoomModel {

    func getCurrentAlldayInstance() -> CalendarEventInstanceEntity? {
        if let instance = instances.first(where: { (instance) -> Bool in
            return instance.startTime <= currentTimeStamp && instance.endTime >= currentTimeStamp && instance.selfAttendeeStatus == .accept
        }) {
            if instance.shouldShowAsAllDayEvent() {
                return instance
            }
        }
        return nil
    }

    func getCountdownInfo() throws -> SeizeInfo {
        var hasCurrentInstance: Bool = false
        let currentInstance = instances.first { (instance) -> Bool in
            return instance.startTime <= currentTimeStamp && instance.endTime >= currentTimeStamp && instance.selfAttendeeStatus == .accept
        }
        if let currentInstance = currentInstance {
            hasCurrentInstance = true
            if currentInstance.shouldShowAsAllDayEvent() {
                throw Errors.allDayEvent
            }
        }
        let nextInstance = instances.first {(instance) -> Bool in
            return instance.startTime > currentTimeStamp
        }
        let availableTimeEnd = Int(nextInstance?.startTime ?? Int64(Date(timeIntervalSince1970: TimeInterval(currentTimeStamp)).dayEnd().timeIntervalSince1970))
        var availableTimeStart = -1
        if let currentInstance = currentInstance {
            availableTimeStart = min(Int(currentInstance.startTime) + seizeTime, Int(currentInstance.endTime))
        }
        // 如果当前日程开始时间+抢占时间 < 当前时间戳，则使用当前时间戳作为开始时间
        if availableTimeStart < currentTimeStamp {
            availableTimeStart = currentTimeStamp
        }
        let secondsLeft = availableTimeStart - currentTimeStamp
        if let currentInstance = currentInstance,
            let nextInstance = nextInstance,
            currentInstance.endTime == nextInstance.startTime,
            availableTimeEnd - availableTimeStart <= 0 {
            throw Errors.availableDurationTooShoot
        }
        return (secondsLeft, availableTimeStart, availableTimeEnd, hasCurrentInstance)
    }

    func getTimeCellString(currentTime: Int,
                           availableTimeStart: Int,
                           availTimeEnd: Int,
                           is12HourStyle: Bool) -> String {
        var result = ""
        let endDate = Date(timeIntervalSince1970: TimeInterval(availTimeEnd))
        let customOptions = Options(
            is12HourStyle: is12HourStyle,
            timePrecisionType: .minute
        )
        if currentTime >= availableTimeStart {
            result += BundleI18n.Calendar.Calendar_Takeover_TipsEstimate(NextStartTime: 
                TimeFormatUtils.formatTime(from: endDate, with: customOptions)
            )
        } else {
            let startDate = Date(timeIntervalSince1970: TimeInterval(availableTimeStart))
            let fullTimeSring = TimeFormatUtils.formatTimeRange(startFrom: startDate, endAt: endDate, with: customOptions)
            result += BundleI18n.Calendar.Calendar_Takeover_Today(WholeTime: fullTimeSring)
        }
        return result
    }
}
