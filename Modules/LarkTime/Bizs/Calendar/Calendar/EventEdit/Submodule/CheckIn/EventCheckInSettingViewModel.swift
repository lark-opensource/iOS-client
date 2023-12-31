//
//  EventCheckInSettingViewModel.swift
//  Calendar
//
//  Created by huoyunjie on 2022/9/13.
//

import Foundation

class EventCheckInSettingViewModel {

    typealias CheckInConfig = Rust.CheckInConfig
    typealias CheckInTime = CheckInConfig.CheckInTime

    let absoluteTimeStrGetter: (Date, Date) -> String
    let startDate: Date
    let endDate: Date
    let eventModel: EventEditModel

    var checkInConfig: CheckInConfig

    init(checkInConfig: CheckInConfig?,
         eventModel: EventEditModel,
         absoluteTimeStrGetter: @escaping (Date, Date) -> String) {
        self.eventModel = eventModel
        self.startDate = eventModel.startDate
        self.endDate = eventModel.endDate
        if let checkInConfig = checkInConfig,
           checkInConfig.startAndEndTimeIsValid(startDate: eventModel.startDate, endDate: eventModel.endDate) {
            self.checkInConfig = checkInConfig
        } else {
            self.checkInConfig = CheckInConfig.initialValue
        }
        self.absoluteTimeStrGetter = absoluteTimeStrGetter
    }

    func getAbsoluteTimeStr() -> String {
        let dates = self.checkInConfig.getCheckInDate(startDate: startDate, endDate: endDate)
        return absoluteTimeStrGetter(dates.startDate, dates.endDate)
    }

    func checkInConfigIsValid() -> Bool {
        return self.checkInConfig.startAndEndTimeIsValid(startDate: startDate, endDate: endDate)
    }
}

extension EventCheckInSettingViewModel {
    var checkInStartTimeStr: String {
        let checkInStartTime = checkInConfig.checkInStartTime
        return checkInStartTime.getReadableStr(isStart: true)
    }

    var checkInEndTimeStr: String {
        let checkInEndTime = checkInConfig.checkInEndTime
        return checkInEndTime.getReadableStr(isStart: false)
    }
}

extension Rust.CheckInConfig {
    func startAndEndTimeIsValid(startDate: Date, endDate: Date) -> Bool {
        let checkInDates = self.getCheckInDate(startDate: startDate, endDate: endDate)
        return checkInDates.startDate.timeIntervalSince1970 < checkInDates.endDate.timeIntervalSince1970
    }

    func getCheckInDate(startDate: Date, endDate: Date) -> (startDate: Date, endDate: Date) {
        let start: Date
        let end: Date

        let startDuration = Int(self.checkInStartTime.duration)
        switch self.checkInStartTime.type {
        case .beforeEventStart:
            start = startDate.adding(.minute, value: -startDuration)
        case .afterEventStart:
            start = startDate.adding(.minute, value: startDuration)
        case .afterEventEnd:
            start = endDate.adding(.minute, value: startDuration)
        @unknown default:
            start = startDate.adding(.minute, value: -startDuration)
        }

        let endDuration = Int(self.checkInEndTime.duration)
        switch self.checkInEndTime.type {
        case .beforeEventStart:
            end = startDate.adding(.minute, value: -endDuration)
        case .afterEventStart:
            end = startDate.adding(.minute, value: endDuration)
        case .afterEventEnd:
            end = endDate.adding(.minute, value: endDuration)
        @unknown default:
            end = startDate.adding(.minute, value: -endDuration)
        }

        return (start, end)
    }
}
