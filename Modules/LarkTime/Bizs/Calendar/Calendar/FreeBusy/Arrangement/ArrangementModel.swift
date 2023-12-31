//
//  ArrangementModel.swift
//  Calendar
//
//  Created by zhouyuan on 2019/3/31.
//

import UIKit
import RxRelay
import Foundation
import LarkContainer
import CalendarFoundation

struct ArrangmentModel: ArrangementViewProtocol, FreebusyCalculation, WorkingHoursCalculation {

    private var workHourSettingMap: WorkHourMap = [:]
    var workingHoursTimeRangeMap: [String: [WorkingHoursTimeRange]] {
        return getWorkingHousTimeRangsMap(date: startTime,
                                          workHourSettingMap: workHourSettingMap,
                                          timezoneMap: timezoneMap, uiTimeZoneId: getTimeZone().identifier)
    }

    var workHourConflictCalendarIds: [String] {
        return getWorkHourConflictCalendarIds(startTime: startTime,
                                              endTime: endTime,
                                              workingHoursTimeRangeMap: workingHoursTimeRangeMap,
                                              timeZoneId: getTimeZone().identifier)
    }

    var firstWeekday: DaysOfWeek
    var startTime: Date
    var endTime: Date

    var calendarInstanceMap: InstanceMap = [:]
    var timezoneMap: [String: String] = [:]
    var privateCalMap: [String: Bool] = [:]
    var attendees: [UserAttendeeBaseDisplayInfo]
    let sunStateService: SunStateService

    var calendarIds: [String] {
        return attendees.map { $0.calendarId }
    }

    var is12HourStyle: Bool {
        didSet {
            footerViewModel.is12HourStyle = is12HourStyle
        }
    }

    func cellWidth(with rullerWidth: CGFloat, totalWidth: CGFloat) -> CGFloat {
        let count = attendees.count
        let maxCellCntPerScreen = count >= 5 ? 5 : count
        return (totalWidth - rullerWidth) / CGFloat(maxCellCntPerScreen)
    }

    var headerViewModel: ArrangementHeaderViewModel {
        let calendarIds = freeBusyInfo.map { info in
            (info.busyAttendees + info.maybeFreeAttendees)
                .map { $0.calendarId }
        } ?? []
        return ArrangementHeaderViewModel(
            attendees: attendees,
            startTime: startTime,
            timezoneMap: timezoneMap,
            privateCalMap: privateCalMap,
            conflictCalendarIds: calendarIds,
            notWorkingCalendarIds: workHourConflictCalendarIds,
            is12HourStyle: is12HourStyle,
            sunStateService: sunStateService
        )
    }
    var footerViewModel: ArrangementFooterViewModel

    var freeBusyInfo: AttendeeFreeBusyInfo? {
        return opt_calculationFreeBusyInfo(startTime: startTime,
                                           endTime: endTime,
                                           calendarInstanceMap: calendarInstanceMap,
                                           attendees: attendees,
                                           privateCalendarIds: Array(privateCalMap.keys))
    }

    let rxTimezoneDisplayType: BehaviorRelay<TimezoneDisplayType>

    var timeZone: TimeZoneModel
    init(sunStateService: SunStateService,
         startTime: Date,
         endTime: Date,
         attendees: [UserAttendeeBaseDisplayInfo],
         currentUserCalendarId: String,
         organizerCalendarId: String,
         firstWeekday: DaysOfWeek,
         is12HourStyle: Bool,
         rxTimezoneDisplayType: BehaviorRelay<TimezoneDisplayType>,
         timeZone: TimeZoneModel = TimeZone.current) {
        self.sunStateService = sunStateService
        self.firstWeekday = firstWeekday
        self.startTime = startTime
        self.endTime = endTime
        self.is12HourStyle = is12HourStyle
        self.rxTimezoneDisplayType = rxTimezoneDisplayType
        let attendeesSorted = ArrangmentModel
            .sortedAttendees(attendees: attendees,
                             currentUserCalendarId: currentUserCalendarId,
                             organizerCalendarId: organizerCalendarId)
        self.attendees = attendeesSorted
        self.footerViewModel = ArrangementFooterViewModel(
            startTime: startTime,
            endTime: endTime,
            totalAttendeeCnt: 0,
            unAvailableAttendeeNames: [],
            hasNotWorkingHours: false,
            textMaxWidth: ArrangementFooterView.labelMaxWidth,
            is12HourStyle: is12HourStyle,
            attendeeFreeBusyInfo: AttendeeFreeBusyInfo())
        self.timeZone = timeZone
    }

    /// 组织者排第一，操作者排第二
    static func sortedAttendees(attendees: [UserAttendeeBaseDisplayInfo],
                                currentUserCalendarId: String,
                                organizerCalendarId: String) -> [UserAttendeeBaseDisplayInfo] {
        var attendees = attendees
        if let index = attendees.firstIndex(where: { $0.calendarId == currentUserCalendarId }) {
            let attendee = attendees.remove(at: index)
            attendees.insert(attendee, at: 0)
        }
        if let index = attendees.firstIndex(where: { $0.calendarId == organizerCalendarId }) {
            let attendee = attendees.remove(at: index)
            attendees.insert(attendee, at: 0)
        }
        return attendees
    }

    mutating func changeTimeRange(by date: Date) {
        let date = calibrationDate(date: date)
        let (start, end) = getArrangementTimeFordate(date)
        changeTimeRangeInternal(startTime: start, endTime: end)
    }

    mutating func changeTimeRange(startTime: Date, endTime: Date) {
        let startTime = calibrationDate(date: startTime)
        let endTime = calibrationDate(date: endTime)
        changeTimeRangeInternal(startTime: startTime, endTime: endTime)
    }

    mutating func changeTimeRangeInternal(startTime: Date, endTime: Date) {
        self.startTime = startTime
        self.endTime = endTime
        self.footerViewModel.updateTime(startTime: calibrationDateForUI(date: startTime), endTime: calibrationDateForUI(date: endTime))
        changeFooterFreeBusyInfo(freeBusyInfo: freeBusyInfo)
    }

    mutating func changeServerData(_ serverInstanceData: ServerInstanceData) {
        self.calendarInstanceMap = serverInstanceData.instanceMap
        self.timezoneMap = serverInstanceData.timezoneMap
        self.workHourSettingMap = serverInstanceData.workHourMap
        self.privateCalMap = serverInstanceData.privateCalMap
        changeFooterFreeBusyInfo(freeBusyInfo: freeBusyInfo)
    }

    private mutating func changeFooterFreeBusyInfo(freeBusyInfo: AttendeeFreeBusyInfo?) {
        if let freeBusyInfo = freeBusyInfo {
            self.footerViewModel.updateTime(startTime: calibrationDateForUI(date: startTime), endTime: calibrationDateForUI(date: endTime))
            self.footerViewModel.updateSubTitle(
                hasNotWorkingHours: !workHourConflictCalendarIds.isEmpty,
                workingHourConflictCount: workHourConflictCalendarIds.count,
                attendeeFreeBusyInfo: freeBusyInfo)
        } else {
            self.footerViewModel.showFailure(startTime: calibrationDateForUI(date: startTime), endTime: calibrationDateForUI(date: endTime))
        }
    }

    mutating func moveAttendeeToFirst(indexPath: IndexPath) {
        if attendees.indices.contains(indexPath.row) {
            let attendee = attendees.remove(at: indexPath.row)
            attendees.insert(attendee, at: 0)
        }
    }

    func getArrangementTimeFordate(_ date: Date) -> (Date, Date) {

        guard let startDate = TimeZoneUtil.changeDateDay(srcDay: startTime, tzId: getTimeZone().identifier, destDay: date),
            let endDate = TimeZoneUtil.changeDateDay(srcDay: endTime, tzId: getTimeZone().identifier, destDay: date) else {
                                        assertionFailureLog()
                                        return (date, date)
        }
        return (startDate, endDate)
    }

    func getUiStartTime() -> Date {
        calibrationDateForUI(date: startTime)
    }

    func getUiEndTime() -> Date {
        calibrationDateForUI(date: endTime)
    }
}
extension ArrangmentModel {

    func switchToEventTimezone() {
        EventEdit.logger.info("ArrangmentModel switchToEventTimezone, timezone display type: \(rxTimezoneDisplayType.value)")
        if rxTimezoneDisplayType.value == .deviceTimezone {
            rxTimezoneDisplayType.accept(.eventTimezone)
        }
    }

    var shouldSwitchToEventTimezone: Bool {
        let isDiff = isTimezoneDiff
        let isDeviceTimezone = rxTimezoneDisplayType.value == .deviceTimezone
        EventEdit.logger.info("ArrangmentModel shouldSwitchToEventTimezone, isDeviceTimezone: \(isDeviceTimezone), timezone diff: \(isDiff)")
        return isDeviceTimezone && isDiff
    }

    var isTimezoneDiff: Bool {
        if let eventTimezone = timeZone as? TimeZone {
            return TimeZoneUtil.areTimezonesDifferent(timezones: [.current, eventTimezone])
        }
        return false
    }

    var timezoneDisplayType: TimezoneDisplayType {
        rxTimezoneDisplayType.value
    }

    // 这里获取的时区，可能是日程时区，也可能是本地时区
    func getTimeZone() -> TimeZoneModel {
        return rxTimezoneDisplayType.value == .deviceTimezone ? TimeZone.current : timeZone
    }

    func getEventTimezone() -> TimeZoneModel {
        return timeZone
    }

    func getTzDisplayName() -> String {
        getTimeZone().getGmtOffsetDescription(date: self.startTime)
    }

    mutating func updateTzInfo(timeZone: TimeZoneModel) {
        self.rxTimezoneDisplayType.accept(.eventTimezone)
        let oldTz = getTimeZone().identifier
        self.timeZone = timeZone
        let startTime = TimeZoneUtil.dateTransForm(srcDate: self.startTime, srcTzId: oldTz, destTzId: timeZone.identifier)
        let endTime = TimeZoneUtil.dateTransForm(srcDate: self.endTime, srcTzId: oldTz, destTzId: timeZone.identifier)
        changeTimeRangeInternal(startTime: startTime, endTime: endTime)
    }

    func calibrationDate(date: Date) -> Date {
        // 这里的date是设备时区的date，需要转成年月日时分秒后再转成设置时区的date
        guard TimeZone.current.identifier != getTimeZone().identifier else {
            return date
        }
        return TimeZoneUtil.dateTransForm(srcDate: date, srcTzId: TimeZone.current.identifier, destTzId: getTimeZone().identifier)
    }

    func calibrationDateForUI(date: Date) -> Date {
        // 这里的date是设备时区的date，需要转成年月日时分秒后再转成设置时区的date
        guard TimeZone.current.identifier != getTimeZone().identifier else {
            return date
        }
        return TimeZoneUtil.dateTransForm(srcDate: date, srcTzId: getTimeZone().identifier, destTzId: TimeZone.current.identifier)
    }

    func getUiCurrentDate() -> Date {
     return calibrationDateForUI(date: Date())
    }

}

struct ArrangementDataSource {
    var attendees: [UserAttendeeBaseDisplayInfo]
    var startTime: Date
    var endTime: Date
    var organizerCalendarId: String
    var rxTimezoneDisplayType: BehaviorRelay<TimezoneDisplayType>
    var timeZoneId: String
    var filterParam: FilterParam
    init(attendees: [UserAttendeeBaseDisplayInfo],
         startTime: Date,
         endTime: Date,
         organizerCalendarId: String,
         rxTimezoneDisplayType: BehaviorRelay<TimezoneDisplayType>,
         timeZoneId: String,
         filterParam: FilterParam) {
        self.attendees = attendees
        self.startTime = startTime
        self.endTime = endTime
        self.organizerCalendarId = organizerCalendarId
        self.rxTimezoneDisplayType = rxTimezoneDisplayType
        self.timeZoneId = timeZoneId
        self.filterParam = filterParam
    }
}
